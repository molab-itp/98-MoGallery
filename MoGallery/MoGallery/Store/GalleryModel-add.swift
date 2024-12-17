//
//  GalleryModel-add.swift
//  MoGallery
//
//  Created by jht2 on 3/11/23.
//

import FirebaseDatabase
import FirebaseStorage
import Photos
import UIKit
import SwiftUI

extension GalleryModel {
    
    func addGalleryAsset(phAsset: PHAsset?) async  {
        await withCheckedContinuation { continuation in
            addGalleryAsset (phAsset: phAsset) {
                continuation.resume()
            }
        }
    }
    
    func addGalleryAsset(
        phAsset: PHAsset?,
        done: @Sendable @escaping () -> Void)
    {
        xprint("addGalleryAsset phAsset", phAsset ?? "-none-")
        guard let phAsset = phAsset else { return }
        xprint("addGalleryAsset phAsset.location", phAsset.location as Any)
        xprint("addGalleryAsset phAsset.mediaType", phAsset.mediaType.rawValue)
        
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
        options.isNetworkAccessAllowed = true
        
        let manager = PHImageManager.default()
        
        requestImage(
            manager: manager,
            fullRezSize: fullRezSize,
            targetSize: targetSize,
            options: options,
            phAsset: phAsset,
            attempts: 1,
            done: done)
    }
    
    func requestImage(
        manager: PHImageManager,
        fullRezSize: CGSize,
        targetSize: CGSize,
        options: PHImageRequestOptions?,
        phAsset: PHAsset,
        attempts: Int,
        done: @Sendable @escaping () -> Void)
    {
        xprint("requestImage targetSize", targetSize)
        manager.requestImage(for: phAsset, targetSize: targetSize,
                             contentMode:PHImageContentMode.default, options: options)
        { (image:UIImage?, info) in
            guard let image = image else {
                xprint("requestImage no image. attempts", attempts)
                xprint("requestImage no image. info", info ?? "-nil-")
                if attempts > 0 {
                    let options = PHImageRequestOptions()
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    self.requestImage(
                        manager: manager,
                        fullRezSize: fullRezSize,
                        targetSize: targetSize,
                        options: options,
                        phAsset: phAsset,
                        attempts: attempts-1,
                        done: done)
                }
                return
            }
            xprint("requestImage image.size", image.size)
            guard let imageData = image.jpegData(compressionQuality: 1) else {
                xprint("requestImage jpegData failed")
                return;
            }
            if self.app.settings.storeFullRez {
                let options = PHImageRequestOptions()
                options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                self.requestFullRez(
                    manager: manager,
                    image: image,
                    imageData: imageData,
                    fullRezSize: fullRezSize,
                    options: options,
                    phAsset: phAsset,
                    attempts: 1,
                    done: done)
            }
            else {
                self.requestImageUpload(phAsset: phAsset,
                                        image: image,
                                        imageData: imageData,
                                        fullRezData: nil,
                                        fullRezSize: fullRezSize,
                                        done: done)
            }
        }
    }
    
    func requestFullRez(
        manager: PHImageManager,
        image:UIImage,
        imageData: Data,
        fullRezSize: CGSize,
        options: PHImageRequestOptions?,
        phAsset: PHAsset,
        attempts: Int,
        done: @Sendable @escaping () -> Void)
    {
        xprint("requestFullRez fullRezSize", fullRezSize)
        manager.requestImage(for: phAsset, targetSize: fullRezSize,
                             contentMode:PHImageContentMode.default, options: options)
        { ( fullRezImage:UIImage?, info) in
            guard let fullRezImage = fullRezImage else {
                xprint("requestFullRez no image. attempts", attempts)
                xprint("requestFullRez no image. info", info ?? "-nil-")
                if attempts > 0 {
                    let options = PHImageRequestOptions()
                    options.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
                    options.isNetworkAccessAllowed = true
                    // options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    // !!@ bug full rez not shown for some images from photo library
                    var fullRezSize = fullRezSize;
                    if fullRezSize.width > 1000 { fullRezSize = CGSize(width:1000, height: 1000)}
                    self.requestFullRez(
                        manager: manager,
                        image: image,
                        imageData: imageData,
                        fullRezSize: fullRezSize,
                        options: options,
                        phAsset: phAsset,
                        attempts: attempts-1,
                        done: done)
                }
                return
            }
            // in fastFormat we may get back much smaller image
            xprint("requestFullRez fullRezImage.size", fullRezImage.size)
            guard let fullRezData = fullRezImage.jpegData(compressionQuality: 1) else {
                xprint("requestFullRez jpegData failed")
                return;
            }
            self.requestImageUpload(
                phAsset: phAsset,
                image: image,
                imageData: imageData,
                fullRezData: fullRezData,
                fullRezSize: fullRezImage.size,
                done: done)
        }
    }
    
