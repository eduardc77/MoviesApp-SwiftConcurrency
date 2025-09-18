//
//  EndpointProtocol.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation

/// Protocol defining the common interface for API endpoints
/// This allows for type-safe, testable, and extensible endpoint definitions
public protocol EndpointProtocol {
    /// The HTTP method for this endpoint
    var method: HTTPMethod { get }

    /// The path component of the endpoint
    var path: String { get }

    /// Query parameters for the endpoint
    var queryParameters: [URLQueryItem] { get }

    /// HTTP headers for the endpoint
    var headers: [String: String] { get }

    /// Request body data (if any)
    var body: Data? { get }
}

// MARK: - Default Implementations

public extension EndpointProtocol {
    /// Default GET method
    var method: HTTPMethod { .get }

    /// Default empty headers
    var headers: [String: String] { [:] }

    /// Default no body
    var body: Data? { nil }
}
