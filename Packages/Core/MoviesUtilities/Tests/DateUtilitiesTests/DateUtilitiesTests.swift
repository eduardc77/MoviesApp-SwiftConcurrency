//
//  DateUtilitiesTests.swift
//  DateUtilitiesTests
//
//  Created by User on 9/15/25.
//

import XCTest
@testable import DateUtilities

final class DateUtilitiesTests: XCTestCase {

    func testYearExtractionFromValidISODate() {
        let dateString = "2023-12-25"
        let year = MovieDateFormatter.year(from: dateString)
        XCTAssertEqual(year, "2023")
    }

    func testYearExtractionFromInvalidDate() {
        let dateString = "invalid-date"
        let year = MovieDateFormatter.year(from: dateString)
        XCTAssertEqual(year, "")
    }

    func testYearExtractionFromPartialDate() {
        let dateString = "2023"
        let year = MovieDateFormatter.year(from: dateString)
        XCTAssertEqual(year, "2023")
    }

    func testYearExtractionFallback() {
        let dateString = "2023-12-25T10:30:00Z"  // Full ISO with time
        let year = MovieDateFormatter.year(from: dateString)
        XCTAssertEqual(year, "2023")
    }

    func testDisplayDate() {
        let dateString = "2023-12-25"
        let displayDate = MovieDateFormatter.displayDate(from: dateString)
        // This will vary by locale, but should contain "2023"
        XCTAssertTrue(displayDate.contains("2023"))
    }

    func testFutureDate() {
        let futureDate = "2030-01-01"
        let isFuture = MovieDateFormatter.isFutureDate(futureDate)
        XCTAssertTrue(isFuture)

        let pastDate = "2020-01-01"
        let isPast = MovieDateFormatter.isFutureDate(pastDate)
        XCTAssertFalse(isPast)
    }

    func testYearExtractionEdgeCases() {
        // Test various edge cases for year extraction
        XCTAssertEqual(MovieDateFormatter.year(from: "2023"), "2023")
        XCTAssertEqual(MovieDateFormatter.year(from: "2023-12"), "2023")
        XCTAssertEqual(MovieDateFormatter.year(from: "2023-12-25"), "2023")
        XCTAssertEqual(MovieDateFormatter.year(from: "invalid"), "")
        XCTAssertEqual(MovieDateFormatter.year(from: "99"), "") // Invalid year (too short)
        XCTAssertEqual(MovieDateFormatter.year(from: "12345"), "") // Invalid year (too long)
        XCTAssertEqual(MovieDateFormatter.year(from: ""), "")
    }
}
