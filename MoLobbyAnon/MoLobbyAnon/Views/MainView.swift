/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI

enum TabTag {
    case login
    case lobby
    case settings
}

struct MainView: View {
    
    @EnvironmentObject var lobbyModel: LobbyModel
    @EnvironmentObject var app: AppModel
    
    var body: some View {
            TabView(selection: $app.selectedTab) {
                LobbyView()
                    .tabItem {
                        Label("Lobby", systemImage: "person.3.sequence")
                    }
                    .tag(TabTag.lobby)
                LoginView()
                    .tabItem {
                        Label("Login", systemImage: "square.and.arrow.down")
                    }
                    .tag(TabTag.login)
                AppSettingView()
                    .tabItem {
                        Label("Settings", systemImage: "info")
                    }
                    .tag(TabTag.settings)
            }
        .onAppear {
            print("MainView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
        }
        .task {
            lobbyModel.signInAnonymously();
        }
    }
}

// !!@ Firebase issues a crash when attempting to run in PreviewProvider
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        let app = AppModel();
//        MainView()
//            .environmentObject(app)
//            .environmentObject(app.lobbyModel)
//    }
//}
