//
//  DatabaseDate.swift
//  BCycle
//
//  Created by Thomas Traylor on 12/31/23.
//

import Foundation

@propertyWrapper
struct DatabaseDate : Codable {
    var wrappedValue: Date?
    init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let dateString = try decoder.singleValueContainer().decode(String.self)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        wrappedValue = formatter.date(from: dateString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        if let wrappedValue = self.wrappedValue {
            let dateString = formatter.string(from: wrappedValue)
            try container.encode(["value": dateString])
            return
        }
        
        try container.encode(false)
    }
}
