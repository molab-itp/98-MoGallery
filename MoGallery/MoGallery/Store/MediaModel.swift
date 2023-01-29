//
//  MediaModel.swift
//  CaptureCameraStorage
//
//  Created by jht2 on 12/20/22.
//

import Foundation

struct MediaModel:  Identifiable {
    
    var id: String
    var uid: String
    var authorEmail: String
    var mediaPath: String
    var storagePath: String
    var uploadCount: Int
    var createdAt: Date
    var info: [String: Any]
    var ownerRef: [String]
    var mediaPathFullRez: String
    var storagePathFullRez: String
    var createdDate: String
    
    var ownerRefLabel: String {
        ownerRef.isEmpty ? "": "[\( ownerRef[0] )]"
    }
    
    var fullRezWidth: Int {
        info["fullRezWidth"] as? Int ?? -1
    }
    
    var fullRezHeight:Int {
        info["fullRezHeight"] as? Int ?? -1
    }

    var mediaPathDetail: String {
        if !mediaPathFullRez.isEmpty { return mediaPathFullRez }
        return mediaPath
    }

    var width:Int {
        let val = fullRezWidth
        if val > 0 { return val }
        return info["imageWidth"] as? Int ?? -1
    }
    
    var height:Int {
        let val = fullRezHeight
        if val > 0 { return val }
        return info["imageHeight"] as? Int ?? -1
    }

    var sourceDate: String? {
        guard let item = info["sourceDate"] else { return nil }
        return item as? String
    }
    
    var sourceId: String? {
        guard let item = info["sourceId"] else { return nil }
        return item as? String
    }

    var locationDescription: String? {
        guard let lat = info["lat"] as? Double else { return nil }
        guard let lon = info["lon"] as? Double else { return nil }
        return "\( String(format: "%.6f", lat) ) \( String(format: "%.6f", lon) )"
    }

    // init? if we want to allow for invalid entries filter out with compactMap
    // init?(id: String, dict: [String: Any]) {
    init(id: String, dict: [String: Any]) {
        let uid = dict["uid"] as? String ?? ""
        let authorEmail = dict["authorEmail"] as? String ?? ""
        let mediaPath = dict["mediaPath"] as? String ?? ""
        let storagePath = dict["storagePath"] as? String ?? ""
        let uploadCount = dict["uploadCount"] as? Int ?? 0
        let createdAt = dict["createdAt"] as? TimeInterval ?? 0
        let info = dict["info"] as? [String: Any] ?? [:]
        let ownerRef = dict["ownerRef"] as? [String] ?? []
        let mediaPathFullRez = dict["mediaPathFullRez"] as? String ?? ""
        let storagePathFullRez = dict["storagePathFullRez"] as? String ?? ""
        let createdDate = dict["createdDate"] as? String ?? ""
        
        self.id = id
        self.uid = uid
        self.authorEmail = authorEmail
        self.mediaPath = mediaPath
        self.storagePath = storagePath
        self.uploadCount = uploadCount
        self.createdAt = Date(timeIntervalSinceReferenceDate: createdAt);
        self.info = info
        self.ownerRef = ownerRef
        self.mediaPathFullRez = mediaPathFullRez
        self.storagePathFullRez = storagePathFullRez
        self.createdDate = createdDate
    }
}
