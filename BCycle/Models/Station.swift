//
//  Station.swift
//  BCycle
//
//  Created by Thomas Traylor on 12/8/20.
//

import Foundation
import MapKit

struct Station : Codable, Identifiable {
    var id: Int?
    var name: String?
    var street: String?
    var city: String?
    var state: String?
    var zip: String?
    var docks: Int?
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    @DatabaseDate var created: Date?
    @DatabaseDate var updated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case street
        case city
        case state
        case zip
        case docks
        case latitude
        case longitude
        case created
        case updated
    }
}

class StationAnnotation : NSObject, MKAnnotation {
    
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var station: Station
    
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    var title: String?

    init(station: Station) {
        self.station = station
        latitude = station.latitude
        longitude = station.longitude
        title = station.name
    }
}
