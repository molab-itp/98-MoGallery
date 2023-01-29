//
//  LoginCheckView.swift
//  MoGallery
//
//  Created by jht2 on 12/23/22.
//

import SwiftUI

struct LoginCheckView: View {
    
    @StateObject var lobbyModel: LobbyModel

    @EnvironmentObject var app: AppModel

    var body: some View {
        switch lobbyModel.state {
        case .signedIn, .signedInFresh:
            MainView(photosModel: app.photosModel,
                     lobbyModel: app.lobbyModel,
                     cameraModel: app.cameraModel)
        case .signedOut:
            LoginView(lobbyModel: lobbyModel)
        }
    }
}

//struct LoginCheckView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginCheckView()
//    }
//}
