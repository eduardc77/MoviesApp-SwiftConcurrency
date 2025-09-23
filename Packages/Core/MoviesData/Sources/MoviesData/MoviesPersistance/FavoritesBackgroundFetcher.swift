//
//  FavoritesBackgroundFetcher.swift
//  MoviesData
//
//  Created by User on 9/21/25.
//

import Foundation
import SwiftData
import MoviesDomain

/// An isolated worker responsible for running potentially heavy SwiftData fetches off the main actor
actor FavoritesBackgroundFetcher {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchAllFavorites(sortedBy sortOrder: MovieSortOrder?) throws -> [Movie] {
        let context = ModelContext(container)

        // Build sort descriptors (match FavoritesLocalDataSource semantics)
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
            case .recentlyAdded:
                sortDescriptors.append(SortDescriptor(\.createdAt, order: .reverse))
            }
        } else {
            // Default: recently added first
            sortDescriptors.append(SortDescriptor(\.createdAt, order: .reverse))
        }
        // deterministic tie-breaker
        sortDescriptors.append(SortDescriptor(\.movieId, order: .forward))

        let descriptor = FetchDescriptor<FavoriteMovieEntity>(sortBy: sortDescriptors)
        let rows = try context.fetch(descriptor)

        return rows.map { row in
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
    }

    func fetchFirstPage(sortedBy sortOrder: MovieSortOrder, pageSize: Int) throws -> (items: [Movie], cursor: FavoritesPageCursor?) {
        let context = ModelContext(container)
        let sortDescriptors = FavoritesSortBuilder.descriptors(for: sortOrder)
        var descriptor = FetchDescriptor<FavoriteMovieEntity>(sortBy: sortDescriptors)
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = 0
        let rows = try context.fetch(descriptor)
        let items = rows.map { row in
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
        let last = rows.last
        let cursor: FavoritesPageCursor? = {
            guard let row = last else { return nil }
            switch sortOrder {
            case .recentlyAdded:
                return .recentlyAdded(lastCreatedAt: row.createdAt, lastMovieId: row.movieId)
            case .ratingDescending:
                return .ratingDescending(lastVoteAverage: row.voteAverage, lastMovieId: row.movieId)
            case .ratingAscending:
                return .ratingAscending(lastVoteAverage: row.voteAverage, lastMovieId: row.movieId)
            case .releaseDateDescending:
                return .releaseDateDescending(lastDate: row.releaseDate, lastMovieId: row.movieId)
            case .releaseDateAscending:
                return .releaseDateAscending(lastDate: row.releaseDate, lastMovieId: row.movieId)
            case .popularityAscending, .popularityDescending:
                return nil
            }
        }()
        return (items, cursor)
    }

    func fetchNextPage(cursor: FavoritesPageCursor, pageSize: Int) throws -> (items: [Movie], cursor: FavoritesPageCursor?) {
        let context = ModelContext(container)
        // Derive sort order from cursor case
        let (sortOrder, predicate): (MovieSortOrder, Predicate<FavoriteMovieEntity>?) = {
            switch cursor {
            case let .recentlyAdded(lastCreatedAt, lastMovieId):
                let pred = #Predicate<FavoriteMovieEntity> { entity in
                    (entity.createdAt < lastCreatedAt) || (entity.createdAt == lastCreatedAt && entity.movieId > lastMovieId)
                }
                return (.recentlyAdded, pred)
            case let .ratingDescending(lastVote, lastId):
                let pred = #Predicate<FavoriteMovieEntity> { entity in
                    (entity.voteAverage < lastVote) || (entity.voteAverage == lastVote && entity.movieId > lastId)
                }
                return (.ratingDescending, pred)
            case let .ratingAscending(lastVote, lastId):
                let pred = #Predicate<FavoriteMovieEntity> { entity in
                    (entity.voteAverage > lastVote) || (entity.voteAverage == lastVote && entity.movieId > lastId)
                }
                return (.ratingAscending, pred)
            case let .releaseDateDescending(lastDate, lastId):
                let pred = #Predicate<FavoriteMovieEntity> { entity in
                    (entity.releaseDate < lastDate) || (entity.releaseDate == lastDate && entity.movieId > lastId)
                }
                return (.releaseDateDescending, pred)
            case let .releaseDateAscending(lastDate, lastId):
                let pred = #Predicate<FavoriteMovieEntity> { entity in
                    (entity.releaseDate > lastDate) || (entity.releaseDate == lastDate && entity.movieId > lastId)
                }
                return (.releaseDateAscending, pred)
            }
        }()
        let sortDescriptors = FavoritesSortBuilder.descriptors(for: sortOrder)

        var descriptor = FetchDescriptor<FavoriteMovieEntity>(predicate: predicate, sortBy: sortDescriptors)
        descriptor.fetchLimit = pageSize
        let rows = try context.fetch(descriptor)
        let items = rows.map { row in
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
        let last = rows.last
        let next: FavoritesPageCursor? = {
            guard let row = last else { return nil }
            switch sortOrder {
            case .recentlyAdded:
                return .recentlyAdded(lastCreatedAt: row.createdAt, lastMovieId: row.movieId)
            case .ratingDescending:
                return .ratingDescending(lastVoteAverage: row.voteAverage, lastMovieId: row.movieId)
            case .ratingAscending:
                return .ratingAscending(lastVoteAverage: row.voteAverage, lastMovieId: row.movieId)
            case .releaseDateDescending:
                return .releaseDateDescending(lastDate: row.releaseDate, lastMovieId: row.movieId)
            case .releaseDateAscending:
                return .releaseDateAscending(lastDate: row.releaseDate, lastMovieId: row.movieId)
            case .popularityAscending, .popularityDescending:
                return nil
            }
        }()
        return (items, next)
    }
}


