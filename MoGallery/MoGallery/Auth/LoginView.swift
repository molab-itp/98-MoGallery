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
                
                Text("""
Welcome to MoGallery v\(app.verNum)

Please give permission to access your entire Photo Library. This does not automatically make your entire library visible to other users of the app. You have to specifically add items to galleries from your Photo Library or Camera to make them visible to other users.

All users are by invitation of the developer only and are visible to each other.

Experimental alpha software - use at your own risk. You can always delete shared items if you change your mind.

Don't worry, be happy sharing!
""")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(2)
                
                GoogleSignInButton()
                    .padding()
                    .onTapGesture {
                        lobbyModel.signIn()
                    }
                    // .frame(height: 200)
//                Link("use social media? jht-site#why",
//                     destination:
//                        URL(string: "https://github.com/jht1493/jht-site#why")! )
//                .padding(8)
                Link("Video overview youtube.com",
                     destination:
                        URL(string: "https://jht1493.net/MoGallery/VideoOverView")! )
                .padding(14)
                Link("MoGallery github.com",
                     destination:
                        URL(string: "https://github.com/mobilelabclass-itp/98-MoGallery")! )
                .padding(14)
                
                // Button("Sign In Anonymously") {
                //  lobbyModel.signInAnonymously()
                // }
            }
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
            // .frame(width: geometry.size.width, height: geometry.size.height)
            // }
        }
        .onAppear {
            print("LoginView onAppear currentUser", lobbyModel.currentUser?.email ?? "-none-")
        }
        .onDisappear {
            print("LoginView onDisappear")
            app.locationManager.requestUse();
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
