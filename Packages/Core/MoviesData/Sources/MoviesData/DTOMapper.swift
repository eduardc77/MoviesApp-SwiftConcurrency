//
//  DTOMapper.swift
//  MoviesData
//
//  Created by User on 9/16/25.
//

import MoviesDomain
import MoviesNetwork

/// Mapper for converting between DTOs and Domain Models
/// Bridges the network infrastructure layer with domain models
enum DTOMapper {
    /// Convert MovieDTO to Domain Movie
    static func toDomain(_ dto: MovieDTO) -> Movie {
        Movie(
            id: dto.id,
            title: dto.title,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseDate: dto.releaseDate ?? "",
            voteAverage: dto.voteAverage ?? 0.0,
            voteCount: dto.voteCount ?? 0,
            genres: dto.genres?.map(toDomain),
            popularity: dto.popularity ?? 0.0
        )
    }

    /// Convert GenreDTO to Domain Genre
    static func toDomain(_ dto: GenreDTO) -> Genre {
        Genre(id: dto.id, name: dto.name)
    }

    /// Convert MovieDetailsDTO to Domain MovieDetails
    static func toDomain(_ dto: MovieDetailsDTO) -> MovieDetails {
        MovieDetails(
            id: dto.id,
            title: dto.title,
            overview: dto.overview ?? "",
            posterPath: dto.posterPath,
            backdropPath: dto.backdropPath,
            releaseDate: dto.releaseDate ?? "",
            voteAverage: dto.voteAverage ?? 0.0,
            voteCount: dto.voteCount ?? 0,
            runtime: dto.runtime,
            genres: dto.genres?.map(toDomain) ?? [],
            tagline: dto.tagline
        )
    }

    /// Convert array of MovieDTO to array of Domain Movie
    static func toDomain(_ dtos: [MovieDTO]) -> [Movie] {
        dtos.map(toDomain)
    }

    /// Convert array of GenreDTO to array of Domain Genre
    static func toDomain(_ dtos: [GenreDTO]) -> [Genre] {
        dtos.map(toDomain)
    }
}
