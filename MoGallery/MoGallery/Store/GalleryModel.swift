//
//  GalleryModel.swift
//  MoGallery
//
//  Created by jht2 on 12/20/22.
//

import FirebaseDatabase
import FirebaseStorage
import Photos
import UIKit
import SwiftUI

// load array of MediaModel items for database
// sort by createdAt to show most recent first

class GalleryModel: ObservableObject {
    
    @Published var gallery: [MediaModel] = []
    @Published var currentMeta: MetaEntry?

    @Published var path: NavigationPath = NavigationPath()
    
    var countMine = 0

    // mo-gallery
    var galleryRef: DatabaseReference?
    var galleryHandle: DatabaseHandle?
    var storage = Storage.storage()
    
    static let main = GalleryModel()
    lazy var app = AppModel.main;
//    unowned var app: AppModel
//    init(_ app:AppModel) {
//        self.app = app
//    }
    
    func deleteWarning() -> String {
        "Are you sure you want to delete your \(countMine) photos in this gallery?"
    }
    
    func countDisplayText() -> String {
        if countMine != gallery.count {
            return "\(gallery.count) items, mine: \(countMine)"
        }
        return "\(gallery.count) items"
    }
    
    func itemFor(id: String) -> MediaModel? {
        return gallery.first(where: { $0.id == id } )
    }
    
    func refresh() {
        xprint("GalleryModel refresh storeGalleryKey", app.settings.storeGalleryKey)
        let galleryName = app.settings.storeGalleryKey
        let ngalleryName = app.settings.storePrefix + app.settings.storeGalleryKey
        observeStop()
        galleryRef = Database.root.child(ngalleryName)
        observeStart()
        currentMeta = app.metaModel.fetch(galleryName: galleryName)
    }
    
    func observeStart() {
        guard let galleryRef else { return }
        xprint("GalleryModel observeStart galleryHandle", galleryHandle ?? "nil")
        if galleryHandle != nil {
            return;
        }
        galleryHandle = galleryRef.observe(.value, with: { snapshot in
            Task {
                await self.receiveSnapShot(snapshot)
            }
        })
    }
    
    @MainActor func receiveSnapShot(_ snapshot: DataSnapshot) {
        // xprint("GalleryModel receiveSnapShot snapshot \(snapshot)")
        guard let snapItems = snapshot.value as? [String: [String: Any]] else {
            xprint("GalleryModel gallery EMPTY")
            gallery = []
            countMine = 0
            return
        }
        guard let uid = app.lobbyModel.uid else {
            xprint("GalleryModel gallery NO uid")
            return
        }
        let items = snapItems.compactMap { MediaModel(id: $0, dict: $1) }
        let sortedItems = items.sorted(by: { $0.createdAt > $1.createdAt })
        gallery = sortedItems;
        // Count all the item that match current user id
        countMine = sortedItems.reduce(0, { count, item in
            count + (item.uid == uid ? 1 : 0)
        })
        xprint("GalleryModel gallery count", gallery.count)
        xprint("GalleryModel gallery countMine", countMine)
    }
    
    func observeStop() {
        guard let galleryRef else { return }
        xprint("GalleryModel observeStop mediaHandle", galleryHandle ?? "nil")
        if let refHandle = galleryHandle {
            galleryRef.removeObserver(withHandle: refHandle)
            galleryHandle = nil;
        }
    }
    
    func dbGalleryRef(key: String) -> DatabaseReference? {
        xprint("dbGalleryRef key", key)
        let nkey = app.settings.storePrefix + key
        return Database.root.child(nkey)
    }
    
    func deleteAll() {
        guard let uid = self.app.lobbyModel.uid else {
            xprint("GalleryModel deleteAll NO uid")
            return
        }
        for item in gallery {
            if item.uid == uid {
                deleteMedia(mediaItem: item)
            }
            else {
                xprint("GalleryModel deleteAll skipping uid", item.uid)
            }
        }
    }
    
    // mediaItem is in the current gallery
    // remove it from the gallery
    // add delete any associated storage
    //
    func deleteMedia(mediaItem: MediaModel) {
        xprint("deleteMedia mediaItem \(mediaItem)")

        deleteMediaEntry(mediaItem: mediaItem)

        // Don't delete media of copied references
        guard mediaItem.homeRef.isEmpty else {
            xprint("deleteMedia storage no delete homeRef: \(mediaItem.homeRef)")
            return
        }
        
        // Do only for owner reference to media
        
        deleteMediaUserRef(mediaItem: mediaItem)

        // Delete the media low rez file
        let storageRef = storage.reference(withPath: mediaItem.storagePath)
        storageRef.delete { error in
            if let error = error {
                xprint("deleteMedia storageRef error: \(error)")
            }
        }
        // Delete the full rez file
        if !mediaItem.storagePathFullRez.isEmpty {
            let storageRefFullRez = storage.reference(withPath: mediaItem.storagePathFullRez)
            storageRefFullRez.delete { error in
                if let error = error {
                    xprint("deleteMedia storageRefFullRez error: \(error)")
                }
            }
        }
    }
    
