//
//  GalleryModel.swift
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
    var countMine = 0

    @Published var path: NavigationPath = NavigationPath()

    // mo-gallery
    private var galleryRef: DatabaseReference? 
    private var galleryHandle: DatabaseHandle?
    private var storage = Storage.storage()
    
    unowned var app: AppModel
    init(_ app:AppModel) {
        self.app = app
    }

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
        print("GalleryModel refresh storeGalleryKey", app.settings.storeGalleryKey)
        observeStop()
        galleryRef = Database.root.child(app.settings.storeGalleryKey)
        observeStart()
    }
    
    func observeStart() {
        guard let galleryRef else { return }
        print("GalleryModel observeStart galleryHandle", galleryHandle ?? "nil")
        if galleryHandle != nil {
            return;
        }
        galleryHandle = galleryRef.observe(.value, with: { snapshot in
            self.receiveSnapShot(snapshot)
        })
    }
    
    func receiveSnapShot(_ snapshot: DataSnapshot) {
        guard let snapItems = snapshot.value as? [String: [String: Any]] else {
            print("GalleryModel gallery EMPTY")
            gallery = []
            countMine = 0
            return
        }
        guard let uid = app.lobbyModel.uid else {
            print("GalleryModel gallery NO uid")
            return
        }
        let items = snapItems.compactMap { MediaModel(id: $0, dict: $1) }
        let sortedItems = items.sorted(by: { $0.createdAt > $1.createdAt })
        gallery = sortedItems;
        // Count all the item that match current user id
        countMine = sortedItems.reduce(0, { count, item in
            count + (item.uid == uid ? 1 : 0)
        })
        print("GalleryModel gallery count", gallery.count)
        print("GalleryModel gallery countMine", countMine)
    }
    
    func observeStop() {
        guard let galleryRef else { return }
        print("GalleryModel observeStop mediaHandle", galleryHandle ?? "nil")
        if let refHandle = galleryHandle {
            galleryRef.removeObserver(withHandle: refHandle)
            galleryHandle = nil;
        }
    }
    
    func uploadImageData(_ imageData: Data,
                         fullRezData: Data?,
                         info: [String:Any]) {
        
        guard let lobbyRef = app.lobbyModel.lobbyRef else { return }
        guard let user = app.lobbyModel.currentUser else {
            print("uploadImageData no currentUser");
            return
        }
        // upload filepath is userid/uploadCount.jpeg
        let uid = user.id
        
        // add 1 to user uploadCount
        var values:[AnyHashable : Any] = [:];
        values["uploadCount"] = ServerValue.increment(1);
        lobbyRef.child(uid).updateChildValues(values) { error, ref in
            if let error = error {
                print("uploadImageData uploadCount error: \(error).")
            }
        }
        // !!@ May get out of sync with users logged in multiple times
        // !!@ Need to observe current user
        user.uploadCount += 1;
        
        // Create file metadata including the content type
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public,max-age=300"
        
        let filePath = uid + "/\(user.uploadCount).jpeg"
        let storageRef = storage.reference(withPath: filePath)
        
        // fullRezData
        // + mediaPathFullRez
        // + storagePathFullRez
        let filePathFullRez = uid + "/\(user.uploadCount)z.jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            guard let metad = metadata else {
                print("uploadImageData no metadata")
                return
            }
            print("uploadImageData metad size", metad.size)
            // You can also access to download URL after upload.
            self.fetchDownloadURL(storageRef,
                                  storagePath: filePath,
                                  metadata: metadata,
                                  info: info,
                                  fullRezData: fullRezData,
                                  filePathFullRez: filePathFullRez)
        }
    }
    
    func fetchDownloadURL(_ storageRef: StorageReference,
                          storagePath: String,
                          metadata: StorageMetadata?,
                          info: [String:Any],
                          fullRezData: Data?,
                          filePathFullRez: String) {
        
        storageRef.downloadURL { url, error in
            guard let downloadURL = url else {
                print("fetchDownloadURL download URL error : \(error.debugDescription)")
                return
            }
            // print("fetchDownloadURL download url:\n \(downloadURL) ")
            
            var values: [AnyHashable : Any] = [:];
            values["mediaPath"] = downloadURL.description;
            values["storagePath"] = storagePath;
            
            if let fullRezData {
                self.putFullRezData(metadata: metadata,
                                    info: info,
                                    values: values,
                                    fullRezData: fullRezData,
                                    filePathFullRez: filePathFullRez)
            }
            else {
                self.createMediaEntry(info: info,
                                      values: values,
                                      galleryRef: self.galleryRef,
                                      galleryKey: self.app.settings.storeGalleryKey,
                                      user: self.app.lobbyModel.currentUser);
            }
        }
    }
    
    func putFullRezData(metadata: StorageMetadata?,
                        info: [String:Any],
                        values: [AnyHashable : Any] ,
                        fullRezData: Data,
                        filePathFullRez: String) {
        
        let storageRefFullRez = storage.reference(withPath: filePathFullRez)
        storageRefFullRez.putData(fullRezData, metadata: metadata) { metadata, error in
            guard let metad = metadata else {
                print("putFullRezData no metadata")
                return
            }
            print("putFullRezData metad size", metad.size)
            // You can also access to download URL after upload.
            self.fetchDownloadURL_FullRez(storageRefFullRez,
                                          info: info,
                                          values: values,
                                          filePathFullRez: filePathFullRez)
        }
    }
    
    func fetchDownloadURL_FullRez(_ storageRefFullRez: StorageReference,
                          info: [String:Any],
                          values: [AnyHashable : Any] ,
                          filePathFullRez: String) {
        
        storageRefFullRez.downloadURL { url, error in
            guard let downloadURL = url else {
                print("fetchDownloadURL_FullRez download URL error : \(error.debugDescription)")
                return
            }
            // print("fetchDownloadURL download url:\n \(downloadURL) ")

            var nvalues = values;
            nvalues["mediaPathFullRez"] = downloadURL.description;
            nvalues["storagePathFullRez"] = filePathFullRez;

            self.createMediaEntry(info: info,
                                  values: nvalues,
                                  galleryRef: self.galleryRef,
                                  galleryKey: self.app.settings.storeGalleryKey,
                                  user: self.app.lobbyModel.currentUser);
        }
    }
    
    func createMediaEntry(info: [String:Any],
                          values: [AnyHashable : Any],
                          galleryRef: DatabaseReference?,
                          galleryKey: String,
                          user: UserModel? ) {
        
        // print("createMediaEntry mediaPath", mediaPath)
        print("createMediaEntry storagePath", info["storagePath"] ?? "-nil-")
        print("createMediaEntry user", user ?? "-nil-")

        guard let galleryRef else { return }
        guard let user else { print("createMediaEntry no user"); return }
        
        // !!@ Disabled
        // var info = info;
        // Stamp any item with out location info this current location
//        if info["lat"] == nil, let loc = app.locationManager.lastLocation {
//            print("createMediaEntry loc", loc)
//            info["lat"] = loc.coordinate.latitude;
//            info["lon"] = loc.coordinate.longitude
//        }

        let date = Date()
        var values = values;
        values["uid"] = user.id;
        values["authorEmail"] = user.email;
        values["uploadCount"] = user.uploadCount;
        values["createdAt"] = date.timeIntervalSinceReferenceDate;
        values["createdDate"] = date.description;
        values["info"] = info;
        
        guard let key = galleryRef.childByAutoId().key else {
            print("createMediaEntry no key");
            return
        }

        let userGalleryKey = user.userGalleryKey
        
        // If not linked
        // and not in userGallery, add to userGallery
        
        if values["homeRef"] == nil && app.settings.storeGalleryKey != userGalleryKey {
            let userGalleryRef = dbGalleryRef(key: userGalleryKey)
            guard let userGalleryRef else {
                print("createMediaEntry no userGalleryRef")
                return
            }
            guard let userGalleryChildId = userGalleryRef.childByAutoId().key else {
                print("createMediaEntry no userGalleryChildId")
                return
            }
            var nvalues = values;
            nvalues["homeRef"] = [galleryKey, key]
            userGalleryRef.child(userGalleryChildId).updateChildValues(nvalues) { error, ref in
                if let error = error {
                    print("createMediaEntry userGalleryRef updateChildValues error: \(error).")
                }
            }
            values["userGalleryChildId"] = userGalleryChildId;
        }
        
        galleryRef.child(key).updateChildValues(values) { error, ref in
            if let error = error {
                print("createMediaEntry updateChildValues error: \(error).")
            }
        }
        
        // Update user location
        app.lobbyModel.updateCurrentUser()
    }
    
    // Add the mediaItem to another gallery named galleryKey
    //  homeRef will point to the current source gallery
    //
    func createMediaEntry(galleryKey: String, mediaItem: MediaModel) {
        var values: [AnyHashable : Any] = [:];
        values["homeRef"] = [app.settings.storeGalleryKey, mediaItem.id]
        let ngalleryRef = dbGalleryRef(key: galleryKey)
        
        values["mediaPath"] = mediaItem.mediaPath;
        values["storagePath"] = mediaItem.storagePath;
        // Copy full rez paths if present
        if !mediaItem.mediaPathFullRez.isEmpty {
            values["mediaPathFullRez"] = mediaItem.mediaPathFullRez;
        }
        if !mediaItem.storagePathFullRez.isEmpty {
            values["storagePathFullRez"] = mediaItem.storagePathFullRez;
        }
        // media copy reference is tagged with current user
        let user = app.lobbyModel.currentUser
        // let user = app.lobbyModel.user(uid: mediaItem.uid)
        createMediaEntry(info: mediaItem.info,
            values: values,
            galleryRef: ngalleryRef,
            galleryKey: galleryKey,
            user: user)
    }
    
    func dbGalleryRef(key: String) -> DatabaseReference? {
        Database.root.child(key)
    }
    
    func deleteAll() {
        guard let uid = self.app.lobbyModel.uid else {
            print("GalleryModel deleteAll NO uid")
            return
        }
        for item in gallery {
            if item.uid == uid {
                deleteMedia(mediaItem: item)
            }
            else {
                print("GalleryModel deleteAll skipping uid", item.uid)
            }
        }
    }
    
    func deleteMedia(mediaItem: MediaModel) {
        print("deleteMedia mediaItem \(mediaItem)")
        guard let galleryRef else { return }
        // Delete the media item database entry
        galleryRef.child(mediaItem.id).removeValue {error, ref in
            if let error = error {
                print("deleteMedia removeValue error: \(error)")
            }
        }
        // Don't delete media of copied references
        guard mediaItem.homeRef.isEmpty else {
            print("deleteMedia storage no delete homeRef: \(mediaItem.homeRef)")
            return
        }
        // Delete the media low rez file
        let storageRef = storage.reference(withPath: mediaItem.storagePath)
        storageRef.delete { error in
            if let error = error {
                print("deleteMedia storageRef error: \(error)")
            }
        }
        // Delete the full rez file
        if !mediaItem.storagePathFullRez.isEmpty {
            let storageRefFullRez = storage.reference(withPath: mediaItem.storagePathFullRez)
            storageRefFullRez.delete { error in
                if let error = error {
                    print("deleteMedia storageRefFullRez error: \(error)")
                }
            }
        }
        
        // remove userGalleryChildId if present
        let userGalleryChildId = mediaItem.userGalleryChildId
        if !userGalleryChildId.isEmpty {
            guard let user = app.lobbyModel.user(uid: mediaItem.uid) else {
                print("deleteMedia no user for mediaItem.uid", mediaItem.uid)
                return
            }
            guard let userGalleryRef = dbGalleryRef(key: user.userGalleryKey) else {
                print("deleteMedia no userGalleryRef userGalleryKey", user.userGalleryKey)
                return
            }
            userGalleryRef.child(userGalleryChildId).removeValue {error, ref in
                if let error = error {
                    print("deleteMedia userGalleryRef removeValue error: \(error)")
                }
            }
        }
    }
    
    // Store image from camera
    func getSaveImageData(photoInfo: PhotoInfo) -> Data? {
        print("getSaveImageData photoInfo \(photoInfo)")
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
            var info:[String:Any] = [
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
    
    func addGalleryAsset(phAsset: PHAsset?) {
        print("addGalleryAsset phAsset", phAsset ?? "-none-")
        guard let phAsset = phAsset else { return }
        print("addGalleryAsset phAsset.location", phAsset.location as Any)
        
        // var targetSize = PHImageManagerMaximumSize
        let fullRezSize:CGSize = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
        var targetSize = fullRezSize
        let dim = Int(app.settings.storePhotoSize) ?? 0;
        if dim != 0 {
            targetSize = CGSize(width: dim, height: dim)
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isSynchronous = true
        
        let manager = PHImageManager.default()
        
        requestImage(manager: manager,
                     fullRezSize: fullRezSize,
                     targetSize: targetSize,
                     options: options,
                     phAsset: phAsset,
                     attempts: 1)
    }
    
    func requestImage(manager: PHImageManager,
                      fullRezSize: CGSize,
                      targetSize: CGSize,
                      options: PHImageRequestOptions?,
                      phAsset: PHAsset,
                      attempts: Int) {
        print("requestImage targetSize", targetSize)
        manager.requestImage(for: phAsset, targetSize: targetSize,
                             contentMode:PHImageContentMode.default, options: options)
        { (image:UIImage?, info) in
            guard let image = image else {
                print("requestImage no image. attempts", attempts)
                print("requestImage no image. info", info ?? "-nil-")
                if attempts > 0 {
                    let options = PHImageRequestOptions()
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
                    options.isSynchronous = true
                    self.requestImage(manager: manager,
                                      fullRezSize: fullRezSize,
                                      targetSize: targetSize,
                                      options: options,
                                      phAsset: phAsset,
                                      attempts: attempts-1)
                }
                return
            }
            print("requestImage image.size", image.size)
            guard let imageData = image.jpegData(compressionQuality: 1) else {
                print("requestImage jpegData failed")
                return;
            }
            if self.app.settings.storeFullRez {
                let options = PHImageRequestOptions()
                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                options.isSynchronous = true
                self.requestFullRez(manager: manager,
                                         image: image,
                                         imageData: imageData,
                                         fullRezSize: fullRezSize,
                                         options: options,
                                         phAsset: phAsset,
                                         attempts: 1)
            }
            else {
                self.requestImageUpload(phAsset: phAsset,
                                        image: image,
                                        imageData: imageData,
                                        fullRezData: nil,
                                        fullRezSize: fullRezSize)
            }
        }
    }
    
    func requestFullRez(manager: PHImageManager,
                        image:UIImage,
                        imageData: Data,
                        fullRezSize: CGSize,
                        options: PHImageRequestOptions?,
                        phAsset: PHAsset,
                        attempts: Int) {
        print("requestFullRez fullRezSize", fullRezSize)
        manager.requestImage(for: phAsset, targetSize: fullRezSize,
                             contentMode:PHImageContentMode.default, options: options)
        { ( fullRezImage:UIImage?, info) in
            guard let fullRezImage = fullRezImage else {
                print("requestFullRez no image. attempts", attempts)
                print("requestFullRez no image. info", info ?? "-nil-")
                if attempts > 0 {
                    let options = PHImageRequestOptions()
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
                    // options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    // !!@ bug full rez not shown for some images from photo library
                    var fullRezSize = fullRezSize;
                    if fullRezSize.width > 1000 { fullRezSize = CGSize(width:1000, height: 1000)}
                    self.requestFullRez(manager: manager,
                                        image: image,
                                        imageData: imageData,
                                        fullRezSize: fullRezSize,
                                        options: options,
                                        phAsset: phAsset,
                                        attempts: attempts-1)
                }
                return
            }
            // in fastFormat we may get back much smaller image
            print("requestFullRez fullRezImage.size", fullRezImage.size)
            guard let fullRezData = fullRezImage.jpegData(compressionQuality: 1) else {
                print("requestFullRez jpegData failed")
                return;
            }
            self.requestImageUpload(phAsset: phAsset,
                                    image: image,
                                    imageData: imageData,
                                    fullRezData: fullRezData,
                                    fullRezSize: fullRezImage.size)
        }
    }

    func requestImageUpload(phAsset: PHAsset,
                          image:UIImage,
                          imageData: Data,
                          fullRezData: Data?,
                          fullRezSize: CGSize) {
        let sourceId = phAsset.localIdentifier;
        let sourceDate = phAsset.creationDate?.description ?? ""
        let imageSize = image.size;
        print("requestImageUpload imageSize", imageSize)
        var info:[String:Any] = [
            "sourceId": sourceId,
            "sourceDate": sourceDate,
            "imageWidth": imageSize.width,
            "imageHeight": imageSize.height,
        ]
        if let loc = phAsset.location {
            info["lat"] = loc.coordinate.latitude
            info["lon"] = loc.coordinate.longitude
        }
        if fullRezData != nil {
            info["fullRezWidth"] = fullRezSize.width
            info["fullRezHeight"] = fullRezSize.height
        }
        self.uploadImageData(imageData,
                             fullRezData: fullRezData,
                             info: info)
    }
}

