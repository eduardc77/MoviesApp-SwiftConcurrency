//
//  DomainError.swift
//  MoviesDomain
//
//  Created by User on 9/14/25.
//

import Foundation

/// Central error type for the Domain layer.
/// Infra errors (network/persistence) should be mapped to this at repository boundaries.
public enum DomainError: Error, LocalizedError, Sendable {
    case network(underlying: Error)
    case decoding(underlying: Error)
    case httpStatus(code: Int)
    case unauthorized
    case rateLimited
    case notFound
    case persistence(underlying: Error)
    case unknown(underlying: Error?)

    public var errorDescription: String? {
        switch self {
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .decoding(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .httpStatus(let code):
            return "HTTP error with status code: \(code)"
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .notFound:
            return "The requested resource could not be found."
        case .persistence(let underlying):
            return "Data persistence error: \(underlying.localizedDescription)"
        case .unknown(let underlying):
            return underlying?.localizedDescription ?? "Unknown error occurred"
        }
    }
}
