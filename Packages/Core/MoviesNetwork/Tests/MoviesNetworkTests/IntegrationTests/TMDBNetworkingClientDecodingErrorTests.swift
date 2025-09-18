//
//  TMDBNetworkingClientDecodingErrorTests.swift
//  MoviesNetworkTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
@testable import MoviesNetwork

private final class URLProtocolStub_DecodeErr: URLProtocol {
    struct Response { let statusCode: Int; let headers: [String: String]; let body: Data }
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> Response)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override class func canInit(with task: URLSessionTask) -> Bool { true }
    override func startLoading() {
        guard let handler = Self.requestHandler else { return }
        do {
            let r = try handler(request)
            let http = HTTPURLResponse(url: request.url!, statusCode: r.statusCode, httpVersion: nil, headerFields: r.headers)!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: r.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() { }
}

private struct Dummy: Codable { let ok: Bool }
private struct TestEndpoint: EndpointProtocol { let path: String; var queryParameters: [URLQueryItem] }

final class TMDBNetworkingClientDecodingErrorTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func makeClient() -> TMDBNetworkingClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub_DecodeErr.self]
        let session = URLSession(configuration: config)
        let networkingConfig = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "TEST_KEY",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        return TMDBNetworkingClient(session: session, networkingConfig: networkingConfig)
    }

    func test_invalidJSON_emitsFailure() {
        let exp = expectation(description: "decoding failed")
        URLProtocolStub_DecodeErr.requestHandler = { _ in
            let bad = Data("{not json}".utf8)
            return .init(statusCode: 200, headers: ["Content-Type": "application/json"], body: bad)
        }
        let client = makeClient()
        let endpoint = TestEndpoint(path: "movie/1", queryParameters: [])
        client.request(endpoint)
            .sink(receiveCompletion: { c in
                if case .failure = c { exp.fulfill() }
            }, receiveValue: { (_: Dummy) in
                XCTFail("should not decode")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
}


