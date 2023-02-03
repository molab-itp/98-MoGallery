//
//  UserViewModel.swift
//  CaptureCameraStorage
//
//  Created by jht2 on 12/19/22.
//

import Foundation
import MapKit

class UserModel: ObservableObject, Identifiable {
    
    @Published var id: String
    @Published var name: String
    @Published var email: String
    @Published var profileImg: String
    @Published var dateIn: Date
    @Published var uploadCount: Int
    @Published var activeCount: Int
    // @Published var activeLapse: TimeInterval
    var info:[AnyHashable : Any] = [:]
    
    var activeCountLabel: String? {
        if activeCount > 0 { return "signin: "+String(activeCount) }
        return nil
    }
    
    var userGalleryKey: String {
        let nemail = email.replacingOccurrences(of: ".", with: "-")
        let str = "zu-\( id )-\( nemail )"
        // print("userGalleryKey", str)
        return str
    }
    
    init(id: String, dict: [String: Any]) {
        let name = dict["name"] as? String ?? ""
        let email = dict["email"] as? String ?? ""
        let profileImg = dict["profileImg"] as? String ?? ""
        let dateIn = dict["dateIn"] as? TimeInterval ?? 0
        let uploadCount = dict["uploadCount"] as? Int ?? 0
        let activeCount = dict["activeCount"] as? Int ?? 0
        // let activeLapse = dict["activeLapse"] as? TimeInterval ?? 0

        self.id = id
        self.name = name;
        self.email = email
        self.profileImg = profileImg
        self.dateIn = Date(timeIntervalSinceReferenceDate: dateIn);
        self.uploadCount = uploadCount
        self.activeCount = activeCount
        // self.activeLapse = activeLapse
        self.info = dict
    }
}

extension UserModel {
    var locationDescription: String? {
        guard let lat = info["lat"] as? Double else { return nil }
        guard let lon = info["lon"] as? Double else { return nil }
        return "\( String(format: "%.6f", lat) ) \( String(format: "%.6f", lon) )"
    }
    var loc: Location? {
        guard let lat = info["lat"] as? Double else { return nil }
        guard let lon = info["lon"] as? Double else { return nil }
        return Location(id: email, latitude: lat, longitude: lon, label: email)
    }
}
