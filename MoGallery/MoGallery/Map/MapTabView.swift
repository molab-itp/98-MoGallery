//
//  MapViewTab.swift
//  MoGallery
//
//  Created by jht2 on 2/1/23.
//

import SwiftUI
import MapKit

struct MapTabView: View {

    @EnvironmentObject var model: LocationModel
    
    var body: some View {
//        let _ = Self._printChanges()
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $model.region,
                    annotationItems: model.locations )
                { loc in
                    MapAnnotation(coordinate: loc.coordinate) {
                        VStack {
                            Image(loc.imageRef)
                                .resizable()
                                .frame(width: 44, height: 22)
                            Text(loc.label)
                        }
                        .onTapGesture {
                            withAnimation {
                                print("nextLocAction withAnimation")
                                model.setLocation(loc)
                            }
                        }
                    }
                }
                centerCircle()
                topInfo()
                bottomInfo()
            }
            .onAppear {
//                print("MapTabView onAppear locations", model.locations)
            }
            .onChange(of: model.region ) { _ in
//                print("MapTabView onAppear region", model.region)
            }
            // .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !model.locationMatch(model.currentLocation) {
                        Button(action: restoreLocAction ) {
                            Image(systemName: "star.circle" )
                        }
                    }
                    Button(action: nextLocAction ) {
                        Text("Next")
                    }
                }
            }
        }
    }

    func topInfo() -> some View {
        VStack {
            Text(model.currentLocation.label)
            Spacer()
        }
    }
    
    func bottomInfo() -> some View {
        VStack {
            Spacer()
            Text("lat: \(centerLatitude)")
                .font(locationFont)
            Text("lon: \(centerLongitude)")
                .font(locationFont)
        }
    }

    private func centerCircle() -> some View {
        Circle()
            .fill(.blue)
            .opacity(0.3)
            .frame(width: 32, height: 32)
    }
    
    private func starNextButton() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: nextLocAction ) {
                    Image(systemName: "star")
                }
                .padding()
                .background(.black.opacity(0.75))
                .foregroundColor(.white)
                .font(.title)
                .clipShape(Circle())
            }
        }
    }
    
    func restoreLocAction() {
        print("nextLocAction")
        withAnimation {
            print("nextLocAction withAnimation")
            model.restoreLocation()
        }
    }
    
    func nextLocAction() {
        print("nextLocAction")
        withAnimation {
            print("nextLocAction withAnimation")
            model.nextLocation()
        }
    }

    var centerLatitude: String {
        String(format: "%+.6f", model.region.center.latitude)
    }
    
    var centerLongitude: String {
        String(format: "%+.6f", model.region.center.longitude)
    }
    
}

let locationFont = Font
    .system(size: 20)
    .monospaced()

#Preview {
    MapTabView()
        .environmentObject(LocationModel.sample)
}
