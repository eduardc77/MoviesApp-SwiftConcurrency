//
//  TMDBNetworkingClientTests.swift
//  MoviesNetworkTests
//
//  Created by User on 9/10/25.
//

import XCTest
import Combine
@testable import MoviesNetwork

private final class URLProtocolStub: URLProtocol {
    struct Response {
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> Response)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override class func canInit(with task: URLSessionTask) -> Bool { true }

    override func startLoading() {
        guard let handler = URLProtocolStub.requestHandler else { return }
        do {
            let response = try handler(request)
            let httpResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: response.headers
            )!
            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}

private struct DummyDecodable: Codable, Equatable { let ok: Bool }

private struct TestEndpoint: EndpointProtocol {
    let path: String
    var queryParameters: [URLQueryItem]
}

final class TMDBNetworkingClientTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        cancellables.removeAll()
        super.tearDown()
    }

    private func skipIfUnsupported() throws {
        #if os(macOS)
        throw XCTSkip("Skipping URLProtocol-based client tests on macOS SwiftPM runner")
        #endif
    }

    private func makeClient() -> TMDBNetworkingClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: config)
        let networkingConfig = NetworkingConfig(
            baseURL: URL(string: "https://api.themoviedb.org")!,
            apiKey: "TEST_KEY",
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        )
        return TMDBNetworkingClient(session: session, networkingConfig: networkingConfig)
    }

    func test_buildsURL_withPathQueryAndApiKey() throws {
        try skipIfUnsupported()
        let exp = expectation(description: "request sent")
        URLProtocolStub.requestHandler = { request in
            let comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            XCTAssertEqual(comps.path, "/3/movie/123")
            let items = comps.queryItems ?? []
            XCTAssertTrue(items.contains(URLQueryItem(name: "q", value: "a")))
            XCTAssertTrue(items.contains { $0.name == "api_key" && $0.value == "TEST_KEY" })
            exp.fulfill()
            let body = try JSONEncoder().encode(DummyDecodable(ok: true))
            return .init(statusCode: 200, headers: ["Content-Type": "application/json"], body: body)
        }

        let client = makeClient()
        let endpoint = TestEndpoint(path: "movie/123", queryParameters: [URLQueryItem(name: "q", value: "a")])

        client.request(endpoint)
            .sink(receiveCompletion: { _ in }, receiveValue: { (value: DummyDecodable) in })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_mapsNon2xxToHttpError() throws {
        try skipIfUnsupported()
        let exp = expectation(description: "error mapped")
        URLProtocolStub.requestHandler = { request in
            return .init(statusCode: 404, headers: [:], body: Data("{}".utf8))
        }

        let client = makeClient()
        let endpoint = TestEndpoint(path: "movie/404", queryParameters: [])

        client.request(endpoint)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion, let e = error as? TMDBNetworkingError {
                    if case .httpError(404) = e { exp.fulfill() }
                }
            }, receiveValue: { (value: DummyDecodable) in
                XCTFail("should not succeed")
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func test_decodesValidPayload() throws {
        try skipIfUnsupported()
        let exp = expectation(description: "decoded")
        URLProtocolStub.requestHandler = { _ in
            let body = try JSONEncoder().encode(DummyDecodable(ok: true))
            return .init(statusCode: 200, headers: ["Content-Type": "application/json"], body: body)
        }

        let client = makeClient()
        let endpoint = TestEndpoint(path: "ok", queryParameters: [])

        client.request(endpoint)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion { XCTFail("\(error)") }
            }, receiveValue: { (value: DummyDecodable) in
                XCTAssertEqual(value, DummyDecodable(ok: true))
                exp.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
}


