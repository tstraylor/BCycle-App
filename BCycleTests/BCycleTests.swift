//
//  BCycleTests.swift
//  BCycleTests
//
//  Created by Thomas Traylor on 12/8/20.
//

import XCTest
import MapKit
@testable import BCycle

class BCycleTests: XCTestCase {

    /// Test decoding a Station.
    ///
    func testStationDecode() throws {
        let jsonStationData = """
            {"id":1,"name":"Market Street Station","street":"1600 Market St","city":"Denver","state":"CO","zip":"80202","docks":21,"latitude":39.7498805,"longitude":-104.9982723,"created":"2023-12-27T15:48:53.000Z","updated":"2023-12-27T15:48:53.000Z"}
        """.data(using: .utf8)!
        let station = try JSONDecoder().decode(Station.self, from: jsonStationData)
        XCTAssertNotNil(station)
        XCTAssertEqual(station.state, "CO")
        XCTAssertEqual(station.latitude, 39.7498805)
        XCTAssertEqual(station.longitude, -104.9982723)
    }

    /// Test getting Stations in a region.
    /// The database needs to be running to use this test.
    ///
    func testGetStationsInRegion() async throws {
        do {
            // get stations in Denver
            let center = CLLocationCoordinate2D(latitude: 39.758202, longitude: -105.001359)
            let region = MKCoordinateRegion(center: center, latitudinalMeters: 1609.34, longitudinalMeters: 1609.34)
            let bcycleApiService = BCycleApiService()
            let stations = try await bcycleApiService.getStationsInRegion(region)
            XCTAssertNotNil(stations)
            if let station = stations.first {
                XCTAssertEqual(station.city, "Denver")
                XCTAssertEqual(station.state, "CO")
            }
            else {
                XCTFail("failed to get the first station")
            }
        }
        catch {
            XCTFail("failed to get stations")
        }
    }
    
    /// Test creating a Station.
    /// The database needs to be running to use this test.
    ///
    func testCreateStation() async throws {
        do {
            // create a random location in downtown Boulder, CO
            let nw = CLLocationCoordinate2D(latitude: 40.020554, longitude: -105.291551)
            let se = CLLocationCoordinate2D(latitude: 40.010589, longitude: -105.273299)
            let boulder = createRandomLocation(nw: nw, se: se)
            if let placemark = await getPlacemark(boulder) {
                let station = createStation(placemark)
                let bcycleApiService = BCycleApiService()
                let newStation = try await bcycleApiService.createStation(station)
                XCTAssertNotNil(newStation)
                XCTAssertEqual(newStation.city, "Boulder")
                XCTAssertEqual(newStation.state, "CO")
            }
            else {
                XCTFail("unable to get a placemark withing boulder")
            }
        }
        catch {
            XCTFail("failed to create a station")
        }
    }
    
    /// Create a random CLLocation within  bounding box.
    /// - Parameters:
    ///     - nw: The northwest corner of the bounding box.
    ///     - se: The southeast corner of the bounding box.
    /// - Returns: A random CLLocation within the specified area.
    ///
    private func createRandomLocation(nw: CLLocationCoordinate2D, se: CLLocationCoordinate2D) -> CLLocation {
        let latitude = randomDoubleBetween(lower: nw.latitude, upper: se.latitude)
        let longitude = randomDoubleBetween(lower: nw.longitude, upper: se.longitude)
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// Generate a random double between a range.
    /// - Parameters:
    ///     - lower: The low end of the range.
    ///     - upper: The top of the range.
    /// - Returns: A random double between the lower and upper range.
    ///
    private func randomDoubleBetween(lower: Double, upper: Double) -> Double {
        let diff: Double = upper - lower
        return ((Double(arc4random() % (UInt32(RAND_MAX) + 1)) / Double(RAND_MAX)) * diff) + lower
    }
    
    /// Get CLPlacemark from the current location.
    /// - Parameters:
    ///     - currentLocation: The current location (CLLocation).
    /// - Returns: A CLPlacemark representing the current location.
    ///
    private func getPlacemark(_ currentLocation: CLLocation) async -> CLPlacemark? {
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(currentLocation) { clPlacmarks, _ in
                if let placemarks = clPlacmarks, let placemark = placemarks.first {
                    continuation.resume(returning: placemark)
                }
                else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Create Station from a CLPlacemark
    /// - Parameters:
    ///     - placemark: The location to create the station.
    /// - Returns: Newly created station.
    ///
    private func createStation(_ placemark: CLPlacemark) -> Station {
        var station = Station()
        station.latitude = placemark.location?.coordinate.latitude ?? 0.0
        station.longitude = placemark.location?.coordinate.longitude ?? 0.0
        station.name = placemark.name
        station.street = "\(placemark.subThoroughfare ?? "100") \(placemark.thoroughfare ?? "Main")"
        station.city = placemark.locality
        station.state = placemark.administrativeArea
        station.zip = placemark.postalCode
        station.docks = 1
        return station
    }
}
