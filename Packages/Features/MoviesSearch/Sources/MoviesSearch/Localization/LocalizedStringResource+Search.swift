//
//  LocalizedStringResource+Search.swift
//  MoviesSearch
//
//  Created by User on 9/10/25.
//

import Foundation

public extension LocalizedStringResource {
    enum SearchL10n {
        public static let title = LocalizedStringResource("search.title", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
        public static let emptyTitle = LocalizedStringResource("search.empty_title", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
        public static let emptyDescription = LocalizedStringResource("search.empty_description", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
        public static let noResultsDescription = LocalizedStringResource("search.no_results_description", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
        public static let errorTitle = LocalizedStringResource("search.error_title", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
        public static let searchPrompt = LocalizedStringResource("search.prompt", table: "Search", bundle: .atURL(Bundle.module.bundleURL))
    }
}
