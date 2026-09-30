//
//  FirestorePaths.swift
//  MoGallery
//
//  Created by ChatGPT on 11/21/25.
//

import FirebaseFirestore

enum FirestorePaths {
    
    private static func normalizedPrefix(_ prefix: String) -> String {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutSlashes = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let collapsed = withoutSlashes.replacingOccurrences(of: "/", with: "-")
        return collapsed.isEmpty ? "default" : collapsed
    }
    
    private static func namespaceDocument(prefix: String) -> DocumentReference {
        let namespaceId = normalizedPrefix(prefix)
        return Firestore.firestore()
            .collection("gstore")
            .document(namespaceId)
    }
    
    static func galleryEntries(prefix: String, key: String) -> CollectionReference {
        namespaceDocument(prefix: prefix)
            .collection("galleries")
            .document(key)
            .collection("entries")
    }
    
    static func lobbyUsers(prefix: String, lobbyKey: String) -> CollectionReference {
        namespaceDocument(prefix: prefix)
            .collection("lobbies")
            .document(lobbyKey)
            .collection("users")
    }
    
    static func metaEntries(prefix: String) -> CollectionReference {
        namespaceDocument(prefix: prefix)
            .collection("metaEntries")
    }
}


