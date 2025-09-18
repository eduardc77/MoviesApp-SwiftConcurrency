//
//  MoviesResponseDTO.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

/// Data Transfer Object for TMDB movies API response
/// Infrastructure layer - API contract, separate from domain models
public struct MoviesResponseDTO: Decodable {
    public let results: [MovieDTO]
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
}
