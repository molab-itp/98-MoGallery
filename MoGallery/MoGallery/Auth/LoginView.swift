//
//  LoginView.swift

import SwiftUI

// ?? Why not centered vertically with Spacers

struct LoginView: View {
    
    @StateObject var lobbyModel: LobbyModel

    @EnvironmentObject var app: AppModel
    @Environment(\.openURL) var openURL

    var body: some View {
        // GeometryReader { geometry in
        NavigationStack {
            VStack {
                Text("MoGallery")
                    .font(.system(size: 72, weight: .bold))
                // Spacer()
                
                Text("Welcome to MoGallery (\(app.verNum)).\n\nBy using this app you consent to sharing photos that you select from your Photo Library or Camera to others using the app and possible to the entire web.\n\nPlease give permission to access entire Photo Library.\n\nExperimental alpha software - use at your own risk.\n\nHappy sharing!\n")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(2)
                
                GoogleSignInButton()
                    .padding()
                    .onTapGesture {
                        lobbyModel.signIn()
                    }
//                    .frame(height: 200)
                
//                Link("use social media? jht-site#why",
//                     destination:
//                        URL(string: "https://github.com/jht1493/jht-site#why")! )
//                .padding(8)
//                Link("Mobile Lab Class @ ITP",
//                     destination:
//                        URL(string: "https://github.com/mobilelabclass-itp/content-2023")! )
//                .padding(8)
                Link("MoGallery git repo",
                     destination:
                        URL(string: "https://github.com/mobilelabclass-itp/98-MoGallery")! )
                .padding(16)
                
                // Button("Sign In Anonymously") {
                //  lobbyModel.signInAnonymously()
                // }
            }
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .frame(width: geometry.size.width, height: geometry.size.height)
            // }
        }
        .onAppear {
            print("MainView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
            app.locationManager.requestUse();
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
