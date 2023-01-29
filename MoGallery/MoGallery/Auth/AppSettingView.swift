//
//  AppSettingView.swift
//  MoGallery
//
//  Created by jht2 on 12/22/22.
//

import SwiftUI

// !!@ can't get label to work for TextField
// maybe macOS issue
// https://developer.apple.com/documentation/swiftui/textfield
// !!@ fails to give label on iOS
//            TextField(text: $app.applePhotoAlbumName, prompt: Text("Required")) {
//                Text("Username")
//            }

struct AppSettingView: View {
    
    @EnvironmentObject var app: AppModel
    @Environment(\.openURL) var openURL

    var body: some View {
        Form {
            Section {
                Text("Firebase Storage")
                Toggle("Store Camera Capture", isOn: $app.settings.storeAddEnabled)
                Toggle("Store FullRez", isOn: $app.settings.storeFullRez)
                HStack {
                    Text("Photo Size")
                        // .bold()
                        .frame(width:160)
                    TextField("", text: $app.settings.storePhotoSize)
                }
                HStack {
                    Text("Gallery Key")
                        .frame(width:160)
                    TextField("", text: $app.settings.storeGalleryKey)
                }
                HStack {
                    Text("Lobby Key")
                        .frame(width:160)
                    TextField("", text: $app.settings.storeLobbyKey)
                }
            }
            Section {
                Text("Apple Photos")
                Toggle("Photos Camera Capture", isOn: $app.settings.photoAddEnabled)
                HStack {
                    Text("Photo Size")
                        // .bold()
                        .frame(width:160)
                    TextField("", text: $app.settings.photoSize)
                }
                HStack {
                    Text("Album Name")
                        .frame(width:160)
                    TextField("", text: $app.settings.photoAlbum)
                }
            }
            Section {
                Link("MoGallery git repo",
                     destination:
                        URL(string: "https://github.com/mobilelabclass-itp/98-MoGallery")! )
                .padding(8)
            }
        }
        .onDisappear {
            print("AppSettingView onDisappear")
            app.updateSettings();
        }
    }
}

struct AppSettingView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingView( )
            .environmentObject(AppModel())
    }
}
