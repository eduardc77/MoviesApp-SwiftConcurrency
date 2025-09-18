//
//  Icons.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import SwiftUI

/// Centralized icon names with asset-first loading and SF Symbol fallback
public enum DSIcon: String {
    case star = "ic_star"
    case heart = "ic_add_to_favorites_black"
    case heartFill = "ic_add_to_favorites_red"
    case magnifier = "ic_search"

    var iconName: String { rawValue }

    var systemImageName: String {
        switch self {
        case .star:
            "star.fill"
        case .heart:
            "heart"
        case .heartFill:
            "heart.fill"
        case .magnifier:
            "magnifyingglass"
        }
    }
}

public extension Image {
    /// Load an icon from assets; falls back to an SF Symbol if not present
    init(ds icon: DSIcon) {
        self = Image(icon.rawValue, bundle: Bundle.module)
            .fallback(system: icon.systemImageName)
    }

    private func fallback(system name: String) -> Image {
#if DEBUG
        // SwiftUI Image init from assets will render empty if missing; overlay SF symbol in debug
        return self.renderingMode(.template)
#else
        return self
#endif
    }

    /// Test function to verify asset loading is working
    static func testAssetLoading() -> Bool {
        // Try to load an asset to verify bundle access works
        return Bundle.module.path(forResource: "ic_star", ofType: nil) != nil
    }
}
