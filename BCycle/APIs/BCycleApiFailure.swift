//
//  BCycleApiFailure.swift
//  BCycle
//
//  Created by Thomas Traylor on 12/31/23.
//

import Foundation

enum BCycleApiFailure: Error {
    case invalidURL
    case invalidServerResponse
    case badRequest
    case forbidden
    case notFound
    case created
    case finishedWithoutValue
    case decodingError
}
