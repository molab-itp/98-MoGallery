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

@Observable class AppModel {

    var settings:Settings = AppModel.loadSettings()
    var selectedTab = TabTag.gallery

    var videoPlayer: AVPlayer?
    var youTubePlayer: YouTubePlayer?

    static let main = AppModel()

    @ObservationIgnored let cameraModel = CameraModel.main
    @ObservationIgnored lazy var lobbyModel = LobbyModel.main
    @ObservationIgnored lazy var galleryModel = GalleryModel.main
    @ObservationIgnored lazy var photosModel = PhotosModel.main
    @ObservationIgnored lazy var metaModel = MetaModel.main
//    lazy var locationModel = LocationModel.main

    @ObservationIgnored var locationManager = LocationManager()
    @ObservationIgnored var geometrySize = CGSize.zero

    @ObservationIgnored var dateFormatter = DateComponentsFormatter()

    @ObservationIgnored lazy var verNum = Self.bundleVersion()

    @ObservationIgnored var photoLibLimited = false

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