    func requestImageUpload(
        phAsset: PHAsset,
        image:UIImage,
        imageData: Data,
        fullRezData: Data?,
        fullRezSize: CGSize,
        done: @Sendable @escaping () -> Void)
    {
        let sourceId = phAsset.localIdentifier;
        let sourceDate = phAsset.creationDate?.description ?? ""
        let imageSize = image.size;
        xprint("requestImageUpload imageSize", imageSize)
        var info:[String: Any] = [
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
        var mediaType = "";
        switch phAsset.mediaType {
        case .image:
            mediaType = "image"
        case .video:
            mediaType = "video"
        case .audio:
            mediaType = "audio"
        case .unknown:
            mediaType = "unknown"
        @unknown default:
            mediaType = "unknown"
        }
        info["mediaType"] = mediaType
        xprint("requestImageUpload mediaType", mediaType)
        if phAsset.isFavorite {
            info["isFavorite"] = true
        }
        if phAsset.duration > 0 {
            info["duration"] = phAsset.duration
        }
        self.uploadImageData(
            imageData,
            fullRezData: fullRezData,
            info: info,
            done: done)
        // !!@ Disabled
        // if phAsset.mediaType == .video {
        // export(phAsset: phAsset)
        // }
    }
    
} // extension GalleryModel

func export(phAsset: PHAsset) {
    xprint("export phAsset", phAsset)
    
    let manager = PHImageManager.default()
    
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    
    _ = manager.requestAVAsset(
        forVideo: phAsset,
        options: options) { avasset, audioMix, info in
            xprint("export phAsset avasset", avasset ?? "-nil-")
            xprint("export phAsset info", info ?? "-nil-")
            let dirUrl = FileManager.documentsDirectory.appending(path: "videos", directoryHint: .isDirectory)
            let filem = FileManager.default
            do {
                try filem.createDirectory(at: dirUrl, withIntermediateDirectories: true)
            }
            catch {
                xprint("export createDirectory error", error)
            }
            let outputUrl = dirUrl.appendingPathComponent("export-1.mp4")
            do {
                try filem.removeItem(at: outputUrl)
            }
            catch {
                xprint("export removeItem error", error)
            }
            if let avasset {
                Task {
                    await export(video: avasset, atURL: outputUrl)
                }
            }
        }
}

// AVAssetExportPresetHighestQuality

func export(
    video: AVAsset,
    atURL outputURL: URL,
    withPreset preset: String = AVAssetExportPresetLowQuality,
    toFileType outputFileType: AVFileType = .mp4
) async
{
    // Check the compatibility of the preset to export the video to the output file type.
    guard await AVAssetExportSession.compatibility(ofExportPreset: preset,
                                                   with: video,
                                                   outputFileType: outputFileType) else {
        xprint("The preset can't export the video to the output file type.")
        return
    }
    
    // Create and configure the export session.
    guard let exportSession = AVAssetExportSession(asset: video,
                                                   presetName: preset) else {
        xprint("Failed to create export session.")
        return
    }
    exportSession.outputFileType = outputFileType
    exportSession.outputURL = outputURL
    
    // Convert the video to the output file type and export it to the output URL.
    await exportSession.export()
    
    xprint("export(video outputURL", outputURL)
}

// https://developer.apple.com/documentation/avfoundation/avassetexportsession/export_presets
// https://developer.apple.com/documentation/photokit/phimagemanager/1616935-requestavasset

