//
//  LocalizedStringResource+DesignSystem.swift
//  MoviesDesignSystem
//
//  Created by User on 9/11/25.
//
//  Shared, reusable localized strings for UI elements across modules
//

import Foundation

public extension LocalizedStringResource {
    enum DesignSystemL10n {
        public static let loading = LocalizedStringResource(
            "ds.loading",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let loadingMore = LocalizedStringResource(
            "ds.loading_more",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let none = LocalizedStringResource(
            "ds.none",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let retry = LocalizedStringResource(
            "ds.retry",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let cancel = LocalizedStringResource(
            "ds.cancel",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let sortTitle = LocalizedStringResource(
            "ds.sort_title",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let searchPlaceholder = LocalizedStringResource(
            "ds.search_placeholder",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
        public static let searchClearA11y = LocalizedStringResource(
            "ds.search_clear_a11y",
            table: "DesignSystem",
            bundle: .atURL(Bundle.module.bundleURL)
        )
    }
}
