//
// LobbyView
// display list of users that have logged in

import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-load-a-remote-image-from-a-url
// Use AsyncImage in place of NetworkImage to avoid async warning

struct LobbyView: View {

    @EnvironmentObject var lobbyModel: LobbyModel
    @EnvironmentObject var app: AppModel
    
    var body: some View {
        NavigationStack {
            VStack {
                userListView()
            }
        }
        .onAppear {
            print("LobbyView onAppear currentUser", lobbyModel.currentUser ?? "-none-")
        }
        .navigationTitle("Info MoGallery v\(app.verNum)")
        .navigationBarTitleDisplayMode(.inline)

    }
        
    private func userListView() -> some View {
        List {
            Text("\(lobbyModel.users.count) users")
            ForEach(lobbyModel.users) { user in
                NavigationLink {
                    UserDetailView(user: user )
                } label: {
                    userRowView(user: user)
                }
            }
        }
    }
    
    private func userRowView(user: UserModel) -> some View {
        HStack {
            AsyncImage(url: URL(string: user.profileImg))
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80, alignment: .center)
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                HStack {
                    Text(user.dateIn.getElapsedInterval())
                        .font(.subheadline)
                    Spacer()
                    Text(user.activeCountLabel ?? "")
                        .font(.subheadline)
                }
                Text(user.caption)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}
