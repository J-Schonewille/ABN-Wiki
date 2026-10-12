import Foundation
import Synchronization
import Testing

/// A `URLProtocol` that answers each request with the HTTP reply registered for its URL.
///
/// Each test registers its reply under a URL of its own, so tests running in parallel never share a reply.
/// A smaller copy of the stub in ABNNetworkingTests: sharing one would need a test-support target.
final class StubURLProtocol: URLProtocol {
    struct Reply: Sendable {
        let statusCode: Int
        let body: Data
    }

    /// A session that sends every request to this protocol.
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    private static let replies = Mutex<[URL: Reply]>([:])
    private static let receivedRequests = Mutex<[URL: URLRequest]>([:])

    /// Registers a reply under a new, unique URL and returns that URL.
    static func register(statusCode: Int, body: Data) throws -> URL {
        let url = try #require(URL(string: "https://stub.test/\(UUID().uuidString)"))
        replies.withLock { $0[url] = Reply(statusCode: statusCode, body: body) }
        return url
    }

    /// The request for `url` as it reached the network.
    static func receivedRequest(for url: URL) -> URLRequest? {
        receivedRequests.withLock { $0[url] }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let reply = Self.replies.withLock({ $0[url] }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: reply.statusCode, httpVersion: nil, headerFields: nil)
        guard let response else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        Self.receivedRequests.withLock { $0[url] = request }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
