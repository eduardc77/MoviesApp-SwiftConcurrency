//
//  FavoriteMovieEntity.swift
//  MoviesData
//
//  Created by User on 9/10/25.
//

import Foundation
import SwiftData

@Model
public final class FavoriteMovieEntity {
    @Attribute(.unique)
    public var movieId: Int
    public var title: String
    public var overview: String
    public var posterPath: String?
    public var backdropPath: String?
    public var releaseDate: String
    public var voteAverage: Double
    public var voteCount: Int
    public var runtime: Int?
    public var popularity: Double?
    public var tagline: String?
    @Relationship(deleteRule: .cascade)
    public var genres: [FavoriteGenreEntity]
    public var createdAt: Date

    public init(
        movieId: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String,
        voteAverage: Double,
        voteCount: Int,
        runtime: Int?,
        popularity: Double?,
        tagline: String?,
        genres: [FavoriteGenreEntity] = [],
        createdAt: Date = .now
    ) {
        self.movieId = movieId
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.runtime = runtime
        self.popularity = popularity
        self.tagline = tagline
        self.genres = genres
        self.createdAt = createdAt
    }
}

@Model
public final class FavoriteGenreEntity {
    public var id: Int
    public var name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
