//
//  MovieDetailsDTO.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

/// Data Transfer Object for movie details
public struct MovieDetailsDTO: Decodable {
    public let id: Int
    public let title: String
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let runtime: Int?
    public let genres: [GenreDTO]?
    public let tagline: String?
}
