//
//  MovieDetailIntegrationTests.swift
//  MoviesDetailsTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
import SharedModels
@testable import MoviesDetails
@testable import MoviesDomain
@testable import MoviesNetwork
@testable import AppLog
@testable import MoviesData

private final class URLProtocolStub_Detail: URLProtocol {
    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) -> Response)?
    override class func canInit(with request: URLRequest) -> Bool {
        // Limit interception to TMDB host to avoid unrelated system requests
        (request.url?.host ?? "").contains("api.themoviedb.org")
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override class func canInit(with task: URLSessionTask) -> Bool { true }
    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let r = handler(request)
        let http = HTTPURLResponse(url: request.url!, statusCode: r.statusCode, httpVersion: nil, headerFields: r.headers)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: r.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { }
}

@MainActor
final class MovieDetailIntegrationTests: XCTestCase {
    private func makeRepository() -> MovieRepositoryProtocol {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub_Detail.self]
        let session = URLSession(configuration: config)
        let networkingConfig = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "TEST_KEY",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        let client = TMDBNetworkingClient(session: session, networkingConfig: networkingConfig)
        let remote = MovieRemoteDataSource(networkingClient: client)
        return MovieRepository(remoteDataSource: remote)
    }

    func testViewModelFetchesDetailsViaRepositoryStubbedByURLProtocol() {
        // Arrange network stub with a minimal TMDB details payload
        struct Payload: Codable {
            let id: Int; let title: String; let overview: String
            let poster_path: String?; let backdrop_path: String?
            let release_date: String; let vote_average: Double; let vote_count: Int
            let runtime: Int?; let genres: [Genre]
            struct Genre: Codable { let id: Int; let name: String }
        }

        let body = try! JSONEncoder().encode(Payload(
            id: 99, title: "X", overview: "O", poster_path: nil, backdrop_path: nil,
            release_date: "2020-01-01", vote_average: 7.0, vote_count: 10, runtime: nil,
            genres: []
        ))
        URLProtocolStub_Detail.requestHandler = { req in
            let path = req.url!.path
            XCTAssertTrue(path.contains("/3/movie/99"))
            return .init(statusCode: 200, headers: ["Content-Type": "application/json"], body: body)
        }

        let repo = makeRepository()
        let store = FavoritesStore(favoritesLocalDataSource: InMemoryFavoritesLocalDataSourceStub())
        let vm = MovieDetailViewModel(repository: repo, favoritesStore: store, movieId: 99)
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(vm.movie?.id, 99)
    }
}

// Minimal in-memory storage for deterministic favorites behavior
final class InMemoryFavoritesLocalDataSourceStub: @unchecked Sendable, FavoritesLocalDataSourceProtocol {
    private var ids = Set<Int>()
    func getFavoriteMovieIds() -> AnyPublisher<Set<Int>, Error> { Just(ids).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func addToFavorites(movie: Movie) -> AnyPublisher<Void, Error> { ids.insert(movie.id); return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func addToFavorites(details: MovieDetails) -> AnyPublisher<Void, Error> { ids.insert(details.id); return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func removeFromFavorites(movieId: Int) -> AnyPublisher<Void, Error> { ids.remove(movieId); return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func isFavorite(movieId: Int) -> AnyPublisher<Bool, Error> { Just(ids.contains(movieId)).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func getFavorites(page: Int, pageSize: Int, sortOrder: MovieSortOrder?) -> AnyPublisher<[Movie], Error> {
        let sorted = Array(ids).sorted()
        let start = max(page - 1, 0) * pageSize
        let end = min(start + pageSize, sorted.count)
        let slice = (start < end) ? Array(sorted[start..<end]) : []
        let movies = slice.map { id in Movie(id: id, title: "t\(id)", overview: "o", posterPath: nil, backdropPath: nil, releaseDate: "2023-01-01", voteAverage: 0, voteCount: 0, genres: [], popularity: 0) }
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


