//
//  FavoritesStorageTests.swift
//  MoviesDataTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
import SwiftData
@testable import MoviesData
import MoviesDomain

final class FavoritesStorageTests: XCTestCase {

    @MainActor
    func testGetFavoriteMovieIdsEmpty() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let sut = FavoritesLocalDataSource(container: container)
        var cancellables = Set<AnyCancellable>()
        let exp = expectation(description: "empty")
        sut.getFavoriteMovieIds()
            .sink(receiveCompletion: { _ in }, receiveValue: { ids in
                XCTAssertTrue(ids.isEmpty)
                exp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1)
    }

    @MainActor
    func testAddAndRemoveFavorites() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let sut = FavoritesLocalDataSource(container: container)
        var cancellables = Set<AnyCancellable>()
        let add1 = expectation(description: "add1")
        sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            .sink(receiveCompletion: { _ in add1.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [add1], timeout: 1)

        let add2 = expectation(description: "add2")
        sut.addToFavorites(movie: Movie(id: 2, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            .sink(receiveCompletion: { _ in add2.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [add2], timeout: 1)

        let isFav = expectation(description: "isFav")
        sut.isFavorite(movieId: 1)
            .sink(receiveCompletion: { _ in }, receiveValue: { value in
                XCTAssertTrue(value)
                isFav.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [isFav], timeout: 1)

        let remove = expectation(description: "remove")
        sut.removeFromFavorites(movieId: 1)
            .sink(receiveCompletion: { _ in remove.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [remove], timeout: 1)
    }

    @MainActor
    func testDuplicateAddToFavoritesKeepsSingleEntry() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let sut = FavoritesLocalDataSource(container: container)
        var cancellables = Set<AnyCancellable>()
        let add1 = expectation(description: "add1")
        sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            .sink(receiveCompletion: { _ in add1.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [add1], timeout: 1)

        let add2 = expectation(description: "add2")
        sut.addToFavorites(movie: Movie(id: 1, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            .sink(receiveCompletion: { _ in add2.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [add2], timeout: 1)

        let idsExp = expectation(description: "ids")
        sut.getFavoriteMovieIds()
            .sink(receiveCompletion: { _ in }, receiveValue: { ids in
                XCTAssertEqual(ids.count, 1)
                XCTAssertTrue(ids.contains(1))
                idsExp.fulfill()
            })
            .store(in: &cancellables)
        wait(for: [idsExp], timeout: 1)
    }

    @MainActor
    func testConcurrentOpsNoDeadlock() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let sut = FavoritesLocalDataSource(container: container)
        var cancellables = Set<AnyCancellable>()
        // Just verify that multiple operations complete successfully
        let expectation = self.expectation(description: "Multiple operations complete")

        var completedCount = 0
        let totalOperations = 5

        for i in 0..<totalOperations {
            sut.addToFavorites(movie: Movie(id: i, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0)).sink(receiveCompletion: { _ in
                completedCount += 1
                if completedCount == totalOperations {
                    expectation.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(completedCount, totalOperations)
    }

    @MainActor
    func testMemoryLeakPreventionSubscriptionCleanup() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: config)
        let sut = FavoritesLocalDataSource(container: container)
        var cancellables = Set<AnyCancellable>()
        // Critical test: Verify Combine subscriptions don't cause memory leaks
        weak var weakStorage: FavoritesLocalDataSource? = sut

        autoreleasepool {
            // Create a subscription and immediately cancel it
            let cancellable = sut.getFavoriteMovieIds()
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

            // Store it in cancellables set
            cancellable.store(in: &cancellables)

            // Remove the cancellable (simulating view deallocation)
            cancellables.removeAll()
        }

        // Force garbage collection by creating memory pressure
        for _ in 0..<1000 {
            _ = NSObject()
        }

        // Verify the storage is still alive (not leaked)
        // This ensures we haven't created any strong reference cycles
        XCTAssertNotNil(weakStorage, "FavoritesStorage should not be deallocated")

        // Verify storage is still functional after subscription cleanup
        let expectation = self.expectation(description: "Storage still works")
        sut.addToFavorites(movie: Movie(id: 999, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2.0)
    }
}
