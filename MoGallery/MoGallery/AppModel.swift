//
//  AppSetting.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

import Foundation
import SwiftUI
import AVKit
import Photos
import YouTubePlayerKit

class AppModel: ObservableObject {
    
    @Published var settings:Settings = AppModel.loadSettings()
    @Published var selectedTab = TabTag.gallery
    
    @Published var videoPlayer: AVPlayer?
    @Published var youTubePlayer: YouTubePlayer?

    lazy var cameraModel = CameraModel()
    lazy var lobbyModel = LobbyModel(self)
    lazy var galleryModel = GalleryModel(self)
    lazy var photosModel = PhotosModel(self)
    lazy var metaModel = MetaModel(self)
    
    var locationManager = LocationManager()
    var geometrySize = CGSize.zero

    lazy var verNum = Self.bundleVersion()

    func playVideo(url ref: String) {
        // https://bit.ly/swswift
        // https://jht1493.net/macr/mov/sample_640x360.mp4
        print("playVideo url", ref)
        if ref.hasPrefix("https://youtu.be/") ||
            ref.hasPrefix("https://youtube.com") {
            playVideo(youTubeUrl: ref)
        }
        else if !ref.hasPrefix("https://") {
            playVideo(youTubeId: ref)
        }
        else {
            guard let url = URL(string: ref) else {
                print("playVideo url failed")
                return
            }
            videoPlayer = AVPlayer(url: url);
            videoPlayer?.play()
        }
    }
    
    func playVideo(youTubeId ref: String) {
        print("playVideo youTubeId ref", ref)
        // youTubePlayer = "https://youtube.com/watch?v=psL_5RIBqnY"
        youTubePlayer = YouTubePlayer(
            source: .video(id: ref),
            configuration: .init(
                autoPlay: true
            )
        )
    }
    
    func playVideo(youTubeUrl ref: String) {
        print("playVideo youTubeUrl ref", ref)
        // https://youtube.com/watch?v=psL_5RIBqnY
        // https://youtu.be/-Vmv9BMv7AQ
        youTubePlayer = YouTubePlayer(
            source: .url(ref),
            configuration: .init(
                autoPlay: true
            )
        )
    }
    
    func playVideo(phAsset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        manager.requestPlayerItem( forVideo: phAsset, options: options ) {
                playerItem, info in
            print("playVideo playerItem", playerItem ?? "-nil-")
            print("playVideo info", info ?? "-nil-")
            self.videoPlayer = AVPlayer(playerItem: playerItem)
            self.videoPlayer?.play()
        }
    }
    
    func stopVideo() {
        print("videoStop")
        youTubePlayer = nil
        videoPlayer = nil
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
    
    func selectGallery(key: String) {
        setStoreGallery(key: key)
        toGalleryTab()
    }
    
    func toGalleryTab() {
        selectedTab = .gallery
        print("toGalleryTab galleryModel.path", galleryModel.path)
        while !galleryModel.path.isEmpty {
            galleryModel.path.removeLast()
        }
    }
    
    func toMapTab() {
        selectedTab = .map
    }

    func updateSettings() {
        saveSettings()
        refreshModels()
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
    
} // class AppModel

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
