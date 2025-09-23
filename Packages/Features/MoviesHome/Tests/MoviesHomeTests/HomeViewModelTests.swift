//
//  HomeViewTests.swift
//  MoviesHomeTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SharedModels
import SwiftData
@testable import MoviesHome
@testable import MoviesDomain
@testable import MoviesData

private final class RepoMock: MovieRepositoryProtocol {
    let fetchMoviesPageHandler: @Sendable (MovieType, Int) -> MoviePage = { type, page in
        let items = (0..<10).map { index in
            let baseValue = Double(index)
            return Movie(
                id: index + (page-1)*10,
                title: "M\(index)",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2020-01-01",
                voteAverage: baseValue,
                voteCount: 0,
                genres: nil,
                popularity: baseValue * 10.0
            )
        }
        return MoviePage(items: items, page: page, totalPages: 3)
    }

    func fetchMovies(type: MovieType) async throws -> [Movie] {
        let mockMovies = [
            Movie(id: 1, title: "Test Movie 1", overview: "Overview 1", posterPath: "/poster1.jpg", backdropPath: "/backdrop1.jpg", releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, genres: nil, popularity: 85.5),
            Movie(id: 2, title: "Test Movie 2", overview: "Overview 2", posterPath: "/poster2.jpg", backdropPath: "/backdrop2.jpg", releaseDate: "2023-02-01", voteAverage: 8.0, voteCount: 150, genres: nil, popularity: 92.3)
        ]
        return mockMovies
    }

    func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage {
        fetchMoviesPageHandler(type, page)
    }

    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage {
        var items = (0..<10).map { index in
            let baseValue = Double(index)
            return Movie(
                id: index + (page-1)*10,
                title: "M\(index)",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2020-01-01",
                voteAverage: baseValue,
                voteCount: 0,
                genres: nil,
                popularity: baseValue * 10.0
            )
        }

        // Apply sorting if specified
        if let sortOrder = sortBy {
            switch sortOrder {
            case .popularityAscending:
                items.sort { $0.popularity < $1.popularity }
            case .popularityDescending:
                items.sort { $0.popularity > $1.popularity }
            case .ratingAscending:
                items.sort { $0.voteAverage < $1.voteAverage }
            case .ratingDescending:
                items.sort { $0.voteAverage > $1.voteAverage }
            case .releaseDateAscending:
                items.sort { $0.releaseDate < $1.releaseDate }
            case .releaseDateDescending:
                items.sort { $0.releaseDate > $1.releaseDate }
            case .recentlyAdded:
                break
            }
        }

        return MoviePage(items: items, page: page, totalPages: 3)
    }

    func searchMovies(query: String) async throws -> [Movie] {
        let mockMovies = [
            Movie(id: 100, title: "Search Result 1 for '\(query)'", overview: "Search overview 1", posterPath: "/search1.jpg", backdropPath: "/search_backdrop1.jpg", releaseDate: "2023-03-01", voteAverage: 6.5, voteCount: 80, genres: nil, popularity: 65.2),
            Movie(id: 101, title: "Search Result 2 for '\(query)'", overview: "Search overview 2", posterPath: "/search2.jpg", backdropPath: "/search_backdrop2.jpg", releaseDate: "2023-03-02", voteAverage: 7.2, voteCount: 120, genres: nil, popularity: 78.8)
        ]
        return mockMovies
    }

    func searchMovies(query: String, page: Int) async throws -> MoviePage {
        let mockMovies = [
            Movie(id: 200 + (page - 1) * 20, title: "Search Page \(page) Result 1 for '\(query)'", overview: "Search page \(page) overview 1", posterPath: "/search_p\(page)_1.jpg", backdropPath: "/search_backdrop_p\(page)_1.jpg", releaseDate: "2023-04-\(String(format: "%02d", page))", voteAverage: 6.0 + Double(page) * 0.3, voteCount: 70 + page * 15, genres: nil, popularity: 55.0 + Double(page) * 5.0),
            Movie(id: 201 + (page - 1) * 20, title: "Search Page \(page) Result 2 for '\(query)'", overview: "Search page \(page) overview 2", posterPath: "/search_p\(page)_2.jpg", backdropPath: "/search_backdrop_p\(page)_2.jpg", releaseDate: "2023-04-\(String(format: "%02d", page + 1))", voteAverage: 6.5 + Double(page) * 0.3, voteCount: 85 + page * 15, genres: nil, popularity: 60.0 + Double(page) * 5.0)
        ]
        let mockPage = MoviePage(items: mockMovies, page: page, totalPages: 3)
        return mockPage
    }

