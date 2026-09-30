/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI

enum TabTag {
    case gallery
    case photos
    case camera
    case map
    case settings
}

struct MainView: View {
    
    @Environment(LobbyModel.self) var lobbyModel
//    @Environment(PhotosModel.self) var photosModel
//    @Environment(CameraModel.self) var cameraModel

    @Environment(AppModel.self) var app

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.selectedTab) {
            GalleryTabView()
                .tabItem {
                    Label("Gallery", systemImage: "rectangle.stack")
                }
                .tag(TabTag.gallery)
            PhotoCollectionView()
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle")
                }
                .tag(TabTag.photos)
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(TabTag.camera)
            MapTabView()
                .tabItem {
                    Label("Map", systemImage: "globe")
                }
                .tag(TabTag.map)
            settingsView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
                .tag(TabTag.settings)
        }
        .onAppear {
            xprint("MainView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
        }
    }

    func settingsView() -> some View {
        Group {
            if lobbyModel.currentUser == nil {
                LoginView()
            }
            else {
                LobbyView()
            }
        }
    }
        
}

#Preview {
    MainView()
        .environment(AppModel.main)
        .environment(CameraModel.main)
        .environment(LobbyModel.main)
        .environment(GalleryModel.main)
        .environment(PhotosModel.main)
        .environment(MetaModel.main)
        .environment(LocationModel.main)
}

//    func signInAnonymously() async {
//        // Using Cloud Storage for Firebase requires the user be authenticated. Here we are using
//        // anonymous authentication.
//        xprint("signInAnonymously", Auth.auth().currentUser ?? "no-user")
//        xprint("uid", Auth.auth().currentUser?.uid ?? "")
//        if Auth.auth().currentUser == nil {
//            do {
//                try await Auth.auth().signInAnonymously()
//                authenticated = true
//            } catch {
//                xprint("Not able to connect: \(error)")
//                authenticated = false
//            }
//        }
//    }

// navigation with app.path

// NavigationStack(path: $app.path) {

// NavigationLink(value: "gallery") {
//    Label("Media Gallery", systemImage: "photo.stack.fill")
//        .font(.system(size: 36, weight: .bold))
//        .foregroundColor(.white)
// }

//    .navigationDestination(for: String.self) { dest in
//        if dest == "gallery" {
//            GalleryView(galleryModel: app.galleryModel)
//        }
//        else {

