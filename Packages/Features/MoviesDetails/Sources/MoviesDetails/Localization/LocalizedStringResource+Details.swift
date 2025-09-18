//
//  LocalizedStringResource+Details.swift
//  MoviesDetails
//
//  Created by User on 9/10/25.
//

import Foundation

public extension LocalizedStringResource {
    enum DetailsL10n {
        public static let notFound = LocalizedStringResource(
            "details.not_found",
            table: "Details",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let title = LocalizedStringResource(
            "details.title",
            table: "Details",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let releasedIn = LocalizedStringResource(
            "details.released_in",
            table: "Details",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let ratingOutOfTen = LocalizedStringResource(
            "details.rating_out_of_ten",
            table: "Details",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let voteCount = LocalizedStringResource(
            "details.vote_count",
            table: "Details",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
