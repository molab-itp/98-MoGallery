//
//  MediaEditView.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

// Present an image from the gallary from Firebase storage
//  + button to delete

import SwiftUI

struct MediaDetailView: View {
    @StateObject var lobbyModel: LobbyModel
    var item: MediaModel;
    var priorSelection: String
    
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAlert = false
    @State private var thumbImage:Image?
    @State private var selection: String?
    @State private var isSharing = false
    @State private var imageThumb: UIImage?

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: item.mediaPathDetail))
            { image in
                image
                    .resizable()
                    .scaledToFit()
                
            } placeholder: {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.secondary)
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // navigationBarLeading
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    isSharing = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }.sheet(isPresented: $isSharing) {
                    ShareSheet(
                        activityItems: activityItems(), // ["Place Holder" as Any],
                        excludedActivityTypes: [])
                }
                Button {
                    showingAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                // MediaDetailView EditButtons Add Photo
                NavigationLink {
                    GalleryPickerView(galleryKeys: app.galleryKeysExcludingCurrent,
                                      selection: $selection,
                                      mediaItem: item)
                } label: {
                    Label("Add Photo", systemImage: "plus.app.fill")
                }
            }
        }
        .overlay(alignment: .top) {
            VStack {
                Text(item.authorEmail)
                Group {
                    if let sourceDate = item.sourceDate {
                        Text(sourceDate.prefix(19))
                    }
                    let homeRefLabel = app.homeRefLabel(item: item)
                    Text("\(item.width) x \(item.height) \(homeRefLabel)" )
                    if let locationDescription = item.locationDescription {
                        Button {
                            app.selectedTab = .map
                        } label: {
                            Text(locationDescription)
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding(EdgeInsets(top: 5, leading: 30, bottom: 5, trailing: 30))
            .background(Color.secondary.colorInvert())
        }
//        .overlay(alignment: .bottom) {
//            EditButtons(showingAlert: $showingAlert, selection: $selection, item: item)
//                .offset(x: 0, y: -50)
//        }
        .alert("Are you sure you want to delete this photo?", isPresented:$showingAlert) {
            Button("OK") {
                showingAlert = false
                dismiss()
                app.galleryModel.deleteMedia(mediaItem: item)
            }
            Button("Cancel", role: .cancel) {
                showingAlert = false
            }
        }
        .onChange(of: selection) { newState in
            print("MediaDetailView onChange priorSelection", priorSelection, "newState", newState ?? "-nil-")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        }
        .onAppear {
            print("MediaDetailView onAppear")
            lobbyModel.locsForUsers(firstLoc: item.loc)
        }
        .task {
            imageThumb = await imageFor(string: item.mediaPath)
            print("imageStash", imageThumb ?? "-nil-")
        }
    }
    
    func imageFor(string str: String) async -> UIImage? {
        guard let url = URL(string: str) else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data:data)
    }

    func activityItems() -> [Any] {
        var items: [String] = []
        items.append("authorEmail: "+item.authorEmail)
        items.append("createdDate: "+item.createdDate)
        items.append("uid: "+item.uid)
        items.append("mediaPath: "+item.mediaPath)
        if !item.mediaPathFullRez.isEmpty {
            items.append("mediaPathFullRez: "+item.mediaPathFullRez)
        }
        if let fullRezHeight = item.info["fullRezHeight"] as? Int {
            items.append("info.fullRezHeight: "+String(fullRezHeight))
        }
        if let fullRezWidth = item.info["fullRezWidth"] as? Int {
            items.append("info.fullRezWidth: "+String(fullRezWidth))
        }
        if let imageWidth = item.info["imageWidth"] as? Int {
            items.append("info.imageWidth: "+String(imageWidth))
        }
        if let imageHeight = item.info["imageHeight"] as? Int {
            items.append("info.imageHeight: "+String(imageHeight))
        }
        if let lat = item.info["lat"] as? Double {
            items.append("info.lat: "+String(lat))
        }
        if let lon = item.info["lon"] as? Double {
            items.append("info.lon: "+String(lon))
        }
        if let sourceDate = item.info["sourceDate"] as? String {
            items.append("info.sourceDate: "+sourceDate)
        }
        if let sourceId = item.info["sourceId"] as? String {
            items.append("info.sourceId: "+sourceId)
        }
        let str = items.joined(separator: "\n")
        return [self.imageThumb as Any, str];
    }
}

//    struct EditButtons: View {
//        @Binding var showingAlert: Bool;
//        @Binding var selection: String?
//        var item: MediaModel
//
//        @EnvironmentObject var app: AppModel
//
//        var body: some View {
//            HStack(spacing: 60) {
//                Button {
//                    showingAlert = true
//                } label: {
//                    Label("Delete", systemImage: "trash")
//                        .font(.system(size: 24))
//                }
//                // MediaDetailView EditButtons Add Photo
//                NavigationLink {
//                    GalleryPickerView(galleryKeys: app.galleryKeysExcludingCurrent,
//                                      selection: $selection,
//                                      mediaItem: item)
//                } label: {
//                    Label("Add Photo", systemImage: "plus.app.fill")
//                        .font(.system(size: 24))
//                }
//            }
//            .buttonStyle(.plain)
//            .labelStyle(.iconOnly)
//            .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
//            .background(Color.secondary.colorInvert())
//            .cornerRadius(15)
//        }
//    }

//                        NavigationLink {
//                            MapView(locs: lobbyModel.mapRegion.locs)
//                        } label: {
//                            Text(locationDescription)
//                        }


// https://www.hackingwithswift.com/books/ios-swiftui/sending-and-receiving-codable-data-with-urlsession-and-swiftui

