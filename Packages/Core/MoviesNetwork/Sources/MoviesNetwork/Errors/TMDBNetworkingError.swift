//
//  TMDBNetworkingError.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation

/// Networking-specific errors
public enum TMDBNetworkingError: Error, LocalizedError {
    case invalidURL

    case networkError(Error)
    case decodingError(DecodingError)
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL constructed for request"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error with status code: \(code)"

        }
    }
}
