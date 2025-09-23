//
//  FavoritesViewModelTests.swift
//  MoviesFavoritesTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SharedModels
import SwiftData
@testable import MoviesFavorites
@testable import MoviesDomain
@testable import MoviesData

private class InMemoryFavoritesLocalDataSource: @unchecked Sendable, FavoritesLocalDataSourceProtocol {
    private var ids = Set<Int>()

    func getFavoriteMovieIds() throws -> Set<Int> {
        return ids
    }

    func addToFavorites(movie: Movie) throws {
        ids.insert(movie.id)
    }

    func addToFavorites(details: MovieDetails) throws {
        ids.insert(details.id)
    }

    func removeFromFavorites(movieId: Int) throws {
        ids.remove(movieId)
    }

    func isFavorite(movieId: Int) -> Bool {
        return ids.contains(movieId)
    }

    func getFavoriteDetails(movieId: Int) -> MovieDetails? {
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    // Synchronous methods for incremental updates
    func getFavoriteMovieSync(movieId: Int) -> Movie? {
        if ids.contains(movieId) {
            return Movie(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0)
        }
        return nil
    }

    func getFavoriteDetailsSync(movieId: Int) -> MovieDetails? {
        if ids.contains(movieId) {
            return MovieDetails(id: movieId, title: "t\(movieId)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, runtime: 100, genres: [], tagline: nil)
        }
        return nil
    }

    func isFavoriteSync(movieId: Int) -> Bool {
        return ids.contains(movieId)
    }
}

private final class RepoMock: MovieRepositoryProtocol {
    func fetchMovies(type: MovieType) async throws -> [Movie] { fatalError() }
    func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage { fatalError() }
    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage { fatalError() }
    func searchMovies(query: String) async throws -> [Movie] { fatalError() }
    func searchMovies(query: String, page: Int) async throws -> MoviePage { fatalError() }
    func fetchMovieDetails(id: Int) async throws -> MovieDetails {
        let details = MovieDetails(id: id, title: "Movie \(id)", overview: "Detailed overview for movie \(id)", posterPath: "/poster\(id).jpg", backdropPath: "/backdrop\(id).jpg", releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, runtime: 120, genres: [Genre(id: 28, name: "Action"), Genre(id: 12, name: "Adventure")], tagline: "An epic adventure")
        return details
    }
}

@MainActor
final class FavoritesViewModelTests: XCTestCase {
    func testReloadReflectsFavoritesAfterAdd() async throws {
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = FavoritesViewModel(favoritesStore: store)

        // Initially empty
        vm.reload()
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertTrue(vm.items.isEmpty)

        // Add favorite and reload
        store.addToFavorites(movie: Movie(id: 42, title: "t", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 1, voteCount: 1, genres: [], popularity: 0))
        vm.reload()
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(vm.items.map { $0.id }, [42])

        // Remove and reload
        store.removeFromFavorites(movieId: 42)
        vm.reload()
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertTrue(vm.items.isEmpty)
    }

    func testFavoritesStoreIsAccessibleForObservation() throws {
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = FavoritesViewModel(favoritesStore: store)

        // Verify ViewModel exposes store for View observation
        XCTAssertNotNil(vm.favoritesStore)
        XCTAssertTrue(vm.favoritesStore.favoriteMovieIds.isEmpty)
    }
}
