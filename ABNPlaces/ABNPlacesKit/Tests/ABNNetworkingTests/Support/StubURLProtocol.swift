import Foundation
import Synchronization
import Testing

/// A `URLProtocol` that answers each request with the reply registered for its URL.
///
/// Swift Testing runs tests in parallel. With one shared reply, one test could overwrite another's, so each test
/// registers its reply under a URL of its own, and the registry is behind a `Mutex`.
final class StubURLProtocol: URLProtocol {
    enum Reply: Sendable {
        case http(statusCode: Int, body: Data = Data())
        /// A response that isn't an `HTTPURLResponse`.
        case nonHTTP
        case failure(URLError.Code)
        /// No answer until the task is cancelled. `onStart` runs once the request is in flight.
        case hang(onStart: @Sendable () -> Void)
    }

    /// A session that sends every request to this protocol.
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    private static let replies = Mutex<[URL: Reply]>([:])
    private static let receivedRequests = Mutex<[URL: URLRequest]>([:])

    /// Registers `reply` under a new, unique URL and returns that URL.
    static func register(_ reply: Reply) throws -> URL {
        let url = try #require(URL(string: "https://stub.test/\(UUID().uuidString)"))
        replies.withLock { $0[url] = reply }
        return url
    }

    /// The request for `url` as it reached the network, after `HTTPClient` and `URLSession` prepared it.
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
        Self.receivedRequests.withLock { $0[url] = request }

        switch reply {
        case .http(let statusCode, let body):
            guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .nonHTTP:
            let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case .hang(let onStart):
            onStart()
        }
    }

    override func stopLoading() {}
}
