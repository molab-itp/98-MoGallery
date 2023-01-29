//
//  MetaModel.swift
//
//  Created by jht2 on 12/20/22.
//

import FirebaseDatabase

class MetaModel: ObservableObject {
    
    @Published var metas: [MetaEntry] = []

    // mo-meta
    private var metaRef: DatabaseReference? //  = Database.root.child(app.settings.storeGalleryKey)
    private var metaHandle: DatabaseHandle?
    
    unowned var app: AppModel
    init(_ app:AppModel) {
        print("MetaModel init")
        self.app = app
        metaRef = Database.root.child("mo-meta")
    }
    
    func refresh() {
        print("MetaModel refresh")
        observeStop()
        metaRef = Database.root.child("mo-meta")
        observeStart()
    }
    
    func observeStart() {
        guard let metaRef = self.metaRef else { return }
        print("MetaModel observeStart metaHandle", metaHandle ?? "nil")
        if metaHandle != nil {
            return;
        }
        metaHandle = metaRef.observe(.value, with: { snapshot in
            guard let snapItems = snapshot.value as? [String: [String: Any]] else {
                print("MetaModel meta EMPTY")
                self.metas = []
                return
            }
            let items = snapItems.compactMap { MetaEntry(id: $0, dict: $1) }
            let sortedItems = items.sorted(by: { $0.galleryName > $1.galleryName })
            self.metas = sortedItems;
            print("MetaModel metas count", self.metas.count)
        })
    }
    
    func observeStop() {
        guard let metaRef = self.metaRef else { return }
        print("MetaModel observeStop metaHandle", metaHandle ?? "nil")
        if let refHandle = metaHandle {
            metaRef.removeObserver(withHandle: refHandle)
            metaHandle = nil;
        }
    }
    
    func find(galleryName: String) -> MetaEntry? {
        return metas.first(where: { $0.galleryName == galleryName })
    }
    
    func addMeta(galleryName: String) {
        print("addMeta galleryName", galleryName);
        let mentry = find(galleryName: galleryName)
        if mentry != nil {
            print("addMeta present uid", mentry!.uid);
            return;
        }
        guard let user = app.lobbyModel.currentUser else {
            print("addMeta no currentUser");
            return
        }

        var values:[AnyHashable : Any] = [:];
        values["uid"] = user.id;
        values["galleryName"] = galleryName;
        
        guard let metaRef = self.metaRef else { return }
        guard let key = metaRef.childByAutoId().key else {
            print("addMeta no key");
            return
        }
        metaRef.child(key).updateChildValues(values) { error, ref in
            if let error = error {
                print("addMeta updateChildValues error: \(error).")
            }
        }
    }
    
    func removeMeta(galleryName: String) {
        print("removeMeta galleryName", galleryName);
        guard let mentry = find(galleryName: galleryName)
        else {
            print("removeMeta NOT FOUND galleryName", galleryName)
            return;
        }
        // Delete from meta if this user is the creator
        guard let user = app.lobbyModel.currentUser else {
            print("addMeta no currentUser");
            return
        }
        if user.id != mentry.uid {
            print("removeMeta NOT owner mentry.uid", mentry.uid, "user.id", user.id)
            return
        }
        guard let metaRef = self.metaRef else { return }
        metaRef.child(mentry.id).removeValue {error, ref in
            if let error = error {
                print("removeMeta removeValue error: \(error).")
            }
        }
    }
}

struct MetaEntry:  Identifiable {
    var id: String
    var uid: String
    var galleryName: String
    
    init(id: String, dict: [String: Any]) {
        let uid = dict["uid"] as? String ?? ""
        let galleryName = dict["galleryName"] as? String ?? ""

        self.id = id
        self.uid = uid
        self.galleryName = galleryName
    }
}
