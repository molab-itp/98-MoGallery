//
// LobbyView
// display list of users that have logged in

import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-load-a-remote-image-from-a-url
// Use AsyncImage in place of NetworkImage to avoid async warning

struct LobbyView: View {

    @StateObject var lobbyModel: LobbyModel
    
    @EnvironmentObject var app: AppModel
    
    var body: some View {
        NavigationStack {
            VStack {
                userHeaderView()
                if app.settings.showUsers {
                    userListView()
                }
                // !!@ if ! or else causes jump back to Camera view
                if !app.settings.showUsers {
                    AppSettingView()
                }
            }
            .navigationTitle("Settings (\(app.verNum))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        app.settings.showUsers.toggle()
                        app.saveSettings();
                    }) {
                        Image(systemName: app.settings.showUsers ?
                              "person.3.sequence.fill" : "person.3.sequence")
                    }
                }
            }
        }
    }
    
    private func userHeaderView() -> some View {
        VStack {
            HStack {
                if let currentUser = lobbyModel.currentUser {
                    // AsyncImage(url: URL(string: currentUser.profileImg))
                    // .aspectRatio(contentMode: .fit)
                    // .frame(width: 80, height: 80, alignment: .center)
                    VStack(alignment: .leading) {
                        // Text(currentUser.name )
                        // .font(.headline)
                        Text(currentUser.email )
                            .font(.subheadline)
                        Text(currentUser.id )
                            .font(.subheadline)
                        // Text(gApp.settings.storeLobbyKey )
                        // .font(.subheadline)
                    }
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            Button(action: lobbyModel.signOut) {
                Text("Sign Out")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemIndigo))
                    .cornerRadius(12)
                    .padding(5)
            }
        }
    }
    
    private func userListView() -> some View {
        List {
            ForEach(lobbyModel.users) { user in
                HStack {
                    AsyncImage(url: URL(string: user.profileImg))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80, alignment: .center)
                    // .cornerRadius(8)
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                        // Text(user.dateIn.description)
                        HStack {
                            Text(user.dateIn.getElapsedInterval())
                                .font(.subheadline)
                            Spacer()
                            Text(user.activeCountLabel ?? "")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        LobbyView()
//    }
//}
