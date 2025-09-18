//
//  KingfisherConfig.swift
//  MoviesDesignSystem
//
//  Created by User on 9/10/25.
//

import Kingfisher

/// Simple Kingfisher configuration for movie app
/// Call this once in your app's initialization
public struct KingfisherConfig {
    public static func configure() {
        // Basic cache configuration for movie images
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50MB
        ImageCache.default.diskStorage.config.sizeLimit = 200 * 1024 * 1024       // 200MB
        ImageCache.default.diskStorage.config.expiration = .days(7)

        // User-Agent to avoid bot detection
        ImageDownloader.default.sessionConfiguration.httpAdditionalHeaders = [
            "User-Agent": "MoviesApp/1.0 (iOS)"
        ]

        // Default options for all images
        ImageDownloader.default.downloadTimeout = 30
    }

    /// Clear all caches (useful for debugging)
    public static func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }
}
