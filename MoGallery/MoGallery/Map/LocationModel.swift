//
//  MapRegionModel.swift
//  EarthFlags
//
//  Created by jht2 on 11/18/23.
//

import Foundation
import MapKit

@MainActor class LocationModel: ObservableObject {
        
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 40.630566,    // Brooklyn Flatlands
            longitude: -73.922013),
        span: MKCoordinateSpan(
            latitudeDelta: 0.001,
            longitudeDelta: 0.001)
    )
    @Published var locations:[Location] = []
    var currentLocation = Location()
    var index = 0

    static let main = LocationModel()

    static var sample:LocationModel {
        let model = LocationModel();
        model.locations = knownLocations
        return model
    }

    func locationMatch(_ current:Location) -> Bool {
//        xprint("locationMatch current", current, "center", region.center)
        let epsilon = 0.000001;
        let center = region.center
        return abs(current.latitude - center.latitude) < epsilon
            && abs(current.longitude - center.longitude) < epsilon
    }
    
    func setLocations(_ locs: [Location]) {
        locations = locs;
    }

    func nextLocation() {
        xprint("LocationModel next index", index, "locations.count", locations.count)
        if locations.count <= 0 {
            return;
        }
        index = (index + 1) % locations.count;
        setLocation(index: index)
    }
    
    func setLocation(index: Int) {
        self.index = index;
        let loc = locations[index];
        region = loc.region
        currentLocation = loc;
//        AppModel.main.currentFlagItem(loc.id)
    }
    
    func setLocation(ccode: String) {
        if let index = locations.firstIndex(where: { $0.id == ccode }) {
            setLocation(index: index)
        }
    }
    
    func setLocation(_ location: Location) {
        if let index = locations.firstIndex(of: location) {
            setLocation(index: index);
        }
    }
    
    func restoreLocation() {
        region = currentLocation.region
    }
        
//    func restoreFrom(marked: Array<String>) {
//        xprint("LocationModel restoreFrom marked", marked)
//        var newLocs = [Location]()
//        for ccode in marked {
//            guard let fitem = AppModel.main.flagItem(ccode: ccode) else { continue }
//            let loc = Location(
//                id: fitem.alpha3,
//                latitude: fitem.latitude,
//                longitude: fitem.longitude,
//                label: fitem.name,
//                capital: fitem.capital);
//            newLocs.append(loc)
//        }
//        locations = newLocs;
//        if !newLocs.isEmpty {
//            setLocation(index: 0)
//        }
//    }
}

let knownLocations:[Location] = [
    Location(delta: 5.0), // USA Brooklyn Flatlands
    Location(id: "USA", latitude: 38.883333, longitude: -77.016667, label: "USA", capital: "Washington, D.C."),
    Location(id: "GBR", latitude: 51.500000, longitude: -0.1166670, label: "UK", capital: "London"),
    Location(id: "JAM", latitude: 17.983333, longitude: -76.800000, label: "Jamaica", capital: "Kingston"),
    Location(id: "GUY", latitude: 6.8058330, longitude: -58.150833, label: "Guyana", capital: "Georgetown"),
    Location(id: "GHA", latitude: 5.5550000, longitude: -0.1925000, label: "Ghana", capital: "Accra"),
    Location(id: "EGY", latitude: 30.033333, longitude: 31.2166670, label: "Egypt", capital: "Cairo")
];

class Location: Identifiable, Codable, Equatable {
        
    var id = "USA Brooklyn Flatlands"
    var latitude = 40.630566
    var longitude = -73.922013
    var label = "USA Brooklyn Flatlands"
    var capital = "Brooklyn Flatlands"
    var delta = 0.001
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
    
    internal init(
        id: String = "USA Brooklyn Flatlands",
        latitude: Double = 40.630566,
        longitude: Double = -73.922013,
        label: String = "USA Brooklyn Flatlands",
        capital: String = "Brooklyn Flatlands",
        delta: Double = 0.001) {
            self.id = id
            self.latitude = latitude
            self.longitude = longitude
            self.label = label
            self.capital = capital
            self.delta = delta
        }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var imageRef: String {
        "flag-\(id)"
    }
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude),
            span: MKCoordinateSpan(
                latitudeDelta: delta,
                longitudeDelta: delta)
        )
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude
        && lhs.center.longitude == rhs.center.longitude
        && lhs.span.latitudeDelta == rhs.span.latitudeDelta
        && lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

// https://www.hackingwithswift.com/books/ios-swiftui/bucket-list-introduction
// https://github.com/twostraws/HackingWithSwift.git

