//
//  LocalizedStringResource+Domain.swift
//  MoviesDomain
//
//  Created by User on 9/10/25.
//

import Foundation

public extension LocalizedStringResource {
    enum DomainL10n {
        public static let nowPlaying = LocalizedStringResource(
            "movietype.now_playing",
            table: "Domain",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let popular = LocalizedStringResource(
            "movietype.popular",
            table: "Domain",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let topRated = LocalizedStringResource(
            "movietype.top_rated",
            table: "Domain",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let upcoming = LocalizedStringResource(
            "movietype.upcoming",
            table: "Domain",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let popularityAscending = LocalizedStringResource("sort.popularity_asc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
        public static let popularityDescending = LocalizedStringResource("sort.popularity_desc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
        public static let ratingAscending = LocalizedStringResource("sort.rating_asc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
        public static let ratingDescending = LocalizedStringResource("sort.rating_desc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
        public static let releaseDateAscending = LocalizedStringResource("sort.release_asc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
        public static let releaseDateDescending = LocalizedStringResource("sort.release_desc", table: "Domain", bundle: .atURL(Bundle.module.bundleURL))
    }
}
