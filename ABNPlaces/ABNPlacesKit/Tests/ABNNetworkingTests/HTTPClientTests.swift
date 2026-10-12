import Foundation
import Testing

@testable import ABNNetworking

@Suite("HTTP client")
struct HTTPClientTests {
    static let userAgent = "HTTPClientTests/1.0"

    let httpClient = HTTPClient(session: StubURLProtocol.session, userAgent: Self.userAgent)

    // MARK: Status codes

    @Test("A 2xx status returns the body and the response", arguments: [200, 204, 299])
    func returnsBodyAndResponseForSuccessStatus(_ statusCode: Int) async throws {
        let body = Data(#"{"ok":true}"#.utf8)
        let url = try StubURLProtocol.register(.http(statusCode: statusCode, body: body))

        let (data, response) = try await httpClient.data(for: URLRequest(url: url))

        #expect(data == body)
        #expect(response.statusCode == statusCode)
    }

    @Test("A status outside 200...299 throws .server with that status", arguments: [199, 300, 404, 500])
    func throwsServerErrorOutside2xx(_ statusCode: Int) async throws {
        let url = try StubURLProtocol.register(.http(statusCode: statusCode))

        await #expect(throws: NetworkError.server(statusCode: statusCode)) {
            try await httpClient.data(for: URLRequest(url: url))
        }
    }

    @Test("A response that isn't HTTP throws .invalidResponse")
    func throwsInvalidResponseForNonHTTPResponse() async throws {
        let url = try StubURLProtocol.register(.nonHTTP)

        await #expect(throws: NetworkError.invalidResponse) {
            try await httpClient.data(for: URLRequest(url: url))
        }
    }

    // MARK: Connection failures

    struct TransportCase: Sendable, CustomTestStringConvertible {
        let code: URLError.Code
        let expected: NetworkError

        var testDescription: String { "URLError \(code.rawValue) → \(expected)" }
    }

    static let transportCases: [TransportCase] = [
        // The device can't reach the server, so the screen says it can't connect, instead of blaming the server.
        TransportCase(code: .notConnectedToInternet, expected: .offline),
        TransportCase(code: .networkConnectionLost, expected: .offline),
        TransportCase(code: .dataNotAllowed, expected: .offline),
        TransportCase(code: .internationalRoamingOff, expected: .offline),
        TransportCase(code: .callIsActive, expected: .offline),
        TransportCase(code: .cannotFindHost, expected: .offline),
        TransportCase(code: .dnsLookupFailed, expected: .offline),
        TransportCase(code: .cannotConnectToHost, expected: .offline),
        TransportCase(code: .timedOut, expected: .timedOut),
        // -999 while nobody cancelled the task: certificate pinning rejected the server, or the session was shut down.
        TransportCase(code: .cancelled, expected: .transport(code: .cancelled)),
        // TLS failures: the device did reach a server, so it isn't offline.
        TransportCase(code: .secureConnectionFailed, expected: .transport(code: .secureConnectionFailed)),
        TransportCase(code: .serverCertificateUntrusted, expected: .transport(code: .serverCertificateUntrusted)),
        TransportCase(code: .serverCertificateHasBadDate, expected: .transport(code: .serverCertificateHasBadDate)),
    ]

    @Test("Each URLError becomes the network error it means", arguments: transportCases)
    func mapsTransportFailure(_ transportCase: TransportCase) async throws {
        let url = try StubURLProtocol.register(.failure(transportCase.code))

        await #expect(throws: transportCase.expected) {
            try await httpClient.data(for: URLRequest(url: url))
        }
    }

    @Test("Cancelling the task while the request is in flight throws .cancelled", .timeLimit(.minutes(1)))
    func cancellingTheTaskThrowsCancelled() async throws {
        let (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)
        let url = try StubURLProtocol.register(.hang(onStart: { startedContinuation.yield() }))
        let httpClient = httpClient
        let request = Task { _ = try await httpClient.data(for: URLRequest(url: url)) }

        // Cancel once the request is in flight, like someone leaving the screen while it loads.
        _ = await started.first { _ in true }
        request.cancel()

        await #expect(throws: NetworkError.cancelled) {
            try await request.value
        }
    }

    // MARK: Session and request settings

    @Test("The ephemeral session keeps no cache, cookies or credentials")
    func ephemeralSessionKeepsNoCacheCookiesOrCredentials() {
        let configuration = HTTPClient.makeEphemeralSession().configuration

        #expect(configuration.urlCache == nil)
        #expect(configuration.httpCookieStorage !== HTTPCookieStorage.shared)
        #expect(configuration.urlCredentialStorage !== URLCredentialStorage.shared)
    }

    @Test("The ephemeral session stops a request after 30 seconds in total")
    func ephemeralSessionLimitsARequestsTotalTime() {
        let configuration = HTTPClient.makeEphemeralSession().configuration

        #expect(configuration.timeoutIntervalForResource == 30)
    }

    @Test("Every request has the User-Agent and the 15-second idle timeout")
    func sendsUserAgentAndIdleTimeout() async throws {
        let url = try StubURLProtocol.register(.http(statusCode: 200))

        _ = try await httpClient.data(for: URLRequest(url: url))

        let sentRequest = try #require(StubURLProtocol.receivedRequest(for: url))
        #expect(sentRequest.value(forHTTPHeaderField: "User-Agent") == Self.userAgent)
        #expect(sentRequest.timeoutInterval == 15)
    }
}
