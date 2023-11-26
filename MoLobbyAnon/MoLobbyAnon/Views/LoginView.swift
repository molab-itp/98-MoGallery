//
//  LoginView.swift

import SwiftUI

// ?? Why not centered vertically with Spacers

struct LoginView: View {
    
    @EnvironmentObject var lobbyModel: LobbyModel

    @EnvironmentObject var app: AppModel
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            VStack {
                Text("MoLobby")
                    .font(.system(size: 50, weight: .bold))
                // Spacer()

                Text("""
Welcome to MoLobby version \(app.verNum)
""")
                // Button move from bottom to avoid getting overlaid with links
                // and rendered inaccessible
                
                GoogleSignInButton()
                    .padding()
                    .onTapGesture {
                        lobbyModel.signIn()
                    }
                
                userDetailRow()

                Button(action: lobbyModel.signInAnonymously) {
                    Text("signInAnonymously")
                }
                Button(action: lobbyModel.signOut) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(.systemIndigo))
                        .cornerRadius(12)
                        .padding(5)
                }
            }
        }
        .onAppear {
            print("LoginView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
        }
        .onDisappear {
            print("LoginView onDisappear")
            app.locationManager.requestUse();
        }
    }
    
    private func userDetailRow() -> some View {
        VStack {
            Text( lobbyModel.uid );
            if let currentUser = lobbyModel.currentUser {
                NavigationLink {
                    UserDetailView(user: currentUser )
                } label: {
                    VStack(alignment: .leading) {
                        Text(currentUser.name)
                            .font(.headline)
                        Text(currentUser.email)
                            .font(.subheadline)
                        Text(currentUser.caption)
                            .lineLimit(1)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        // .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
    }

}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
