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
        }
        .onDisappear {
            print("AppSettingView onDisappear")
            app.updateSettings();
        }
        VStack {
            
// https://www.hackingwithswift.com/quick-start/swiftui/how-to-open-web-links-in-safari
//            Link("Visit Apple", destination: URL(string: "https://www.apple.com")!)
//                .font(.title)
//                .foregroundColor(.red)

            Link("p5js gallery previews",
                 destination:
                    URL(string: "https://mobilelabclass-itp.github.io/98-MoGallery-p5js")!
            )
            .padding(2)
            Link("git repo",
                 destination:
                    URL(string: "https://github.com/mobilelabclass-itp/98-MoGallery")!
            )
            .padding(2)
//            Button(action: {
//                openURL(URL(string: "https://mobilelabclass-itp.github.io/98-MoGallery-p5js")!)
//            }) {
//                Text("p5js gallery previews")
//            }

        }
    }
}

struct AppSettingView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingView( )
            .environmentObject(AppModel())
    }
}
