//
//  MovieDTO.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

/// Data Transfer Object for TMDB movie data
/// Infrastructure layer - API contract, separate from domain Movie model
public struct MovieDTO: Decodable {
    public let id: Int
    public let title: String
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let genreIds: [Int]?
    public let genres: [GenreDTO]?
    public let popularity: Double?
    public let video: Bool?
    public let adult: Bool?
    public let originalLanguage: String?
    public let originalTitle: String?
}
