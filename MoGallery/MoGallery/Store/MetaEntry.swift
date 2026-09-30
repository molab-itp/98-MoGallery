//
//  MetaEntry.swift
//  MoGallery
//
//  Created by jht2 on 2/9/23.
//

import Foundation
import Observation

@Observable class MetaEntry: Identifiable {

    @ObservationIgnored var id: String
    @ObservationIgnored var uid: String
    @ObservationIgnored var galleryName: String
    @ObservationIgnored var caption: String

    init(id: String, dict: [String: Any]) {

        let uid = dict["uid"] as? String ?? ""
        let galleryName = dict["galleryName"] as? String ?? ""
        let caption = dict["caption"] as? String ?? ""

        self.id = id
        self.uid = uid
        self.galleryName = galleryName
        self.caption = caption
    }
}
