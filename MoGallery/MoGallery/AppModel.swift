//
//  AppSetting.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

import Foundation
import SwiftUI

struct Settings: Codable {
    
    var photoAlbum = "-Photo Library-"
    var photoSize = "" // Size is empty string for default full resolution
    var photoAddEnabled = false;
    
    var storePhotoSize = "70"
    var storeAddEnabled = true;
    var storeFullRez = false;
    var storeGalleryKey = "mo-gallery-1"
    var storeLobbyKey = "mo-lobby"
    
    var showUsers = false
    var randomAddWarning = true
    
    var galleryKeys:[String] = ["mo-gallery-1", "mo-gallery-2", "mo-gallery-3"]
}

class AppModel: ObservableObject {
    
    @Published var settings:Settings = AppModel.loadSettings()

    @Published var selectedTab = TabTag.gallery
    
    lazy var cameraModel = CameraModel()
    lazy var lobbyModel = LobbyModel(self)
    lazy var galleryModel = GalleryModel(self)
    lazy var photosModel = PhotosModel(self)
    lazy var metaModel = MetaModel(self)
    
    var locationManager = LocationManager()

    lazy var verNum = Self.bundleVersion()
    
    static func bundleVersion() -> String {
        return String(describing: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)
    }
    
    func initRefresh() {
        // metaModel is not dependent on login status or selected gallery
        // on need to refresh once per app launch
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
    
    func toGalleryTab() {
        selectedTab = .gallery
        print("toGalleryTab galleryModel.path", galleryModel.path)
        if !galleryModel.path.isEmpty {
            galleryModel.path.removeLast()
        }
    }
    
    func updateSettings() {
        saveSettings()
        refreshModels()
        // lobbyModel.signOut()
    }
    
    func removeGalleryKey(at offsets: IndexSet) {
        if let index = offsets.first {
            let name = settings.galleryKeys[index]
            metaModel.removeMeta(galleryName: name)
        }
        settings.galleryKeys.remove(atOffsets: offsets)
    }
    
    func addGalleryKey(name: String) {
        let _ = metaModel.addMeta(galleryName: name)
        settings.galleryKeys.append(name);
    }
    
    var galleryKeysExcludingCurrent: [String] {
        let filter: (String) -> String? = { item in
            if item == self.settings.storeGalleryKey {
                return nil
            }
            return item
        }
        return settings.galleryKeys.compactMap( filter )
    }

    func setStoreGallery(key: String) {
        settings.storeGalleryKey = key
        saveSettings()
        galleryModel.refresh()
        lobbyModel.refresh()
    }
    
    var galleyTitle: String {
        displayTitle(galleryName: settings.storeGalleryKey)
    }

    func displayTitle(galleryName: String) -> String {
        var titl = galleryName
        // zu-oVFxc052pOWF5qq560qMuBmEsbr2-jht1900@gmail-com
        if titl.hasPrefix("zu-") {
            titl = String(titl.dropFirst(32)).replacingOccurrences(of: "-", with: ".")
        }
        return titl
    }
    
    func homeRefLabel(item: MediaModel) -> String {
        var label = ""
        if !item.homeRef.isEmpty {
            label = "[\( displayTitle(galleryName: item.homeRef[0]) )]"
        }
        return label;
    }
}

extension AppModel {
    
    static let savePath = FileManager.documentsDirectory.appendingPathComponent("AppSetting")

    static func loadSettings() -> Settings {
        var settings:Settings;
        do {
            let data = try Data(contentsOf: Self.savePath)
            settings = try JSONDecoder().decode(Settings.self, from: data)
        } catch {
            print("AppModel loadSettings error", error)
            settings = Settings();
        }
        return settings;
    }
    
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: Self.savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("AppModel saveSettings error", error)
        }
    }
}

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

// https://github.com/twostraws/HackingWithSwift.git
//  SwiftUI/project14/Bucketlist/ContentView-ViewModel.swift
// https://github.com/twostraws/HackingWithSwift/blob/main/SwiftUI/project14/Bucketlist/ContentView-ViewModel.swift
