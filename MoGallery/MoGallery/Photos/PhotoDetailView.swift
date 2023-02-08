/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI
import Photos
import MapKit

// view single 1024x1024 image
// async load using CachedImageManager.requestImage


struct PhotoDetailView: View {
    @StateObject var lobbyModel: LobbyModel
    var asset: PhotoAsset
    var cache: CachedImageManager?
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var app: AppModel

    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    
    private let imageSize = CGSize(width: 1024, height: 1024)

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(asset.accessibilityLabel)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.secondary)
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if let phAsset = asset.phAsset {
                VStack {
                    Text( (phAsset.creationDate?.description ?? "").prefix(19) )
                    Text( "\(phAsset.pixelWidth) x \(phAsset.pixelHeight)" )
                    if let locationDescription = phAsset.locationDescription {
                        Button {
                            app.selectedTab = .map
                        } label: {
                            Text(locationDescription)
                        }
//                        NavigationLink {
//                            MapView(locs: lobbyModel.mapRegion.locs)
//                        } label: {
//                            Text(locationDescription)
//                        }
                    }
                }
                .padding(EdgeInsets(top: 5, leading: 30, bottom: 5, trailing: 30))
                .background(Color.secondary.colorInvert())
            }
        }
        .overlay(alignment: .bottom) {
            buttonsView()
                .offset(x: 0, y: -50)
        }
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
        .onAppear {
            print("PhotoDetailView onAppear")
            if let phAsset = asset.phAsset {
                lobbyModel.locsForUsers(firstLoc: phAsset.loc)
            }
        }
    }
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            
            Button {
                Task {
                    app.galleryModel.addGalleryAsset(phAsset: asset.phAsset)
                    await MainActor.run {
                        // navigation with app.path
                        // Show gallery after media added
                        // app.path.removeLast()
                        // app.path.append("gallery")
                        dismiss()
                        app.toGalleryTab()
                    }
                }
            } label: {
                Label("Add Photo", systemImage: "plus.app.fill")
                    .font(.system(size: 24))
            }
            
            Button {
                Task {
                    await asset.setIsFavorite(!asset.isFavorite)
                }
            } label: {
                Label("Favorite", systemImage: asset.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 24))
            }

            Button {
                Task {
                    await asset.delete()
                    await MainActor.run {
                        dismiss()
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 24))
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color.secondary.colorInvert())
        .cornerRadius(15)
    }
}

extension PHAsset {
    var locationDescription: String? {
        guard let lat = self.location?.coordinate.latitude else { return nil }
        guard let lon = self.location?.coordinate.longitude else { return nil }
        return "\( String(format: "%.6f", lat) ) \( String(format: "%.6f", lon) )"
    }
    var loc: Location? {
        guard let lat = self.location?.coordinate.latitude as? Double else { return nil }
        guard let lon = self.location?.coordinate.longitude as? Double else { return nil }
        return Location(id: "photo", latitude: lat, longitude: lon, label: "photo")
    }
}
