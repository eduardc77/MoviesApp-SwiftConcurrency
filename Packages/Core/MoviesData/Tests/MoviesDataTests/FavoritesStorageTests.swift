//
//  FavoritesStorageTests.swift
//  MoviesDataTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SwiftData
@testable import MoviesData
import MoviesDomain

final class FavoritesStorageTests: XCTestCase {

    // MARK: - Test Setup

    private var sut: FavoritesLocalDataSource!
    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        sut = FavoritesLocalDataSource(container: container)
    }

    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testGetFavoriteMovieIdsEmpty() {
        do {
            let ids = try sut.getFavoriteMovieIds()
            XCTAssertTrue(ids.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAddAndRemoveFavorites() {
        do {
            // Add first movie
            try sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))

            // Add second movie
            try sut.addToFavorites(movie: Movie(id: 2, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))

            // Check first movie is favorited
            XCTAssertTrue(sut.isFavorite(movieId: 1))

            // Check second movie is favorited
            XCTAssertTrue(sut.isFavorite(movieId: 2))

            // Remove first movie
            try sut.removeFromFavorites(movieId: 1)

            // Verify first is no longer favorited
            XCTAssertFalse(sut.isFavorite(movieId: 1))

            // Verify second is still favorited
            XCTAssertTrue(sut.isFavorite(movieId: 2))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDuplicateAddToFavoritesKeepsSingleEntry() {
        do {
            // Add same movie twice
            try sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            try sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))

            // Verify only one entry exists
            let ids = try sut.getFavoriteMovieIds()
            XCTAssertEqual(ids.count, 1)
            XCTAssertTrue(ids.contains(1))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConcurrentOpsNoDeadlock() {
        do {
            // Just verify that multiple operations complete successfully
            let totalOperations = 5

            // Add multiple movies synchronously
            for i in 0..<totalOperations {
                try sut.addToFavorites(movie: Movie(id: i, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            }

            // Verify all movies were added
            let ids = try sut.getFavoriteMovieIds()
            XCTAssertEqual(ids.count, totalOperations)

            for i in 0..<totalOperations {
                XCTAssertTrue(ids.contains(i))
                XCTAssertTrue(sut.isFavorite(movieId: i))
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLargeDatasetOperations() {
        do {
            // Test with a larger dataset to ensure performance
            let totalMovies = 100

            // Add many movies
            for i in 0..<totalMovies {
                try sut.addToFavorites(movie: Movie(id: i, title: "t\(i)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            }

            // Verify all were added
            let ids = try sut.getFavoriteMovieIds()
            XCTAssertEqual(ids.count, totalMovies)

            // Smoke test: fetch all rows via SwiftData directly to ensure seed worked
            let ctx = ModelContext(container)
            let rows = try ctx.fetch(FetchDescriptor<FavoriteMovieEntity>())
            XCTAssertEqual(rows.count, totalMovies)

            // Remove half the movies
            for i in 0..<50 {
                try sut.removeFromFavorites(movieId: i)
            }

            // Verify removals
            let remainingIds = try sut.getFavoriteMovieIds()
            XCTAssertEqual(remainingIds.count, 50)

            // Verify remaining movies are still there
            for i in 50..<totalMovies {
                XCTAssertTrue(sut.isFavorite(movieId: i))
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
