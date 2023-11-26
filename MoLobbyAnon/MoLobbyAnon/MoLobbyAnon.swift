/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI
//import Firebase

// Init firebase and signIn on view appear

@main
struct MoLobbyAnon: App {
    
    var app = AppModel();

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(app)
                .environmentObject(app.lobbyModel)
        }
    }
}

// !!@ Google sample code Database / Storage does not use UIApplicationDelegate
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        FirebaseApp.configure()
//        return true
//    }
//}

// Following latest sample code setup gives this warning
// 2023-01-13 12:40:38.561186-0500 MoGallery[17202:2835966] 9.6.0 - [GoogleUtilities/AppDelegateSwizzler][I-SWZ001014]
//  App Delegate does not conform to UIApplicationDelegate protocol.
//
// https://peterfriese.dev/posts/swiftui-new-app-lifecycle-firebase/
// recommends: Start using the SwiftUI App Life Cycle
