//
//  AppSetting.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

import SwiftUI
import AVKit
import Photos
import YouTubePlayerKit

class AppModel: ObservableObject {
    
    @Published var settings:Settings = AppModel.loadSettings()
    @Published var selectedTab = TabTag.gallery
    
    @Published var videoPlayer: AVPlayer?
    @Published var youTubePlayer: YouTubePlayer?
    
    static let main = AppModel()

    let cameraModel = CameraModel.main
    lazy var lobbyModel = LobbyModel.main
    lazy var galleryModel = GalleryModel.main
    lazy var photosModel = PhotosModel.main
    lazy var metaModel = MetaModel.main
//    lazy var locationModel = LocationModel.main
        
    var locationManager = LocationManager()
    var geometrySize = CGSize.zero
    
    var dateFormatter = DateComponentsFormatter()
    
    lazy var verNum = Self.bundleVersion()
    
    var photoLibLimited = false;
    
    func string(duration: Double) -> String {
        if let str = dateFormatter.string(from: duration) {
            return str
        }
        return ""
    }
    
    func initRefresh() {
        // metaModel is not dependent on login status or selected gallery
        // only need to refresh once per app launch
        metaModel.refresh()
        refreshModels()
    }
    
    func refreshModels() {
        cameraModel.photoInfoProvided = { photoInfo in
            self.photosModel.savePhoto(photoInfo: photoInfo)
            // Exit camera view back to gallery after Camera capture
            self.toGalleryTab()
        }
        cameraModel.previewImageProvided = { image in
            self.photosModel.viewfinderImage = image
        }
        cameraModel.refresh()
        lobbyModel.refresh()
        galleryModel.refresh()
        photosModel.refresh()
    }
    
    func toMapTab() {
        selectedTab = .map
    }
    
    func updateSettings() {
        saveSettings()
        refreshModels()
    }

//    func userGalleryKey(user: UserModel) -> String {
//        let nemail = user.email.replacingOccurrences(of: ".", with: "-")
//        let str = "zu-\( user.id )-\( nemail )"
//        // let str = settings.storePrefix + "zu-\( user.id )-\( nemail )"
//        // let str = "zu-\( id )-\( nemail )"
//        // xprint("userGalleryKey", str)
//        return str;
//    }
    
} // class AppModel

// load and save settings
//
extension AppModel {
    
    static let savePath = FileManager.documentsDirectory.appendingPathComponent("AppSetting")
    
    static func loadSettings() -> Settings {
        var settings:Settings;
        do {
            let data = try Data(contentsOf: Self.savePath)
            settings = try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            xprint("AppModel loadSettings error", error)
            settings = Settings();
        }
        return settings;
    }
    
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: Self.savePath, options: [.atomic, .completeFileProtection])
        } catch {
            xprint("AppModel saveSettings error", error)
        }
    }
    
    static func bundleVersion() -> String {
        return String(describing: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)
    }
    
} // extension AppModel

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
} // extension FileManager

// https://github.com/twostraws/HackingWithSwift.git
//  SwiftUI/project14/Bucketlist/ContentView-ViewModel.swift
// https://github.com/twostraws/HackingWithSwift/blob/main/SwiftUI/project14/Bucketlist/ContentView-ViewModel.swift
