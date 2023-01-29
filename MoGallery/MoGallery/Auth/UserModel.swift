//
//  UserViewModel.swift
//  CaptureCameraStorage
//
//  Created by jht2 on 12/19/22.
//

import Foundation

class UserModel: ObservableObject, Identifiable {
    
    @Published var id: String
    @Published var name: String
    @Published var email: String
    @Published var profileImg: String
    @Published var dateIn: Date
    @Published var uploadCount: Int
    @Published var activeCount: Int
    // @Published var activeLapse: TimeInterval

    var activeCountLabel: String? {
        if activeCount > 0 { return String(activeCount) }
        return nil
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
    }
}

