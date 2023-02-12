//
//  MetaEntry.swift
//  MoGallery
//
//  Created by jht2 on 2/9/23.
//

import Foundation

// struct MetaEntry:  Identifiable {
class MetaEntry: ObservableObject, Identifiable {
    var id: String
    var uid: String
    var galleryName: String
    var status: String
    
    init(id: String, dict: [String: Any]) {
        let uid = dict["uid"] as? String ?? ""
        let galleryName = dict["galleryName"] as? String ?? ""
        let status = dict["status"] as? String ?? ""

        self.id = id
        self.uid = uid
        self.galleryName = galleryName
        self.status = status
    }
}
