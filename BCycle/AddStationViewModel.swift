//
//  AddStationViewModel.swift
//  BCycle
//
//  Created by Thomas Traylor on 3/14/24.
//

import Foundation
import Combine
import MapKit

@MainActor
class AddStationViewModel: ObservableObject {
    
    @Published var name = ""
    @Published var street = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zip = ""
    @Published var docks = 0
    var location: CLLocation = .init()
    
    
    var isValidName: AnyPublisher<Bool, Never> {
        $name.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    var isValidStreet: AnyPublisher<Bool, Never> {
        $street.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    var isValidCity: AnyPublisher<Bool, Never> {
        $city.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    var isValidState: AnyPublisher<Bool, Never> {
        $state.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    var isValidZip: AnyPublisher<Bool, Never> {
        $zip.map { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    var isValidDocks: AnyPublisher<Bool, Never> {
        $docks.map { $0 > 0 }
            .eraseToAnyPublisher()
    }
    
    var isSubmitEnabled: AnyPublisher<Bool, Never> {
        let paramOne = Publishers.CombineLatest3(isValidName, isValidStreet, isValidCity)
            .map { $0 && $1 && $2 }
        let paramTwo = Publishers.CombineLatest3(isValidState, isValidZip, isValidDocks)
            .map { $0 && $1 && $2 }
        return Publishers.CombineLatest(paramOne, paramTwo)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }
    
    func saveStation(_ callback: @escaping (() -> Void)) {
        
        Task {
            var station = Station()
            station.name = self.name
            station.street = self.street
            station.city = self.city
            station.state = self.state
            station.zip = self.zip
            station.docks = self.docks
            station.latitude = self.location.coordinate.latitude
            station.longitude = self.location.coordinate.longitude
            
            do {
                let bcycleApiService = BCycleApiService()
                let _ = try await bcycleApiService.createStation(station)
                callback()
            }
            catch {
                print("caught error")
            }
        }
    }
}
