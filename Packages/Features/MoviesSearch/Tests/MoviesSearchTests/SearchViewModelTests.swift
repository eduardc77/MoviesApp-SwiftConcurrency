//
//  SearchViewTests.swift
//  MoviesSearchTests
//
//  Created by User on 9/10/25.
//

import XCTest
import SharedModels
@testable import MoviesSearch
@testable import MoviesDomain
@testable import MoviesData

private final class RepoMock: MovieRepositoryProtocol {
    func fetchMovies(type: MovieType) async throws -> [Movie] { fatalError() }
    func fetchMovies(type: MovieType, page: Int) async throws -> MoviePage { fatalError() }
    func fetchMovies(type: MovieType, page: Int, sortBy: MovieSortOrder?) async throws -> MoviePage { fatalError() }
    func searchMovies(query: String) async throws -> [Movie] { fatalError() }
    func searchMovies(query: String, page: Int) async throws -> MoviePage {
        let mockMovies = (0..<5).map { index in
            let movieId = 200 + (page - 1) * 20 + index
            let title = "Search Page \(page) Result \(index + 1) for '\(query)'"
            let overview = "Search page \(page) overview \(index + 1)"
            let posterPath = "/search_p\(page)_\(index + 1).jpg"
            let backdropPath = "/search_backdrop_p\(page)_\(index + 1).jpg"
            let releaseDate = "2023-04-01"
            let baseRating = 6.0 + Double(page) * 0.3 + Double(index) * 0.1
            let voteCount = 70 + page * 15 + index * 5
            let popularity = 50.0 + Double(page) * 5.0 + Double(index) * 2.0

            return Movie(
                id: movieId,
                title: title,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: releaseDate,
                voteAverage: baseRating,
                voteCount: voteCount,
                genres: nil,
                popularity: popularity
            )
        }
        let mockPage = MoviePage(items: mockMovies, page: page, totalPages: 3)
        return mockPage
    }
    func fetchMovieDetails(id: Int) async throws -> MovieDetails { fatalError() }
}

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testSearchPaginatesAndGuardsMinLength() async throws {
        let repo = RepoMock()
        let store = FavoritesStore()
        let vm = SearchViewModel(repository: repo, favoritesStore: store)

        await vm.search(reset: true, trigger: .submit) // query empty -> should no-op
        XCTAssertTrue(vm.items.isEmpty)

        vm.query = "abc"
        await vm.search(reset: true, trigger: .submit)
        XCTAssertEqual(vm.items.count, 5)

        await vm.loadNextIfNeeded(currentItem: vm.items.last)
        XCTAssertGreaterThan(vm.items.count, 5)
    }
}
