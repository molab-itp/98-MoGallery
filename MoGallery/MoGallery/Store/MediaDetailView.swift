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
        .overlay(alignment: .top) {
            VStack {
                Text(item.authorEmail)
                Group {
                    if let sourceDate = item.sourceDate {
                        Text(sourceDate.prefix(19))
                    }
                    Text("\(item.width) x \(item.height) \(item.homeRefLabel)" )
                    if let locationDescription = item.locationDescription {
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
                .font(.subheadline)
            }
            .padding(EdgeInsets(top: 5, leading: 30, bottom: 5, trailing: 30))
            .background(Color.secondary.colorInvert())
        }
        .overlay(alignment: .bottom) {
            EditButtons(showingAlert: $showingAlert, selection: $selection, item: item)
                .offset(x: 0, y: -50)
        }
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
    }
}


struct EditButtons: View {
    @Binding var showingAlert: Bool;
    @Binding var selection: String?
    var item: MediaModel
    
    @EnvironmentObject var app: AppModel

    var body: some View {
        HStack(spacing: 60) {
            Button {
                showingAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 24))
            }
            // MediaDetailView EditButtons Add Photo
            NavigationLink {
                GalleryPickerView(galleryKeys: app.galleryKeysExcludingCurrent,
                                  selection: $selection,
                                  mediaItem: item)
            } label: {
                Label("Add Photo", systemImage: "plus.app.fill")
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
