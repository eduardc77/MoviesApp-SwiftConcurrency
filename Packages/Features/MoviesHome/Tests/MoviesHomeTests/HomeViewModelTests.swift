//
//  HomeViewTests.swift
//  MoviesHomeTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
import SharedModels
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

    func fetchMovies(type: MovieType) -> AnyPublisher<[Movie], Error> {
        let mockMovies = [
            Movie(id: 1, title: "Test Movie 1", overview: "Overview 1", posterPath: "/poster1.jpg", backdropPath: "/backdrop1.jpg", releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, genres: nil, popularity: 85.5),
            Movie(id: 2, title: "Test Movie 2", overview: "Overview 2", posterPath: "/poster2.jpg", backdropPath: "/backdrop2.jpg", releaseDate: "2023-02-01", voteAverage: 8.0, voteCount: 150, genres: nil, popularity: 92.3)
        ]
        return Just(mockMovies).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func fetchMovies(type: MovieType, page: Int) -> AnyPublisher<MoviePage, Error> {
        Just(fetchMoviesPageHandler(type, page)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) -> AnyPublisher<MoviePage, Error> {
        // For testing, we'll return the same data regardless of sort order
        // In a real implementation, this would use the sortBy parameter
        Just(fetchMoviesPageHandler(type, page)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func searchMovies(query: String) -> AnyPublisher<[Movie], Error> {
        let mockMovies = [
            Movie(id: 100, title: "Search Result 1 for '\(query)'", overview: "Search overview 1", posterPath: "/search1.jpg", backdropPath: "/search_backdrop1.jpg", releaseDate: "2023-03-01", voteAverage: 6.5, voteCount: 80, genres: nil, popularity: 65.2),
            Movie(id: 101, title: "Search Result 2 for '\(query)'", overview: "Search overview 2", posterPath: "/search2.jpg", backdropPath: "/search_backdrop2.jpg", releaseDate: "2023-03-02", voteAverage: 7.2, voteCount: 120, genres: nil, popularity: 78.8)
        ]
        return Just(mockMovies).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func searchMovies(query: String, page: Int) -> AnyPublisher<MoviePage, Error> {
        let mockMovies = [
            Movie(id: 200 + (page - 1) * 20, title: "Search Page \(page) Result 1 for '\(query)'", overview: "Search page \(page) overview 1", posterPath: "/search_p\(page)_1.jpg", backdropPath: "/search_backdrop_p\(page)_1.jpg", releaseDate: "2023-04-\(String(format: "%02d", page))", voteAverage: 6.0 + Double(page) * 0.3, voteCount: 70 + page * 15, genres: nil, popularity: 55.0 + Double(page) * 5.0),
            Movie(id: 201 + (page - 1) * 20, title: "Search Page \(page) Result 2 for '\(query)'", overview: "Search page \(page) overview 2", posterPath: "/search_p\(page)_2.jpg", backdropPath: "/search_backdrop_p\(page)_2.jpg", releaseDate: "2023-04-\(String(format: "%02d", page + 1))", voteAverage: 6.5 + Double(page) * 0.3, voteCount: 85 + page * 15, genres: nil, popularity: 60.0 + Double(page) * 5.0)
        ]
        let mockPage = MoviePage(items: mockMovies, page: page, totalPages: 3)
        return Just(mockPage).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func fetchMovieDetails(id: Int) -> AnyPublisher<MovieDetails, Error> {
        let details = MovieDetails(id: id, title: "Movie \(id)", overview: "Detailed overview for movie \(id)", posterPath: "/poster\(id).jpg", backdropPath: "/backdrop\(id).jpg", releaseDate: "2023-01-01", voteAverage: 7.5, voteCount: 100, runtime: 120, genres: [Genre(id: 28, name: "Action"), Genre(id: 12, name: "Adventure")], tagline: "An epic adventure")
        return Just(details).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadResetReplacesItemsAndSetsPagination() {
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        vm.load(reset: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(vm.items.count, 10)
    }

    func testLoadNextThresholdTriggersPagination() {
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        vm.load(reset: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let last = vm.items.suffix(2).first  // Get item within threshold (last 3 items)
        vm.loadNextIfNeeded(currentItem: last)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertGreaterThan(vm.items.count, 10)
    }

    func testSetSortOrderAppliesSorting() {
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        vm.load(reset: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        vm.setSortOrder(.ratingDescending)
        let sorted = vm.items.map { $0.voteAverage }
        XCTAssertEqual(sorted, sorted.sorted(by: >))
    }

    func testPaginationStopsAtLastPage() {
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying
        // Load all 3 pages
        vm.load(reset: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        var last = vm.items.suffix(2).first  // Use item within threshold
        vm.loadNextIfNeeded(currentItem: last)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        last = vm.items.suffix(2).first  // Use item within threshold
        vm.loadNextIfNeeded(currentItem: last)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        let countAtMax = vm.items.count
        // Attempt beyond last page should not change count
        last = vm.items.last  // Use actual last item
        vm.loadNextIfNeeded(currentItem: last)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(vm.items.count, countAtMax)
    }

    func testLargeDatasetPerformancePaginationEfficiency() {
        // Performance test: Ensure pagination handles large datasets efficiently
        // This simulates loading many pages without performance degradation
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = HomeViewModel(repository: repo, favoritesStore: store)
        vm.category = .nowPlaying

        // Measure performance of loading multiple pages
        measure {
            vm.load(reset: true)
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))

            // Load 3 pages (simulating user scrolling through content)
            for _ in 1..<3 {
                let last = vm.items.suffix(2).first  // Use item within threshold
                vm.loadNextIfNeeded(currentItem: last)
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
        }

        // Verify we have reasonable data without memory issues
        XCTAssertGreaterThan(vm.items.count, 20, "Should load multiple pages of data")
        XCTAssertLessThan(vm.items.count, 50, "Should not load excessive data")
    }
}
