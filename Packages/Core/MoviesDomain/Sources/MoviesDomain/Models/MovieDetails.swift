//
//  MovieDetails.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import DateUtilities

public struct MovieDetails: Identifiable, Hashable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String
    public let voteAverage: Double
    public let voteCount: Int
    public let runtime: Int?
    public let genres: [Genre]
    public let tagline: String?

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String,
        voteAverage: Double,
        voteCount: Int,
        runtime: Int?,
        genres: [Genre],
        tagline: String?
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.runtime = runtime
        self.genres = genres
        self.tagline = tagline
    }

    public var releaseYear: String {
        MovieDateFormatter.year(from: releaseDate)
    }
}

// Extension to convert MovieDetails to Movie for list display
extension MovieDetails {
    /// Converts detailed movie data to basic movie data for list/card display
    public var asMovie: Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genres: genres,
            popularity: 0 // MovieDetails doesn't have popularity, use 0
        )
    }
}
