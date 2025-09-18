//
//  FavoritesLocalDataSource.swift
//  MoviesData
//
//  Created by User on 9/10/25.
//

import Foundation
import SwiftData
import MoviesDomain

public protocol FavoritesLocalDataSourceProtocol: Sendable {
    /// Get current favorite movie IDs
    func getFavoriteMovieIds() async throws -> Set<Int>

    /// Add a snapshot of Movie to favorites
    func addToFavorites(movie: Movie) async throws
    /// Add a snapshot of MovieDetails to favorites
    func addToFavorites(details: MovieDetails) async throws

    /// Remove movie from favorites
    func removeFromFavorites(movieId: Int) async throws

    /// Check if movie is favorited
    func isFavorite(movieId: Int) async throws -> Bool

    /// Fetch a page of favorited movies from local storage
    func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) async throws -> [Movie]

    /// Fetch locally stored favorite details snapshot if available
    func getFavoriteDetails(movieId: Int) async throws -> MovieDetails?
}

/// Actor-based storage backed by SwiftData for thread-safe concurrent operations.
public actor FavoritesLocalDataSource: FavoritesLocalDataSourceProtocol {
    private let container: ModelContainer

    public init(container: ModelContainer? = nil) {
        if let container {
            self.container = container
        } else {
            // Create a private container if one isn't injected (app can inject its own)
            do {
                self.container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self)
            } catch {
                fatalError("Failed to create ModelContainer for FavoriteMovie: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    /// Fetches a single favorite movie entity by ID
    private func fetchByMovieId(_ id: Int, in context: ModelContext) throws -> FavoriteMovieEntity? {
        var descriptor = FetchDescriptor<FavoriteMovieEntity>(
            predicate: #Predicate { $0.movieId == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Safely replaces genres relationship to prevent orphaned rows
    private func replaceGenres(for entity: FavoriteMovieEntity, with newGenres: [FavoriteGenreEntity], in context: ModelContext) {
        // Clear existing relationships to prevent orphans
        entity.genres.forEach { context.delete($0) }
        entity.genres = newGenres
    }

    public func getFavoriteMovieIds() async throws -> Set<Int> {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<FavoriteMovieEntity>(
            sortBy: [SortDescriptor(\FavoriteMovieEntity.createdAt, order: .reverse)]
        )
        let rows = try context.fetch(descriptor)
        return Set(rows.map { $0.movieId })
    }

    public func addToFavorites(movie: Movie) async throws {
        let context = ModelContext(container)
        let targetId = movie.id

        if let existing = try fetchByMovieId(targetId, in: context) {
            // Update existing entity
            existing.title = movie.title
            existing.overview = movie.overview
            existing.posterPath = movie.posterPath
            existing.backdropPath = movie.backdropPath
            existing.releaseDate = movie.releaseDate
            existing.voteAverage = movie.voteAverage
            existing.voteCount = movie.voteCount
            existing.runtime = nil
            existing.popularity = movie.popularity
            existing.tagline = nil
            let newGenres = movie.genres?.map { FavoriteGenreEntity(id: $0.id, name: $0.name) } ?? []
            replaceGenres(for: existing, with: newGenres, in: context)
        } else {
            // Create new entity
            let genres = movie.genres?.map { FavoriteGenreEntity(id: $0.id, name: $0.name) } ?? []
            let entity = FavoriteMovieEntity(
                movieId: movie.id,
                title: movie.title,
                overview: movie.overview,
                posterPath: movie.posterPath,
                backdropPath: movie.backdropPath,
                releaseDate: movie.releaseDate,
                voteAverage: movie.voteAverage,
                voteCount: movie.voteCount,
                runtime: nil,
                popularity: movie.popularity,
                tagline: nil,
                genres: genres
            )
            context.insert(entity)
        }
        try context.save()
    }

    public func addToFavorites(details: MovieDetails) async throws {
        let context = ModelContext(container)
        let targetId = details.id

        let genres = details.genres.map { FavoriteGenreEntity(id: $0.id, name: $0.name) }

        if let existing = try fetchByMovieId(targetId, in: context) {
            // Update existing entity
            existing.title = details.title
            existing.overview = details.overview
            existing.posterPath = details.posterPath
            existing.backdropPath = details.backdropPath
            existing.releaseDate = details.releaseDate
            existing.voteAverage = details.voteAverage
            existing.voteCount = details.voteCount
            existing.runtime = details.runtime
            existing.tagline = details.tagline
            replaceGenres(for: existing, with: genres, in: context)
        } else {
            // Create new entity
            let entity = FavoriteMovieEntity(
                movieId: details.id,
                title: details.title,
                overview: details.overview,
                posterPath: details.posterPath,
                backdropPath: details.backdropPath,
                releaseDate: details.releaseDate,
                voteAverage: details.voteAverage,
                voteCount: details.voteCount,
                runtime: details.runtime,
                popularity: 0, // Note: MovieDetails doesn't have popularity data
                tagline: details.tagline,
                genres: genres
            )
            context.insert(entity)
        }
        try context.save()
    }

    public func removeFromFavorites(movieId: Int) async throws {
        let context = ModelContext(container)
        if let obj = try fetchByMovieId(movieId, in: context) {
            context.delete(obj)
            try context.save()
        }
    }

    public func isFavorite(movieId: Int) async throws -> Bool {
        let context = ModelContext(container)
        let exists = try fetchByMovieId(movieId, in: context) != nil
        return exists
    }

    public func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) async throws -> [Movie] {
        let context = ModelContext(container)

        var sortDescriptors: [SortDescriptor<FavoriteMovieEntity>] = []
        if let order = sortOrder {
            switch order {
            case .popularityAscending:
                sortDescriptors.append(SortDescriptor(\.popularity, order: .forward))
            case .popularityDescending:
                sortDescriptors.append(SortDescriptor(\.popularity, order: .reverse))
            case .ratingAscending:
                sortDescriptors.append(SortDescriptor(\.voteAverage, order: .forward))
            case .ratingDescending:
                sortDescriptors.append(SortDescriptor(\.voteAverage, order: .reverse))
            case .releaseDateAscending:
                sortDescriptors.append(SortDescriptor(\.releaseDate, order: .forward))
            case .releaseDateDescending:
                sortDescriptors.append(SortDescriptor(\.releaseDate, order: .reverse))
            }
        } else {
            sortDescriptors.append(SortDescriptor(\.createdAt, order: .reverse))
        }
        sortDescriptors.append(SortDescriptor(\.movieId, order: .forward))

        var descriptor = FetchDescriptor<FavoriteMovieEntity>(
            sortBy: sortDescriptors
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max((page - 1), 0) * pageSize
        let rows = try context.fetch(descriptor)

        let mapped: [Movie] = rows.map { row in
            Movie(
                id: row.movieId,
                title: row.title,
                overview: row.overview,
                posterPath: row.posterPath,
                backdropPath: row.backdropPath,
                releaseDate: row.releaseDate,
                voteAverage: row.voteAverage,
                voteCount: row.voteCount,
                genres: row.genres.map { Genre(id: $0.id, name: $0.name) },
                popularity: row.popularity ?? 0
            )
        }
        return mapped
    }

    public func getFavoriteDetails(movieId: Int) async throws -> MovieDetails? {
        let context = ModelContext(container)
        if let row = try fetchByMovieId(movieId, in: context) {
            let details = MovieDetails(
                id: row.movieId,
                title: row.title,
                overview: row.overview,
                posterPath: row.posterPath,
                backdropPath: row.backdropPath,
                releaseDate: row.releaseDate,
                voteAverage: row.voteAverage,
                voteCount: row.voteCount,
                runtime: row.runtime,
                genres: row.genres.map { Genre(id: $0.id, name: $0.name) },
                tagline: row.tagline
            )
            return details
        } else {
            return nil
        }
    }
}
