//
//  LoginCheckView.swift
//  MoGallery
//
//  Created by jht2 on 12/23/22.
//

import SwiftUI

struct LoginCheckView: View {
    
    @EnvironmentObject var lobbyModel: LobbyModel
    @EnvironmentObject var app: AppModel

    var body: some View {
        GeometryReader { geometry in
            switch lobbyModel.state {
            case .signedIn, .signedInFresh:
                MainView()
                    .onAppear {
                        app.geometrySize = geometry.size
                    }
            case .signedOut:
                LoginView()
            }
        }
    }
}

#Preview {
    LoginCheckView()
        .environmentObject(AppModel.main)
        .environmentObject(CameraModel.main)
        .environmentObject(LobbyModel.main)
        .environmentObject(GalleryModel.main)
        .environmentObject(PhotosModel.main)
        .environmentObject(MetaModel.main)
}


//struct LoginCheckView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginCheckView()
//    }
//}
