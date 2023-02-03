//
//  GalleryView.swift
//

// Display grid of images from database mo-gallery

import SwiftUI

struct GalleryView: View {
    @StateObject var lobbyModel: LobbyModel
    @StateObject var galleryModel: GalleryModel
    
    @State private var selection: String?
    @State private var showingAlert = false
    @State private var showingAddRandomAlert = false

    @EnvironmentObject var app: AppModel
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) var dismiss

    private static let itemSpacing = 0.0
    // private static let itemCornerRadius = 15.0
    private static let itemSize = CGSize(width: 96, height: 96)
    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2),
                      height: Self.itemSize.height * min(displayScale, 2))
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(galleryModel.countDisplayText())
                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                    ForEach(galleryModel.gallery) { item in
                        NavigationLink {
                            MediaDetailView(lobbyModel: lobbyModel,
                                            item: item,
                                            priorSelection: app.settings.storeGalleryKey)
                        } label: {
                            MediaThumbView(item: item, itemSize: Self.itemSize)
                        }
                        .buttonStyle(.borderless)
                        // .accessibilityLabel(asset.accessibilityLabel)
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .navigationTitle( app.galleyTitle )
            .navigationBarTitleDisplayMode(.inline)
            // .statusBar(hidden: false)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink {
                        GalleryPickerView(galleryKeys: app.settings.galleryKeys,
                                          selection: $selection)
                    } label: {
                        Label("Gallery List", systemImage: "rectangle.stack")
                    }
                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "trash")
                    }
                    Button(action: {
                        if app.settings.allowRandomAdd {
                            addRandomMedia()
                        }
                        else {
                            showingAddRandomAlert = true
                        }
                        // addRandomMedia()
                    }) {
                        Image(systemName: "plus.app.fill")
                    }
                }
            }
            .alert("Are you sure you want to ALL my photos in this gallery?", isPresented:$showingAlert) {
                Button("OK") {
                    showingAlert = false
                    galleryModel.deleteAll()
                    // dismiss();
                }
                Button("Cancel", role: .cancel) {
                    showingAlert = false
                }
            }
            .alert("Are you sure you want to ADD a random photo from your Photo Library?", isPresented:$showingAddRandomAlert) {
                Button("OK") {
                    showingAddRandomAlert = false
                    addRandomMedia()
                }
                Button("OK - dont ask again") {
                    showingAddRandomAlert = false
                    app.settings.allowRandomAdd = true
                    app.saveSettings()
                    addRandomMedia()
                }
                Button("Cancel", role: .cancel) {
                    showingAddRandomAlert = false
                }
            }
            .onAppear {
                selection = app.settings.storeGalleryKey
            }
        }
    }
    
    private func addRandomMedia() {
        Task {
            guard let asset = app.photosModel.nextRandomAsset() else {
                print("GalleryView no assets")
                return
            }
            galleryModel.addGalleryAsset(phAsset: asset.phAsset)
        }
    }
}

struct MediaThumbView: View {
    var item: MediaModel;
    var itemSize: CGSize
    
    var body: some View {
        AsyncImage(url: URL(string: item.mediaPath))
        { image in
            image.resizable()
                .scaledToFill()
//                .scaledToFit()

        } placeholder: {
            ProgressView()
        }
        .aspectRatio(contentMode: .fill)
//        .aspectRatio(contentMode: .fit)
        .frame(width: itemSize.width, height: itemSize.height)
        .clipped()
    }
}

//struct MediaCollectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        GalleryView()
//    }
//}


