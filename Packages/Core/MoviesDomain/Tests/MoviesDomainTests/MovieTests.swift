//
//  MovieTests.swift
//  MoviesDomainTests
//
//  Created by User on 9/10/25.
//

import XCTest
@testable import MoviesDomain

final class MovieTests: XCTestCase {
    func testMovieInitialization() {
        let movie = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test overview",
            posterPath: "/test.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2023-01-01",
            voteAverage: 8.5,
            voteCount: 100,
            popularity: 75.5
        )

        XCTAssertEqual(movie.id, 1)
        XCTAssertEqual(movie.title, "Test Movie")
        XCTAssertEqual(movie.releaseYear, "2023")
    }

    func testMovieEquality() {
        let movie1 = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test overview",
            posterPath: "/test.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2023-01-01",
            voteAverage: 8.5,
            voteCount: 100,
            popularity: 75.5
        )

        let movie2 = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test overview",
            posterPath: "/test.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2023-01-01",
            voteAverage: 8.5,
            voteCount: 100,
            popularity: 75.5
        )

        XCTAssertEqual(movie1, movie2)
    }
}
