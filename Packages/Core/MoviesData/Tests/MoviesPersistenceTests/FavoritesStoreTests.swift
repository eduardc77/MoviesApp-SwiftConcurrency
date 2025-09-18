//
//  FavoritesStoreTests.swift
//  MoviesPersistenceTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
import MoviesDomain
@testable import MoviesData

private final class LocalDataSourceMock: @unchecked Sendable, FavoritesLocalDataSourceProtocol {
    var ids: Set<Int> = []
    var shouldFail = false

    func getFavoriteMovieIds() -> AnyPublisher<Set<Int>, Error> {
        Just(ids).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func addToFavorites(movie: Movie) -> AnyPublisher<Void, Error> {
        if shouldFail { return Fail(error: NSError(domain: "x", code: -1)).eraseToAnyPublisher() }
        ids.insert(movie.id)
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func addToFavorites(details: MovieDetails) -> AnyPublisher<Void, Error> {
        if shouldFail { return Fail(error: NSError(domain: "x", code: -1)).eraseToAnyPublisher() }
        ids.insert(details.id)
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func removeFromFavorites(movieId: Int) -> AnyPublisher<Void, Error> {
        if shouldFail { return Fail(error: NSError(domain: "x", code: -1)).eraseToAnyPublisher() }
        ids.remove(movieId)
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func isFavorite(movieId: Int) -> AnyPublisher<Bool, Error> {
        Just(ids.contains(movieId)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) -> AnyPublisher<[Movie], Error> {
        let sortedIds = Array(ids).sorted()
        let start = max(page - 1, 0) * pageSize
        let end = min(start + pageSize, sortedIds.count)
        let slice = (start < end) ? Array(sortedIds[start..<end]) : []
        let movies = slice.map { id in
            Movie(id: id, title: "t\(id)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0)
        }
        return Just(movies).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func getFavoriteDetails(movieId: Int) -> AnyPublisher<MovieDetails?, Error> {
        if ids.contains(movieId) {
            let details = MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
            return Just(details).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
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


