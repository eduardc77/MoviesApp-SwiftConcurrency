//
//  TMDBNetworkingClientProtocol.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation

/// Protocol for HTTP client operations
/// Infrastructure layer - handles network requests and responses
public protocol TMDBNetworkingClientProtocol: Sendable {
    /// Performs a network request and decodes the response
    /// - Parameter endpoint: The endpoint to request
    /// - Returns: Decoded response value
    func request<T: Decodable>(_ endpoint: EndpointProtocol) async throws -> T
}
