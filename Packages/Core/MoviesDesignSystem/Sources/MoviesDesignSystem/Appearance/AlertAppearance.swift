//
//  AlertAppearance.swift
//  MoviesDesignSystem
//
//  Created by User on 9/12/25.
//

#if canImport(UIKit)
import UIKit
#endif

/// Centralized UIAppearance configuration for UIAlertController (used by confirmation dialogs)
public enum AlertAppearance {
    /// Configure global appearance for UIAlertController (confirmation dialogs, alerts)
    @MainActor public static func configure() {
        #if canImport(UIKit)

        // MARK: Alert Action Buttons
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .label

        #else
        // No-op on non-UIKit platforms (e.g., macOS when running SwiftPM tests)
        #endif
    }
}
