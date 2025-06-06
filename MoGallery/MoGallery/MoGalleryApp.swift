/*
 See the License.txt file for this sample’s licensing information.
 */

import SwiftUI
import Firebase

func xprint(_ args:Any...) {
  print( args )
  // debugPrint( args )
}

// Init firebase and signIn on view appear

@main
struct MoGalleryApp: App {
    
// !!@ not done in
// quickstart-ios/firestore/FirestoreSwiftUIExample/FirestoreSwiftUIExampleApp.swift
// register app delegate for Firebase setup
// @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var app = AppModel.main;

    init() {
        UINavigationBar.applyCustomAppearance()
        FirebaseApp.configure()
        app.initRefresh()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginCheckView()
                .environmentObject(AppModel.main)
                .environmentObject(CameraModel.main)
                .environmentObject(LobbyModel.main)
                .environmentObject(GalleryModel.main)
                .environmentObject(PhotosModel.main)
                .environmentObject(MetaModel.main)
                .environmentObject(LocationModel.main)
                .onAppear {
                    xprint("MoGalleryApp onAppear")
                    // For UIApplicationDelegateAdaptor must refreshModels here
                    // app.refreshModels()
                    app.lobbyModel.signIn()
                }
                .onDisappear {
                    xprint("MoGalleryApp onDisappear")
                }
        }
    }
}

fileprivate extension UINavigationBar {
    
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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

/*
 2023-12-30 13:39:44

 */
