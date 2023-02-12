//
//  UserDetailView.swift
//  MoGallery
//
//  Created by jht2 on 2023-02-09
//

import SwiftUI

struct UserDetailView: View {
    @StateObject var lobbyModel: LobbyModel
    @StateObject var user: UserModel
        
    @EnvironmentObject var app: AppModel

    var body: some View {
        VStack() {
        // VStack(alignment: .leading) {
            AsyncImage(url: URL(string: user.profileImg))
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80, alignment: .center)
            Text(user.name )
                .font(.headline)
            Text(user.email )
                .font(.subheadline)
            Text(user.id )
                .font(.subheadline)
//            if let locationDescription = user.locationDescription {
//                Text(locationDescription)
//            }
            if let locationDescription = user.locationDescription {
                Button {
                    app.selectedTab = .map
                } label: {
                    Text(locationDescription)
                }
            }
        }
        Form {
            Section {
                Text("Status")
                TextField("", text: $user.status, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .onAppear {
            print("UserDetailView onAppear")
            lobbyModel.locsForUsers(firstLoc: user.loc)
        }
        .onDisappear {
            print("UserDetailView onDisappear")
            lobbyModel.updateUser(user: user);
            // app.updateSettings();
        }
    }
}

//struct AppSettingView_Previews: PreviewProvider {
//    static var previews: some View {
//        AppSettingView( )
//            .environmentObject(AppModel())
//    }
//}
