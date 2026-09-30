//
//  LoginCheckView.swift
//  MoGallery
//
//  Created by jht2 on 12/23/22.
//

import SwiftUI

struct LoginCheckView: View {
    
    @Environment(LobbyModel.self) var lobbyModel
    @Environment(AppModel.self) var app

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
        .environment(AppModel.main)
        .environment(CameraModel.main)
        .environment(LobbyModel.main)
        .environment(GalleryModel.main)
        .environment(PhotosModel.main)
        .environment(MetaModel.main)
}


//struct LoginCheckView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginCheckView()
//    }
//}
