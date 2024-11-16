//
//  BCycleApiService.swift
//  BCycle
//
//  Created by Thomas Traylor on 12/31/23.
//

import Foundation
import MapKit

final class BCycleApiService {
    
    private let hostname = "localhost" // "bcycle.local"
    private let MetersPerMile: Double = 1609.344
   
    /// Get all the stations within a given MKCoordinateRegion.
    /// - Parameters:
    ///     - region: The MKCoordinateRegion to return stations from.
    /// - Returns: An array of Stations found.
    ///
    func getStationsInRegion(_ region: MKCoordinateRegion) async throws -> [Station] {
        
        let distanceInMiles = maxDistance(region);
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "latitude", value: String(region.center.latitude)))
        queryItems.append(URLQueryItem(name: "longitude", value: String(region.center.longitude)))
        queryItems.append(URLQueryItem(name: "distance", value: String(distanceInMiles)))
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = hostname
        urlComponents.path = "/api/v1/stations"
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw BCycleApiFailure.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 400 {
                    throw BCycleApiFailure.badRequest
                }
                else {
                    throw BCycleApiFailure.invalidServerResponse
                }
            }
            
            throw BCycleApiFailure.invalidServerResponse
        }
        
        let stations = try JSONDecoder().decode([Station].self, from: data)
        return stations
    }
    
    /// Create a station.
    /// - Parameters:
    ///     - station: The station to create.
    /// - Returns: The newly created station.
    ///
    func createStation(_ station: Station) async throws -> Station {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = hostname
        urlComponents.path = "/api/v1/stations"
        
        guard let url = urlComponents.url else {
            throw BCycleApiFailure.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try JSONEncoder().encode(station)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 400 {
                    throw BCycleApiFailure.badRequest
                }
                else if httpResponse.statusCode == 403 {
                    throw BCycleApiFailure.forbidden
                }
                else {
                    throw BCycleApiFailure.invalidServerResponse
                }
            }
            
            throw BCycleApiFailure.invalidServerResponse
        }
        
        let station = try JSONDecoder().decode(Station.self, from: data)
        return station
    }
    
    /// The max distance in mile from the center of the region to the edge of the region.
    /// - Parameters:
    ///     - region: The MKCoordinateRegion we want to get the distance from.
    /// - Returns: The distance in miles.
    ///
    private func maxDistance(_ region: MKCoordinateRegion) -> Double {
        let centerLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let furthestLocation = CLLocation(latitude: (region.center.latitude + (region.span.latitudeDelta/2)),
                                          longitude: (region.center.longitude + (region.span.longitudeDelta/2)))
        return centerLocation.distance(from: furthestLocation) / MetersPerMile
    }
}
