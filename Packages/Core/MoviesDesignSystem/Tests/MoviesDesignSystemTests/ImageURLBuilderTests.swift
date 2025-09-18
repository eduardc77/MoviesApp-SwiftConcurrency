//
//  ImageURLBuilderTests.swift
//  MoviesDesignSystem
//
//  Created by User on 9/15/25.
//

import XCTest
@testable import MoviesDesignSystem
@testable import MoviesNetwork

final class ImageURLBuilderTests: XCTestCase {
    func testPosterURLBuilder() {
        let config = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "key",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        let url = ImageURLBuilder.posterURL(posterPath: "/test.jpg", config: config, size: .medium)
        XCTAssertEqual(url, URL(string: "https://image.tmdb.org/t/p/w500/test.jpg"))
    }

    func testBackdropURLBuilder() {
        let config = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "key",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        let url = ImageURLBuilder.backdropURL(backdropPath: "/backdrop.jpg", config: config, size: .large)
        XCTAssertEqual(url, URL(string: "https://image.tmdb.org/t/p/w780/backdrop.jpg"))
    }
}
