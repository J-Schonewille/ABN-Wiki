import Foundation

/// Sends requests and turns every failure into a `NetworkError`. Only a 2xx status counts as success.
public struct HTTPClient: Sendable {
    /// Fails a request when no data arrives for this long.
    static let idleTimeout: TimeInterval = 15
    /// Fails a request that takes longer than this in total.
    static let resourceTimeout: TimeInterval = 30

    // Not private, so tests can check them.
    let session: URLSession
    let userAgent: String

    public init(session: URLSession, userAgent: String) {
        self.session = session
        self.userAgent = userAgent
    }

    /// A session without a cache, cookies or credentials, so every request reaches the server.
    public static func makeEphemeralSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil  // An ephemeral session still caches in memory.
        configuration.timeoutIntervalForResource = resourceTimeout
        return URLSession(configuration: configuration)
    }

    /// Sends `request` and returns the body and the response of a 2xx answer.
    public func data(for request: URLRequest) async throws(NetworkError) -> (Data, HTTPURLResponse) {
        var request = request
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = Self.idleTimeout

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let networkError = NetworkError(error)
            // -999 is only a cancellation when our task was cancelled. Otherwise, such as when certificate pinning
            // rejects the server, it's an error to show.
            if networkError == .cancelled, !Task.isCancelled {
                throw .transport(code: .cancelled)
            }
            throw networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw .server(statusCode: httpResponse.statusCode)
        }
        return (data, httpResponse)
    }
}
