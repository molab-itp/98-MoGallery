//
//  AppSetting.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

import SwiftUI
import Firebase

class AppModel: ObservableObject {
    
    @Published var settings:Settings = AppModel.loadSettings()
    @Published var selectedTab = TabTag.lobby

    init() {
        FirebaseApp.configure()
        initRefresh()
    }
    
    lazy var lobbyModel = LobbyModel(self)
    
    var locationManager = LocationManager()
    var geometrySize = CGSize.zero
    
    var dateFormatter = DateComponentsFormatter()
    
    lazy var verNum = Self.bundleVersion()
        
    func string(duration: Double) -> String {
        if let str = dateFormatter.string(from: duration) {
            return str
        }
        return ""
    }
    
    func initRefresh() {
        refreshModels()
    }
    
    func refreshModels() {
        lobbyModel.refresh()
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
