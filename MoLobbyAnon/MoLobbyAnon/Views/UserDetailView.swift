//
//  UserDetailView.swift
//  MoGallery
//
//  Created by jht2 on 2023-02-09
//

import SwiftUI

struct UserDetailView: View {
    
    @ObservedObject var user: UserModel
    
    @EnvironmentObject var lobbyModel: LobbyModel
    @EnvironmentObject var app: AppModel
    
    var body: some View {
        VStack() {
            AsyncImage(url: URL(string: user.profileImg))
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80, alignment: .center)
                .padding(2)
            Text(user.id )
                .font(.headline)
            Text(user.name )
                .font(.headline)
            Text(user.email )
                .font(.headline)
            if let init_lapse = user.stats["init_lapse"] as? Double {
                Text("init_lapse: " + String(init_lapse))
            }
            if let load_lapse = user.stats["load_lapse"] as? Double {
                Text("load_lapse: " + String(load_lapse))
            }
            Form {
                Section {
                    Text("Caption")
                    TextField("", text: $user.caption, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .onAppear {
            print("UserDetailView onAppear")
        }
        .onDisappear {
            print("UserDetailView onDisappear")
            lobbyModel.updateUser(user: user);
        }
    }
}

//struct AppSettingView_Previews: PreviewProvider {
//    static var previews: some View {
//        AppSettingView( )
//            .environmentObject(AppModel())
//    }
//}
