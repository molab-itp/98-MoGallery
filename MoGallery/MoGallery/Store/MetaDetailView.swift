//
//  UserDetailView.swift
//  MoGallery
//
//  Created by jht2 on 2023-02-09
//

import SwiftUI

struct MetaDetailView: View {
    @StateObject var metaModel: MetaModel
    @StateObject var metaEntry: MetaEntry
        
    @EnvironmentObject var app: AppModel

    var body: some View {
        VStack() {
            Text(metaEntry.galleryName )
                .font(.headline)
        }
        Form {
            Section {
                Text("Status")
                TextField("", text: $metaEntry.status, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .onDisappear {
            print("MetaDetailView onDisappear")
            metaModel.update(metaEntry: metaEntry);
        }
    }
}

//struct AppSettingView_Previews: PreviewProvider {
//    static var previews: some View {
//        AppSettingView( )
//            .environmentObject(AppModel())
//    }
//}
