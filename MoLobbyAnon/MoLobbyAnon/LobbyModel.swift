// LobbyModel
//

import Firebase
import GoogleSignIn
import FirebaseDatabase
import FirebaseAuth

class LobbyModel: ObservableObject {
    enum SignInState {
        case signedIn
        case signedOut
    }
    @Published var state: SignInState = .signedOut
    @Published var users: [UserModel] = []
    @Published var albumName = ""
        
    var currentUser: UserModel?
    
    var uid: String {
        if let cu = currentUser {
            print("LobbyModel currentUser cu", cu)
            return cu.id
        }
        else if let cu = Auth.auth().currentUser {
            print("LobbyModel Auth.auth().currentUser cu", cu)
            return cu.uid;
        }
        else {
            return "-no-uid-";
        }
    }

    // mo-lobby
    var lobbyRef: DatabaseReference? // = Database.root.child(app.settings.storeLobbyKey)
    var lobbyHandle: DatabaseHandle?

    unowned let app: AppModel
    init(_ app:AppModel) {
        self.app = app
    }

    func refresh() {
        observeStop()
        let nstoreLobbyKey = app.settings.storePrefix + app.settings.storeLobbyKey
        lobbyRef = Database.root.child(nstoreLobbyKey)
        observeStart()
        albumName = app.settings.photoAlbum
    }
    
    func user(uid: String) -> UserModel? {
        return users.first{ $0.id == uid }
    }

