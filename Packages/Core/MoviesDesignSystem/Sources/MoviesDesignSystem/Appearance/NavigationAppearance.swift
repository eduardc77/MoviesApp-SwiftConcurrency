//
//  NavigationAppearance.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

#if canImport(UIKit)
import UIKit
#endif

/// Centralized UIAppearance configuration for NavigationBar and TabBar
public enum NavigationAppearance {
    /// Configure global appearance for NavigationBar, TabBar
    @MainActor public static func configure() {
        #if canImport(UIKit)
        // MARK: Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .black
        navAppearance.shadowColor = .clear
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navAppearance.backButtonAppearance = backButtonAppearance
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navAppearance
        navBar.scrollEdgeAppearance = navAppearance
        navBar.compactAppearance = navAppearance
        navBar.tintColor = .white // Back button chevron and bar button items
        navBar.barTintColor = .white
        navBar.barStyle = .black

        // MARK: Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .black
        tabAppearance.shadowColor = .clear

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = .white
        #else
        // No-op on non-UIKit platforms (e.g., macOS when running SwiftPM tests)
        #endif
    }
}
