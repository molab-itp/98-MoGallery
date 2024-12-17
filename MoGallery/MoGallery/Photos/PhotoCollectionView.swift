/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI
//import os.log
import PhotosUI

// Display a grid of photos from album
// photos link to details which allows for set favorite and delete

struct PhotoCollectionView: View {
    
    @EnvironmentObject var lobbyModel: LobbyModel
    @EnvironmentObject var photosModel: PhotosModel
    @EnvironmentObject var cameraModel: CameraModel
    @EnvironmentObject var app: AppModel

    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) var dismiss

    @State private var selection: String?
    @State var showLimitedPicker: Bool = true
    
    @State var showDownloading: Bool = false
    @State var downloadingIndex = 0
    @State var downloadingCount = 0
    @State var downloadingBase = 0
    @State var showDownloadingAlert: Bool = false
    @State var downloadingActive: Bool = false

    private static let itemSpacing = 2.0
    private static let itemSize = CGSize(width: 94, height: 94)
    
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2),
                      height: Self.itemSize.height * min(displayScale, 2))
    }
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    
    var body: some View {
        let photoCount = photosModel.photoCollection!.photoAssets.count;
        NavigationStack {
            ScrollView {
                Text("\(photoCount) items")
                if showDownloading {
                    VStack {
                        HStack {
                            Text("downloading \(downloadingIndex) of \(downloadingCount)")
                        }
                        HStack {
                            Button(action: {
                                downloadingActive = !downloadingActive
                                if downloadingActive {
                                    startDownloading()
                                }
                            }) {
                                Text(downloadingActive ? "Pause" : "Resume")
                            }
                            Button(action: {
                                showDownloading = false
                                downloadingActive = false
                                downloadingBase = 0
                            }) {
                                Label("Cancel", systemImage: "x.circle")
                            }
                        }
                    }
                }
                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                    ForEach(photosModel.photoCollection!.photoAssets) { asset in
                        NavigationLink {
                            PhotoDetailView(asset: asset,
                                            cache: photosModel.photoCollection!.cache)
                        } label: {
                            photoItemView(asset: asset, cache: photosModel.photoCollection!.cache)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(asset.accessibilityLabel)
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            // .navigationTitle( photosModel.photoCollection!.albumName ?? "Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            //  .statusBar(hidden: false)
            .toolbar {
                // ToolbarItemGroup(placement: .navigationBarTrailing) {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        app.toGalleryTab()
                    }) {
                        Label("Gallery", systemImage: "rectangle.stack")
                    }
                    NavigationLink {
                        if app.photoLibLimited {
                            LimitedPicker(isPresented: $showLimitedPicker);
                        }
                        else {
                            AlbumPickerView(selection: $selection)
                        }
                    } label: {
                        Label(photosModel.photoCollectionTitle , systemImage: "photo.on.rectangle")
                            .labelStyle(.titleAndIcon)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDownloadingAlert = true
                    }) {
                        Label("Download All", systemImage: "plus.diamond.fill")
                    }
                }
            }
            .alert(
                "Are you sure you want to ADD all \(photoCount) photos from this album?",
                isPresented:$showDownloadingAlert)
            {
                Button("OK") {
                    showDownloadingAlert = false
                    downloadingBase = 0
                    startDownloading()
                }
                Button("Cancel", role: .cancel) {
                    showDownloadingAlert = false
                }
            }
            .onAppear {
                cameraModel.isPreviewPaused = true
            }
            .onDisappear {
                cameraModel.isPreviewPaused = false
                showLimitedPicker = true
            }
        }
    }
        
    func startDownloading() {
        downloadingActive = true;
        showDownloading = true;
        Task {
            let photos = photosModel.photoCollection!.photoAssets
            downloadingCount = photos.count;
            print("Download count", downloadingCount)
            let startIndex = downloadingBase;
            for index in startIndex..<photos.count {
                downloadingIndex = index+1;
                print("Download index", downloadingIndex, " of", downloadingCount);
                
                // Add temporary media item for progress feedback
                app.galleryModel.addTempMedia()
                
                let asset = photos[photos.count - 1 - index]
                await app.galleryModel.addGalleryAsset(phAsset: asset.phAsset);
                downloadingBase = index + 1;
                if !showDownloading || !downloadingActive { break; }
            }
            await MainActor.run {
                if downloadingActive { showDownloading = false; }
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    app.toGalleryTab()
                }
            }
        }
    }
    private func photoItemView(asset: PhotoAsset, cache: CachedImageManager ) -> some View {
        PhotoItemView(asset: asset, cache: cache, imageSize: imageSize)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height)
            .clipped()
        // .cornerRadius(Self.itemCornerRadius)
            .overlay(alignment: .bottomLeading) {
                HStack {
                    if asset.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 1)
                            .font(.callout)
                            .offset(x: 4, y: -4)
                    }
                    if asset.isVideoMediaType {
                        Image(systemName: "video.fill")
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 1)
                            .font(.callout)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .onAppear {
                Task {
                    await cache.startCaching(for: [asset], targetSize: imageSize)
                }
            }
            .onDisappear {
                Task {
                    await cache.stopCaching(for: [asset], targetSize: imageSize)
                }
            }
    }
}

// https://stackoverflow.com/questions/63870238/how-to-call-phphotolibrary-presentlimitedlibrarypicker-from-swiftui
// >> LimitedPicker nav view stays up after selection

struct LimitedPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: uiViewController)
            DispatchQueue.main.async {
                isPresented = false
                dismiss();
            }
        }
    }
}

struct AlbumPickerView: View {
    @Binding var selection: String?

    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
// HStack {
//     Button(action: dismissPicker) {
//         Image(systemName: "chevron.left")
//     }
//     Spacer()
//     let str = selection ?? ""
//     Text("Selected album: \(str)")
//     Spacer()
// }
// .padding(20)
            VStack {
                List(app.photosModel.albumNames, id: \.self,
                     selection: $selection)
                { item in
                    Text(item)
                }
            }
            .onChange(of: selection) { newState in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismissPicker()
                }
            }
        }
        // .navigationTitle( photosModel.photoCollection!.albumName ?? "Photo Library")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Select Album")
        // Label("Select Album", systemImage: "photo.on.rectangle")
        //  .labelStyle(.titleAndIcon)

    }
    
    private func dismissPicker() {
        // showPicker = false
        xprint("selection", selection ?? "-none-")
        if let selection {
            app.settings.photoAlbum = selection
            app.lobbyModel.albumName = selection
            app.saveSettings()
            app.photosModel.refresh()
        }
        dismiss();
    }

}

// !!@ Fails for more than 30 albumNames
//                    Picker("Please choose a album", selection: $app.settings.photoAlbum) {
//                        ForEach(app.photosModel.albumNames, id: \.self) {
//                            Text($0)
//                        }
//                    }

// private static let itemSpacing = 12.0
// private static let itemCornerRadius = 15.0