    // Delete the media entry from its gallery
    func deleteMediaEntry(mediaItem: MediaModel) {
        xprint("deleteMediaEntry mediaItem.id \(mediaItem.id)")
        guard let galleryRef else {
            xprint("deleteMediaEntry !! NO \(String(describing: galleryRef))")
            return
        }
        // Delete the media item database entry
        galleryRef.child(mediaItem.id).removeValue { error, ref in
            xprint("deleteMediaEntry error \(String(describing: error)) ref \(ref)")
            if let error = error {
                xprint("deleteMediaEntry removeValue error: \(error)")
            }
        }
    }
    
    func deleteMediaUserRef(mediaItem: MediaModel) {
        // remove userGalleryChildId if present
        let userGalleryChildId = mediaItem.userGalleryChildId
        if !userGalleryChildId.isEmpty {
            guard let user = app.lobbyModel.user(uid: mediaItem.uid) else {
                xprint("deleteMedia no user for mediaItem.uid", mediaItem.uid)
                return
            }
            let key = user.userGalleryKey
            // let key = app.userGalleryKey(user: user);
            guard let userGalleryRef = dbGalleryRef(key: key) else {
                xprint("deleteMedia no userGalleryRef userGalleryKey", key)
                return
            }
            userGalleryRef.child(userGalleryChildId).removeValue {error, ref in
                if let error = error {
                    xprint("deleteMedia userGalleryRef removeValue error: \(error)")
                }
            }
        }
    }
    
    // Store image from camera
    func getSaveImageData(photoInfo: PhotoInfo) -> Data? {
        xprint("getSaveImageData photoInfo \(photoInfo)")
        let cgImage = photoInfo.cgImage;
        let orient = photoInfo.orient;
        
        // Scale image for Firebase storage
        var fullRezData: Data?
        var fullRezSize: CGSize?
        var imageData = photoInfo.imageData;
        var imageSize = CGSize(width: photoInfo.imageSize.width, height: photoInfo.imageSize.height);
        var dim = Int(app.settings.storePhotoSize) ?? 0;
        if dim != 0 {
            let targetSize = CGSize(width: dim, height: dim)
            let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orient);
            let nimage = uiImage.scalePreservingAspectRatio(targetSize: targetSize)
            guard let nimageData = nimage.jpegData(compressionQuality: 1)
            else { return nil }
            if app.settings.storeFullRez {
                fullRezData = imageData
                fullRezSize = imageSize
            }
            imageData = nimageData
            imageSize = nimage.size
        }
        if (app.settings.storeAddEnabled ) {
            //  "sourceId": sourceId,
            //  "sourceDate": sourceDate,
            //  "imageWidth": imageSize.width,
            //  "imageHeight": imageSize.height,
            //  "lat": lat,
            //  "lon": lon,
            let sourceDate = Date().description
            var info:[String: Any] = [
                "imageWidth": imageSize.width,
                "imageHeight": imageSize.height,
                "sourceDate": sourceDate,
            ]
            if let fullRezSize {
                info["fullRezWidth"] = fullRezSize.width
                info["fullRezHeight"] = fullRezSize.height
            }
            if let loc = app.locationManager.lastLocation {
                info["lat"] = loc.coordinate.latitude;
                info["lon"] = loc.coordinate.longitude
            }
            uploadImageData(imageData,
                            fullRezData: fullRezData,
                            info: info)
        }
        // Saving to Photo library, check for scaling
        if !app.settings.photoAddEnabled {
            return nil
        }
        dim = Int(app.settings.photoSize) ?? 0;
        if dim != 0 {
            let targetSize = CGSize(width: dim, height: dim)
            let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orient);
            let nimage = uiImage.scalePreservingAspectRatio(targetSize: targetSize)
            guard let nimageData = nimage.jpegData(compressionQuality: 1)
            else { return nil }
            imageData = nimageData
        }
        else {
            imageData = photoInfo.imageData
        }
        return imageData;
    }
    
}