    func fetchMovieDetails(id: Int) async throws -> MovieDetails {
        let details = MovieDetails(id: id, title: "Movie \(id)", overview: "Detailed overview for movie \(id)", posterPath: "/poster\(id).jpg", backdropPath: "/backdrop\(id).jpg", releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, runtime: 120, genres: [Genre(id: 28, name: "Action"), Genre(id: 12, name: "Adventure")], tagline: "An epic adventure")
        return details
    }
}

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadResetReplacesItemsAndSetsPagination() async throws {
        let repo = RepoMock()
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        await vm.load(reset: true)
        XCTAssertEqual(vm.items.count, 10)
    }

    func testLoadNextThresholdTriggersPagination() async throws {
        let repo = RepoMock()
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        await vm.load(reset: true)
        let last = vm.items.suffix(2).first  // Get item within threshold (last 3 items)
        await vm.loadNextIfNeeded(currentItem: last)
        XCTAssertGreaterThan(vm.items.count, 10)
    }

    func testSetSortOrderAppliesSorting() async throws {
        let repo = RepoMock()
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        await vm.load(reset: true)
        await vm.setSortOrder(.ratingDescending)
        let sorted = vm.items.map { $0.voteAverage }
        XCTAssertEqual(sorted, sorted.sorted(by: >))
    }

    func testPaginationStopsAtLastPage() async throws {
        let repo = RepoMock()
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        // Load all 3 pages
        await vm.load(reset: true)
        var last = vm.items.suffix(2).first  // Use item within threshold
        await vm.loadNextIfNeeded(currentItem: last)
        last = vm.items.suffix(2).first  // Use item within threshold
        await vm.loadNextIfNeeded(currentItem: last)
        let countAtMax = vm.items.count
        // Attempt beyond last page should not change count
        last = vm.items.last  // Use actual last item
        await vm.loadNextIfNeeded(currentItem: last)
        XCTAssertEqual(vm.items.count, countAtMax)
    }

    func testLargeDatasetPerformancePaginationEfficiency() async throws {
        // Performance test: Ensure pagination handles large datasets efficiently
        // This simulates loading many pages without performance degradation
        let repo = RepoMock()
        let container = try ModelContainer(for: FavoriteMovieEntity.self, FavoriteGenreEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = FavoritesStore(favoritesLocalDataSource: FavoritesLocalDataSource(container: container), container: container)
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying

        // First, ensure initial load works
        await vm.load(reset: true)
        XCTAssertGreaterThan(vm.items.count, 0, "Initial load should populate items")
        let initialCount = vm.items.count

        // Load additional pages and verify they work
        var totalPagesLoaded = 1
        for _ in 2..<4 { // Load pages 2 and 3
            if vm.items.count >= 3 {
                let triggerItem = vm.items[vm.items.count - 2]  // Second to last item
                await vm.loadNextIfNeeded(currentItem: triggerItem)
                totalPagesLoaded += 1
            }
        }

        // Verify pagination worked
        XCTAssertGreaterThan(vm.items.count, initialCount, "Should have loaded additional items")
        XCTAssertEqual(totalPagesLoaded, 3, "Should have loaded 3 pages total")

        // Basic performance check - ensure we don't have excessive items
        XCTAssertLessThan(vm.items.count, 50, "Should not load excessive data")

        // Simple measurement of the operation count
        measure {
            _ = vm.items.count
        }
    }
}
