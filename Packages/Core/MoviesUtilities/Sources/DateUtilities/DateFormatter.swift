//
//  DateFormatter.swift
//  DateUtilities
//
//  Created by User on 9/15/25.
//

import Foundation

/// Centralized date formatting utilities for the Movies app
public enum MovieDateFormatter {

    /// Extract year from a date string in format yyyy-MM-dd (TMDB)
    /// - Parameter dateString: TMDB formatted date string
    /// - Returns: Year as string, or empty string if parsing fails
    public static func year(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            // Fallback: try to extract year from string format (YYYY-MM-DD)
            let components = dateString.split(separator: "-")
            if components.count >= 1, let year = components.first,
               year.count == 4, year.allSatisfy(\.isNumber) {
                return String(year)
            }
            return ""
        }

        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return String(year)
    }

    /// Format a date string for display (e.g., "2023-12-25" -> "Dec 25, 2023")
    /// - Parameter dateString: TMDB formatted date string (yyyy-MM-dd)
    /// - Returns: Formatted date string for display, or original string if parsing fails
    public static func displayDate(from dateString: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.calendar = Calendar(identifier: .iso8601)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }

    /// Check if a date string represents a future date
    /// - Parameter dateString: TMDB formatted date string (yyyy-MM-dd)
    /// - Returns: True if the date is in the future
    public static func isFutureDate(_ dateString: String) -> Bool {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.calendar = Calendar(identifier: .iso8601)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else {
            return false
        }
        return date > Date()
    }
}