    func signIn() {
        print("LobbyModel signIn", state)
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            print("LobbyModel signIn restorePreviousSignIn", state)
            
            GIDSignIn.sharedInstance.restorePreviousSignIn { [unowned self] user, error in
                authenticateUser(for: user, with: error)
            }
        } else {
            print("LobbyModel signIn GIDConfiguration", state)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            guard let rootViewController = windowScene.windows.first?.rootViewController else { return }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] signInResult, error in
                self.authenticateUser(for: signInResult?.user, with: error)
            }
        }
    }
    
    func authenticateUser(for user: GIDGoogleUser?, with error: Error?) {
        if let error = error {
            print("authenticateUser error 1", error.localizedDescription)
            return
        }
        guard let idToken = user!.idToken?.tokenString else { return  };
        let accessToken = user!.accessToken.tokenString;
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

        Auth.auth().signIn(with: credential) { [unowned self] (_, error) in
            if let error = error {
                print("authenticateUser error 2", error.localizedDescription)
            } else {
                setSignedIn()
            }
        }
    }
    
    func signInAnonymously() {
        // anonymous authentication.
        print("signInAnonymously state", state)
        print("signInAnonymously Auth.auth().currentUser", Auth.auth().currentUser ?? "-none-")
        Auth.auth().signInAnonymously() { authResult, error in
            print("signInAnonymously authResult: \(String(describing: authResult))")
            print("signInAnonymously error: \(String(describing: error))")
            self.setSignedIn()
        }
    }

    func setSignedIn() {
        print("setSignedIn state", state)
        if state != .signedIn {
            state = .signedIn
            print("setSignedIn set signedIn", state)
            updateCurrentUser()
            app.lobbyModel.refresh()
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
            state = .signedOut
            currentUser = nil
        } catch {
            print("signOut error", error.localizedDescription)
        }
    }
        
    // First time user is inited in mo-users
    // update db user property dateIn with current time in seconds
    //
    func updateCurrentUser() {
        guard let lobbyRef else { return }
        
        let id = Auth.auth().currentUser?.uid ?? ""
        let guser = GIDSignIn.sharedInstance.currentUser;
        let name = guser?.profile?.name ?? ""
        let email = guser?.profile?.email ?? ""
        let profileImg = guser?.profile?.imageURL(withDimension: 80)?.description ?? ""
        let dateIn = Date().timeIntervalSinceReferenceDate

        var values:[String : Any] = [:];
        values["name"] = name
        values["email"] = email
        values["profileImg"] = profileImg
        values["dateIn"] = dateIn;
        values["uploadCount"] = 0

        print("updateCurrentUser id", id)
        // print("value", values);

        // !!@ Fails to get single value as documented
//        let childRef = lobbyRef.child("/\(id)/uploadCount")
//        let childRef = lobbyRef.child(id).child("uploadCount")
//        childRef.getData() { error, snapshot in
//            guard error == nil else {
//                print(" getData error",error!.localizedDescription)
//                return;
//            }
//            print("getData snapshot", snapshot ?? "-nil-");
//            if let num = snapshot?.value as? Int {
//                print("getData num", num);
//            }
//        }
        // Current user location is update on each login check
        if let loc = app.locationManager.lastLocation {
            values["lat"] = loc.coordinate.latitude;
            values["lon"] = loc.coordinate.longitude
        }

        // Get user info and prepare to update
        lobbyRef.getData() { error, snapshot in
            guard error == nil else {
                print("postUser getData error",error!.localizedDescription)
                return;
            }
            // print("updateCurrentUser snapshot", snapshot ?? "-nil-");
            if let users = snapshot?.value as? [String: Any] {
                if let user = users[id] as? [String: Any] {
                    print("updateCurrentUser user uploadCount", user["uploadCount"] ?? "-nil-");
                    values["uploadCount"] = user["uploadCount"] as? Int ?? 0
                    values["activeCount"] = ServerValue.increment(1);
                }
            }
            // print("updateCurrentUser values", values);
            
            // Update db user properies
            lobbyRef.child(id).updateChildValues(values) { error, ref in
                if let error = error {
                    print("postUser updateChildValues error: \(error).")
                }
            }
            self.currentUser = UserModel(id: id, dict: values)
        }
    }
    
    func updateUser(user: UserModel) {
        print("updateUser updateUser", updateUser)
        guard let lobbyRef else { return }
        
        var values:[String : Any] = [:];
        values["caption"] = user.caption
        values["stats"] = user.stats
        lobbyRef.child(user.id).updateChildValues(values) { error, ref in
            if let error = error {
                print("updateUser updateChildValues error: \(error).")
            }
        }
    }
    
    func observeStart() {
        guard let lobbyRef else { return }
        print("observeUsersStart usersHandle", lobbyHandle ?? "nil")
        if lobbyHandle != nil {
            return;
        }
        lobbyHandle = lobbyRef.observe(.value, with: { snapshot in
            // print("observeUsersStart snapshot", snapshot)
            guard let snapUsers = snapshot.value as? [String: [String: Any]] else {
                print("LobbyModel users EMPTY")
                self.users = []
                return
            }
            let items = snapUsers.compactMap { UserModel(id: $0, dict: $1) }
            let sortedItems = items.sorted(by: { $0.dateIn > $1.dateIn })
            self.users = sortedItems;
            // print("observeUsersStart users", self.users)
            // Update current user check
            if let user = self.currentUser {
                if let nuser = sortedItems.first(where: { $0.id == user.id } ) {
                    print("LobbyModel currentUser nuser", nuser)
                    self.currentUser = nuser
                }
            }
            print("LobbyModel users.count", self.users.count)
        })
    }
    
    func observeStop() {
        guard let lobbyRef else { return }
        print("observeUsersStop usersHandle", lobbyHandle ?? "nil")
        if let refHandle = lobbyHandle {
            lobbyRef.removeObserver(withHandle: refHandle)
            lobbyHandle = nil;
        }
    }
}

extension Database {
    class var root: DatabaseReference {
        return database().reference()
    }
}

//
// Firebase database, storage and auth docs
//  https://firebase.google.com/docs/database/ios/read-and-write?hl=en&authuser=0
//  https://firebase.google.com/docs/storage/ios/start?hl=en&authuser=0
//-- sample code
//  https://github.com/firebase/quickstart-ios/blob/master/database/README.md
//  https://github.com/firebase/quickstart-ios/blob/master/storage/README.md
//
// Google Sign-In & Firebase Authentication Using SwiftUI
//  https://github.com/rudrankriyam/Ellifit
//  https://blog.codemagic.io/google-sign-in-firebase-authentication-using-swift/
// requires google signin verion 6.x

// https://developer.apple.com/documentation/photokit/selecting_photos_and_videos_in_ios
// Selecting Photos and Videos in iOS
// Load Asset Metadata
