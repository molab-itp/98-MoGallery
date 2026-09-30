//
//  MetaModel.swift
//
//  Created by jht2 on 12/20/22.
//

import FirebaseFirestore
import Observation

//private var moMetaKey = "mo-meta1"
//private var moMetaKey = "mo-meta"

@Observable class MetaModel {

    var metas: [MetaEntry] = []

    // mo-meta
    @ObservationIgnored private var moMetaKey = "mo-meta"
    @ObservationIgnored private var metaRef: CollectionReference?
    @ObservationIgnored private var metaListener: ListenerRegistration?
    @ObservationIgnored var loaded: Bool = false
    @ObservationIgnored var cleaned: Bool = true

    static let main = MetaModel()
    @ObservationIgnored lazy var app = AppModel.main

    init() {
        xprint("MetaModel init")
        moMetaKey = app.settings.storePrefix + "meta"
        metaRef = FirestorePaths.metaEntries(prefix: app.settings.storePrefix)
    }
    
    func allGalleryKeys() -> [String] {
        metas.map( { item in
            var ngalleryName = item.galleryName
            let pre = app.settings.storePrefix
            if item.galleryName.hasPrefix(pre) {
                ngalleryName = String(ngalleryName.dropFirst(pre.count))
            }
            return ngalleryName
        })
    }
    
    func refresh() {
        xprint("MetaModel refresh")
        observeStop()
        metaRef = FirestorePaths.metaEntries(prefix: app.settings.storePrefix)
        observeStart()
    }
    
    func observeStart() {
        guard let metaRef else { return }
        xprint("MetaModel observeStart metaListener", metaListener as Any)
        if metaListener != nil {
            return;
        }
        metaListener = metaRef.addSnapshotListener { snapshot, error in
            if let error = error {
                xprint("MetaModel snapshot error", error.localizedDescription)
                return
            }
            guard let snapshot else {
                xprint("MetaModel snapshot nil")
                self.metas = []
                self.loaded = true
                return
            }
            self.receiveSnapShot(snapshot)
        }
    }
    
    func receiveSnapShot(_ snapshot: QuerySnapshot) {
        let documents = snapshot.documents
        guard !documents.isEmpty else {
            xprint("MetaModel meta EMPTY")
            metas = []
            loaded = true
            return
        }
        let items = documents.compactMap { MetaEntry(id: $0.documentID, dict: $0.data()) }
        let sortedItems = items.sorted(by: { $0.galleryName < $1.galleryName })
        metas = sortedItems;
        xprint("MetaModel metas count", metas.count)
        if !cleaned {
            cleaned = true
            removeAllMetas()
        }
        loaded = true
    }
    
    func removeAllMetas() {
        xprint("removeAllMetas metaRef", metaRef ?? "-nil-")
        guard let metaRef else { return }
//        metaRef.removeValue { error, ref in
//            if let error = error {
//                xprint("removeMeta removeValue error: \(error).")
//            }
//        }
        var count = 0
        for mentry in metas {
            if count % 1000 == 0 {
                xprint(count, "removeAllMetas mentry.id ", mentry.id)
            }
            count += 1
            metaRef.document(mentry.id).delete { error in
                if let error = error {
                    xprint("removeAllMetas delete error: \(error).")
                }
            }
        }
        metas = []
    }
    
    func observeStop() {
        xprint("MetaModel observeStop metaListener", metaListener as Any)
        if let listener = metaListener {
            listener.remove()
            metaListener = nil;
        }
    }
    
    func find(galleryName: String) -> MetaEntry? {
        return metas.first(where: { $0.galleryName == galleryName })
    }
    
    func fetch(galleryName: String) -> MetaEntry?  {
        xprint("fetch galleryName", galleryName);
        if let metaEntry = find(galleryName: galleryName) {
            return metaEntry
        }
        guard let user = app.lobbyModel.currentUser else {
            xprint("fetch galleryName no currentUser")
            return nil
        }
        return addMeta(galleryName: galleryName, user: user)
    }
    
    func addMeta(galleryName: String) -> MetaEntry? {
        xprint("addMeta galleryName", galleryName);
        guard let user = app.lobbyModel.currentUser else {
            xprint("addMeta no currentUser")
            return nil
        }
        return addMeta(galleryName: galleryName, user: user)
    }
    
    func addMeta(galleryName: String, user: UserModel?) -> MetaEntry? {
        xprint("addMeta user galleryName", galleryName);
        xprint("addMeta loaded", loaded);
        
        // return nil; // !!@
        guard loaded else { return nil }
        
        let mentry = find(galleryName: galleryName)
        if let mentry  {
            xprint("addMeta present uid", mentry.uid);
            return mentry;
        }
        guard let user else {
            xprint("addMeta no currentUser")
            return nil
        }
        guard let metaRef else {
            xprint("addMeta no metaRef")
            return nil
        }
        var values:[String : Any] = [:];
        values["uid"] = user.id;
        values["galleryName"] = galleryName;
        let docRef = metaRef.addDocument(data: values) { error in
            if let error = error {
                xprint("addMeta setData error: \(error).")
            }
        }
        let newEnt = MetaEntry(id: docRef.documentID, dict: values)
        metas.append( newEnt )
        return newEnt
    }
    
    func removeMeta(galleryName: String) {
        xprint("removeMeta galleryName", galleryName);
        guard let mentry = find(galleryName: galleryName)
        else {
            xprint("removeMeta NOT FOUND galleryName", galleryName)
            return;
        }
        // Delete from meta if this user is the creator
        guard let user = app.lobbyModel.currentUser else {
            xprint("addMeta no currentUser");
            return
        }
        if user.id != mentry.uid {
            xprint("removeMeta NOT owner mentry.uid", mentry.uid, "user.id", user.id)
            return
        }
        guard let metaRef else { return }
        metaRef.document(mentry.id).delete { error in
            if let error = error {
                xprint("removeMeta delete error: \(error).")
            }
        }
    }
    
    // update the caption property
    func update(metaEntry: MetaEntry) {
        guard let metaRef else { return }
        var values:[String: Any] = [:];
        values["caption"] = metaEntry.caption;
        metaRef.document(metaEntry.id).setData(values, merge: true) { error in
            if let error = error {
                xprint("update metaEntry setData error: \(error).")
            }
        }
    }
}

