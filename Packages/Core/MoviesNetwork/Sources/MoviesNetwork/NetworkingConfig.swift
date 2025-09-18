//
//  NetworkingConfig.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation

public struct NetworkingConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String
    public let imageBaseURL: URL

    public init(baseURL: URL, apiKey: String, imageBaseURL: URL) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.imageBaseURL = imageBaseURL
    }

    public var apiBaseURL: URL {
        baseURL.appendingPathComponent("3")
    }
}

public enum TMDBNetworkingConfig {
    /// Static configuration loaded once at module initialization
    public static let config: NetworkingConfig = {
        do {
            return try loadFromInfoPlist()
        } catch {
            fatalError("Failed to load TMDB configuration: \(error.localizedDescription)")
        }
    }()

    /// Load configuration from Info.plist
    public static func loadFromInfoPlist() throws -> NetworkingConfig {
        // Validate Info.plist exists
        guard let dict = Bundle.main.infoDictionary else {
            throw ConfigurationError.missingInfoPlist
        }

        // Validate TMDB configuration section
        guard let tmdb = dict["TMDBConfiguration"] as? [String: Any] else {
            throw ConfigurationError.missingConfigurationSection(
                "Missing 'TMDBConfiguration' in Info.plist. Add:\n" +
                "<key>TMDBConfiguration</key>\n<dict>...</dict>"
            )
        }

        // Validate and parse base URL
        guard let baseURLString = tmdb["TMDBBaseURL"] as? String, !baseURLString.isEmpty else {
            throw ConfigurationError.missingRequiredValue("TMDBBaseURL")
        }

        guard let baseURL = URL(string: baseURLString) else {
            throw ConfigurationError.invalidURLFormat("TMDBBaseURL", baseURLString)
        }

        // Validate and parse image base URL
        guard let imageBaseURLString = tmdb["TMDBImageBaseURL"] as? String, !imageBaseURLString.isEmpty else {
            throw ConfigurationError.missingRequiredValue("TMDBImageBaseURL")
        }

        guard let imageBaseURL = URL(string: imageBaseURLString) else {
            throw ConfigurationError.invalidURLFormat("TMDBImageBaseURL", imageBaseURLString)
        }

        // Validate API key
        guard let apiKey = tmdb["TMDBAPIKey"] as? String, !apiKey.isEmpty else {
            throw ConfigurationError.missingRequiredValue("TMDBAPIKey")
        }

        return NetworkingConfig(baseURL: baseURL, apiKey: apiKey, imageBaseURL: imageBaseURL)
    }
}

/// Errors for configuration loading from Info.plist
public enum ConfigurationError: LocalizedError {
    case missingInfoPlist
    case missingConfigurationSection(String)
    case missingRequiredValue(String)
    case invalidURLFormat(String, String)

    public var errorDescription: String? {
        switch self {
        case .missingInfoPlist:
            return "Info.plist not found"
        case .missingConfigurationSection(let message):
            return "Configuration error: \(message)"
        case .missingRequiredValue(let key):
            return "Missing \(key) in Info.plist"
        case .invalidURLFormat(let key, let value):
            return "Invalid \(key) URL: \(value)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingInfoPlist:
            return "Add Info.plist to your app"
        case .missingConfigurationSection:
            return "Add TMDBConfiguration to Info.plist"
        case .missingRequiredValue:
            return "Add the missing key to TMDBConfiguration"
        case .invalidURLFormat:
            return "Fix the URL format"
        }
    }
}
