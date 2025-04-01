//
//  AlbumPickerView.swift
//  MoGallery
//
//  Created by jht2 on 12/18/24.
//

import SwiftUI

struct AlbumPickerView: View {
    @State var selection: String?
    var albumNames: [String]
    
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
//        let _ = Self._printChanges()
        ScrollViewReader { proxy in
            VStack {
//                Button("Jump 0") {
//                    print("AlbumPickerView jump 0")
//                    proxy.scrollTo(0)
//                }
//                Button("Jump 50") {
//                    print("AlbumPickerView jump 50")
//                    proxy.scrollTo(50)
//                }
                List(albumNames, id: \.self, selection: $selection)
                { item in
                    Text(item)
                }
            }
            .onChange(of: selection) { newState in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismissPicker()
                }
            }
            .onAppear() {
                print("AlbumPickerView onAppear", selection as Any)
                if let selection {
                    proxy.scrollTo(selection)
//                    proxy.scrollTo(selection, anchor: .top)
                }
                else {
                    print("AlbumPickerView no selection")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Select Album")
    }
    
    private func dismissPicker() {
        // showPicker = false
        xprint("selection", selection ?? "-none-")
//        xprint("selectionString", selectionString)
//        selection = selectionString
        if let selection {
            app.settings.photoAlbum = selection
            app.lobbyModel.albumName = selection
            app.saveSettings()
            app.photosModel.refresh()
        }
        dismiss();
    }
    
}

// !!@ selection does not work
//
struct AlbumPickerView_AlbumItem: View {
    @State var selection: AlbumItem?
    var albumItems: [AlbumItem]
    
    //    @State var selectionIndex: Int = 0
    //    @State var selectionString: String = ""
    
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let _ = Self._printChanges()
        ScrollViewReader { proxy in
            VStack {
                // List(albumNames, id: \.self)
                List(albumItems, selection: $selection)
                { item in
                    Text(item.title)
                    //                        .id(item)
                }
            }
            .onChange(of: selection) { newState in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismissPicker()
                }
            }
            .onAppear() {
                print("AlbumPickerView onAppear", selection as Any)
                if let selection {
                    proxy.scrollTo(selection)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Select Album")
    }
    
    private func dismissPicker() {
        // showPicker = false
        xprint("selection", selection ?? "-none-")
        //        xprint("selectionString", selectionString)
        //        selection = selectionString
        if let selection {
            app.settings.photoAlbum = selection.title
            app.lobbyModel.albumName = selection.title
            app.saveSettings()
            app.photosModel.refresh()
        }
        dismiss();
    }
    
}

// scrollTo works!
//
struct AlbumPickerView2: View {
    @State var selection: String?
    @State var selectionInt: Int? = 99
    var albumNames: [String]
    
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let _ = Self._printChanges()
        ScrollViewReader { proxy in
            VStack {
                Button("Jump to #50") {
                    proxy.scrollTo(50, anchor: .top)
                }
                Button("Jump to #1") {
                    proxy.scrollTo(1)
                }
//                List(albumNames, id: \.self, selection: $selection)
//                { item in
//                    Text(item)
//                        .id(item)
//                }
                List(0..<200, id: \.self, selection: $selectionInt)
                { index in
                    Text("Example \(index)")
                        .id(index)
                }
            }
//            .onChange(of: selectionInt) { newState in
//                print("AlbumPickerView onChange selectionInt", selectionInt as Any)
//                dismiss()
//            }
            .onChange(of: selection) { newState in
                print("AlbumPickerView onChange selectionInt", selection as Any)
                dismiss()
            }
            .onAppear() {
                // selectionInt
                print("AlbumPickerView onAppear", selectionInt as Any)
                if let selectionInt {
                    proxy.scrollTo(selectionInt, anchor: .top)
                }
                else {
                    print("AlbumPickerView no selectionInt")
                }
            }
        }
    }
}

struct AlbumPickerView3: View {
    @State var selection: String?
    @State var selectionInt: Int? = 99
    var albumNames: [String]
    
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let _ = Self._printChanges()
        ScrollViewReader { proxy in
            VStack {
                Button("Jump to #50") {
                    proxy.scrollTo(50, anchor: .top)
                }
                Button("Jump to #1") {
                    proxy.scrollTo(1)
                }
                
                List(0..<200, id: \.self, selection: $selectionInt)
                { index in
                    Text("Example \(index)")
                        .id(index)
                }
            }
            .onChange(of: selectionInt) { newState in
                print("AlbumPickerView onChange selectionInt", selectionInt as Any)
                dismiss()
            }
            .onAppear() {
                // selectionInt
                print("AlbumPickerView onAppear", selectionInt as Any)
                if let selectionInt {
                    proxy.scrollTo(selectionInt, anchor: .top)
                }
                else {
                    print("AlbumPickerView no selectionInt")
                }
            }
        }
    }
}

//#Preview {
//    AlbumPickerView()
//}
