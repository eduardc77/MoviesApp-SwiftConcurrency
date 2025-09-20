//
//  FavoritesStoreTests.swift
//  MoviesPersistenceTests
//
//  Created by User on 9/10/25.
//

import XCTest
import MoviesDomain
@testable import MoviesData

private final class LocalDataSourceMock: @unchecked Sendable, FavoritesLocalDataSourceProtocol {
    var ids: Set<Int> = []
    var shouldFail = false

    func getFavoriteMovieIds() throws -> Set<Int> {
        if shouldFail { throw NSError(domain: "test", code: -1, userInfo: nil) }
        return ids
    }

    func addToFavorites(movie: Movie) throws {
        if shouldFail { throw NSError(domain: "test", code: -1, userInfo: nil) }
        ids.insert(movie.id)
    }

    func addToFavorites(details: MovieDetails) throws {
        if shouldFail { throw NSError(domain: "test", code: -1, userInfo: nil) }
        ids.insert(details.id)
    }

    func removeFromFavorites(movieId: Int) throws {
        if shouldFail { throw NSError(domain: "test", code: -1, userInfo: nil) }
        ids.remove(movieId)
    }

    func isFavorite(movieId: Int) -> Bool {
        if shouldFail { return false }
        return ids.contains(movieId)
    }

    func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) throws -> [Movie] {
        if shouldFail { throw NSError(domain: "test", code: -1, userInfo: nil) }
        let sortedIds = Array(ids).sorted()
        let start = max(page - 1, 0) * pageSize
        let end = min(start + pageSize, sortedIds.count)
        let slice = (start < end) ? Array(sortedIds[start..<end]) : []
        return slice.map { id in
            Movie(id: id, title: "t\(id)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0)
        }
    }

    func getFavoriteDetails(movieId: Int) -> MovieDetails? {
        if shouldFail { return nil }
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    // Synchronous methods for incremental updates
    func getFavoriteMovieSync(movieId: Int) -> Movie? {
        if shouldFail { return nil }
        if ids.contains(movieId) {
            return Movie(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0)
        }
        return nil
    }

    func getFavoriteDetailsSync(movieId: Int) -> MovieDetails? {
        if shouldFail { return nil }
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    func isFavoriteSync(movieId: Int) -> Bool {
        if shouldFail { return false }
        return ids.contains(movieId)
    }
}

@MainActor
final class FavoritesStoreTests: XCTestCase {
    func testInitialLoadPopulatesIds() {
        let mock = LocalDataSourceMock()
        mock.ids = [1,2]
        let store = FavoritesStore(favoritesLocalDataSource: mock)
        let exp = expectation(description: "loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertEqual(store.favoriteMovieIds, [1,2])
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testRemoveFavoriteOptimisticRollbackOnFailure() {
        let mock = LocalDataSourceMock()
        mock.ids = [10]
        let store = FavoritesStore(favoritesLocalDataSource: mock)
        // Ensure initial load completed
        let load = expectation(description: "loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { load.fulfill() }
        wait(for: [load], timeout: 1.0)

        XCTAssertTrue(store.favoriteMovieIds.contains(10))

        mock.shouldFail = true
        _ = store.removeFromFavorites(movieId: 10)
        let rollback = expectation(description: "rollback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertTrue(store.favoriteMovieIds.contains(10))
            rollback.fulfill()
        }
        wait(for: [rollback], timeout: 1.0)
    }
}


