//
//  TMDBNetworkingClient.swift
//  MoviesNetwork
//
//  Created by User on 9/10/25.
//

import Foundation
import AppLog

/// HTTP client for TMDB API operations
public final class TMDBNetworkingClient: TMDBNetworkingClientProtocol, Sendable {
    private let session: URLSession
    private let networkingConfig: NetworkingConfig
    private let decoder: JSONDecoder

    public init(session: URLSession = TMDBNetworkingClient.configuredSession(), networkingConfig: NetworkingConfig) {
        self.session = session
        self.networkingConfig = networkingConfig

        // Configure decoder for TMDB API
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public func request<T: Decodable>(_ endpoint: EndpointProtocol) async throws -> T {
        guard let url = buildURL(for: endpoint) else {
            throw TMDBNetworkingError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.httpBody = endpoint.body

        // Set default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add endpoint-specific headers
        for (key, value) in endpoint.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw TMDBNetworkingError.httpError(httpResponse.statusCode)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch let decodingError as DecodingError {
                // Log detailed decoding failure information
                logDecodingFailure(decodingError, rawData: data, endpoint: endpoint)
                throw TMDBNetworkingError.decodingError(decodingError)
            } catch {
                // Log other decoding errors
                AppLog.network.error("Unexpected decoding error for \(endpoint.path): \(error.localizedDescription)")
                throw TMDBNetworkingError.networkError(error)
            }
        } catch let error as TMDBNetworkingError {
            throw error
        } catch {
            // Handle network errors and retry logic
            if shouldRetry(error) {
                AppLog.network.log("Retrying request after error: \(error.localizedDescription)")
                try await Task.sleep(for: .seconds(1))
                return try await request(endpoint)
            }
            throw TMDBNetworkingError.networkError(error)
        }
    }

    // MARK: - Convenience session factory
    public static func configuredSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }

    private func buildURL(for endpoint: EndpointProtocol) -> URL? {
        var components = URLComponents()
        components.scheme = networkingConfig.baseURL.scheme
        components.host = networkingConfig.baseURL.host
        components.path = networkingConfig.apiBaseURL.appendingPathComponent(endpoint.path).path

        var queryItems = endpoint.queryParameters
        queryItems.append(URLQueryItem(name: "api_key", value: networkingConfig.apiKey))

        components.queryItems = queryItems

        return components.url
    }

    private func shouldRetry(_ error: Error) -> Bool {
        switch error {
        case let networkError as TMDBNetworkingError:
            switch networkError {
            case .networkError: return true   // Network connectivity issues
            case .httpError(let code):
                return (500...599).contains(code)  // Server errors (5xx)
            case .invalidURL, .decodingError: return false  // Client errors, don't retry
            }
        case let urlError as URLError:
            switch urlError.code {
            case .timedOut,
                    .cannotConnectToHost,
                    .networkConnectionLost,
                    .notConnectedToInternet,
                    .cannotFindHost,
                    .dnsLookupFailed:
                return true  // Network connectivity issues that should be retried
            default:
                return false  // Other URL errors (400, 401, etc.) don't retry
            }
        default:
            return false  // Unknown errors, don't retry
        }
    }

    // MARK: - Logging Helpers

    private func logDecodingFailure(_ error: DecodingError, rawData: Data, endpoint: EndpointProtocol) {
        // Log the endpoint and error type
        AppLog.network.error("Decoding failed for endpoint: \(endpoint.path)")
        AppLog.network.error("Error type: \(error.localizedDescription)")

        // Try to parse raw JSON to extract useful information
        if let jsonString = String(data: rawData, encoding: .utf8) {
            AppLog.network.debug("Raw JSON response: \(jsonString)")

            // Try to extract movie information if this looks like movie data
            if endpoint.path.contains("/movie/") || endpoint.path.contains("/discover/movie") || endpoint.path.contains("/search/movie") {
                extractMovieInfoFromRawJSON(jsonString)
            }
        } else {
            AppLog.network.error("Could not convert raw data to string")
        }

        // Log specific decoding error details
        switch error {
        case .keyNotFound(let key, let context):
            AppLog.network.error("Missing key: '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            if let debugDescription = context.debugDescription.components(separatedBy: "No value associated").first {
                AppLog.network.error("Context: \(debugDescription.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        case .typeMismatch(let type, let context):
            AppLog.network.error("Type mismatch for key '\(context.codingPath.last?.stringValue ?? "unknown")'. Expected \(type), found different type at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .valueNotFound(let type, let context):
            AppLog.network.error("Value not found for key '\(context.codingPath.last?.stringValue ?? "unknown")'. Expected \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .dataCorrupted(let context):
            AppLog.network.error("Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: ".")): \(context.debugDescription)")
        @unknown default:
            AppLog.network.error("Unknown decoding error: \(error)")
        }
    }

    private func extractMovieInfoFromRawJSON(_ jsonString: String) {
        // Try to parse as JSON to extract basic movie info
        if let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {

            // Single movie object
            if let id = json["id"] as? Int {
                AppLog.network.info("Movie ID: \(id)")
            }
            if let title = json["title"] as? String {
                AppLog.network.info("Movie Title: \(title)")
            }
            if let overview = json["overview"] as? String, !overview.isEmpty {
                AppLog.network.info("Has overview: \(overview.count > 50 ? "Yes (\(overview.count) chars)" : "Yes (short)")")
            } else {
                AppLog.network.warning("Missing or empty overview")
            }
            if let releaseDate = json["release_date"] as? String {
                AppLog.network.info("Release date: \(releaseDate)")
            } else {
                AppLog.network.warning("Missing release_date")
            }
            if let posterPath = json["poster_path"] as? String {
                AppLog.network.info("Has poster: \(posterPath)")
            } else {
                AppLog.network.warning("Missing poster_path")
            }

        } else if let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] {

            // Movies list response
            AppLog.network.info("Movies response with \(results.count) results")
            for (index, movie) in results.enumerated() {
                if let id = movie["id"] as? Int {
                    AppLog.network.debug("Movie \(index + 1) - ID: \(id)")
                }
                if let title = movie["title"] as? String {
                    AppLog.network.debug("Movie \(index + 1) - Title: \(title)")
                }

                // Check for missing required fields
                if movie["title"] == nil || (movie["title"] as? String)?.isEmpty == true {
                    AppLog.network.error("Movie \(index + 1) missing title")
                }
                if movie["overview"] == nil {
                    AppLog.network.error("Movie \(index + 1) missing overview")
                }
                if movie["release_date"] == nil || (movie["release_date"] as? String)?.isEmpty == true {
                    AppLog.network.error("Movie \(index + 1) missing release_date")
                }
            }
        }
    }
}
