//
//  MetaModel.swift
//
//  Created by jht2 on 12/20/22.
//

import FirebaseDatabase

//private var moMetaKey = "mo-meta1"
//private var moMetaKey = "mo-meta"

class MetaModel: ObservableObject {
    
    @Published var metas: [MetaEntry] = []

    // mo-meta
    private var moMetaKey = "mo-meta"
    private var metaRef: DatabaseReference? 
    private var metaHandle: DatabaseHandle?
    var loaded: Bool = false
    var cleaned: Bool = true
    
    static let main = MetaModel()
    lazy var app = AppModel.main;

    init() {
        xprint("MetaModel init")
        moMetaKey = app.settings.storePrefix + "meta"
        metaRef = Database.root.child(moMetaKey)
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
        metaRef = Database.root.child(moMetaKey)
        observeStart()
    }
    
    func observeStart() {
        guard let metaRef else { return }
        xprint("MetaModel observeStart metaHandle", metaHandle ?? "nil")
        if metaHandle != nil {
            return;
        }
        metaHandle = metaRef.observe(.value, with: { snapshot in
            self.receiveSnapShot(snapshot)
        })
    }
    
    func receiveSnapShot(_ snapshot: DataSnapshot) {
        // xprint("MetaModel receiveSnapShot snapshot \(snapshot)")
        guard let snapItems = snapshot.value as? [String: [String: Any]] else {
            xprint("MetaModel meta EMPTY")
            metas = []
            loaded = true
            return
        }
        let items = snapItems.compactMap { MetaEntry(id: $0, dict: $1) }
        let sortedItems = items.sorted(by: { $0.galleryName < $1.galleryName })
        metas = sortedItems;
        xprint("MetaModel metas count", metas.count)
        // if (metas.count > 1000 && !cleaned) {
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
            metaRef.child(mentry.id).removeValue {error, ref in
                if let error = error {
                    xprint("removeAllMetas removeValue error: \(error).")
                }
            }
        }
        metas = []
    }
    
    func observeStop() {
        guard let metaRef else { return }
        xprint("MetaModel observeStop metaHandle", metaHandle ?? "nil")
        if let refHandle = metaHandle {
            metaRef.removeObserver(withHandle: refHandle)
            metaHandle = nil;
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
        guard let key = metaRef.childByAutoId().key else {
            xprint("addMeta no key")
            return nil
        }
        var values:[String : Any] = [:];
        values["uid"] = user.id;
        values["galleryName"] = galleryName;
        metaRef.child(key).updateChildValues(values) { error, ref in
            if let error = error {
                xprint("addMeta updateChildValues error: \(error).")
            }
        }
        let newEnt = MetaEntry(id: key, dict: values)
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
        metaRef.child(mentry.id).removeValue {error, ref in
            if let error = error {
                xprint("removeMeta removeValue error: \(error).")
            }
        }
    }
    
    // update the caption property
    func update(metaEntry: MetaEntry) {
        guard let metaRef else { return }
        var values:[String: Any] = [:];
        values["caption"] = metaEntry.caption;
        metaRef.child(metaEntry.id).updateChildValues(values) { error, ref in
            if let error = error {
                xprint("update metaEntry updateChildValues error: \(error).")
            }
        }
    }
}

