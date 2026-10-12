import Dependencies
import Foundation
import Testing

@testable import ABNNetworking
@testable import ABNPlacesCore

@Suite("Locations client")
struct LocationsClientTests {
    // MARK: The live client, with a fake connection

    /// The real HTTPClient, decoding and mapping. Only the connection is fake.
    @Test("The live client fetches the feed and turns it into places")
    func liveClientFetchesAndMapsTheFeed() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: FeedFixture.data())

        let places = try await Self.liveClient(url: url).fetch()

        #expect(places == (try FeedFixture.places()))
        let request = try #require(StubURLProtocol.receivedRequest(for: url))
        #expect(request.httpMethod == "GET")
    }

    @Test("The live client skips invalid entries")
    func liveClientSkipsInvalidEntries() async throws {
        let body = #"{"locations":[{"name":"Amsterdam","lat":52.3547498,"long":4.8339215},{"name":"Nowhere"}]}"#
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(body.utf8))

        #expect(try await Self.liveClient(url: url).fetch() == [try FeedFixture.amsterdam()])
    }

    @Test("A status outside 2xx is a server failure")
    func liveClientThrowsServerForNon2xx() async throws {
        let url = try StubURLProtocol.register(statusCode: 503, body: Data())

        await #expect(throws: LocationsError.server) {
            try await Self.liveClient(url: url).fetch()
        }
    }

    @Test("A different payload is unexpected data")
    func liveClientThrowsUnexpectedDataForADifferentPayload() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(#"{"places":[]}"#.utf8))

        await #expect(throws: LocationsError.unexpectedData) {
            try await Self.liveClient(url: url).fetch()
        }
    }

    // MARK: Errors

    /// Every network error becomes a cause a screen can explain, and only a cancelled caller is `.cancelled`.
    @Test(
        "Each network error becomes the cause a screen explains",
        arguments: [
            (NetworkError.offline, LocationsError.offline),
            (.timedOut, .server),
            (.server(statusCode: 503), .server),
            (.invalidResponse, .server),
            (.transport(code: .secureConnectionFailed), .server),
            (.transport(code: .cancelled), .server),
            (.decoding, .unexpectedData),
            (.cancelled, .cancelled),
        ]
    )
    func mapsEachNetworkErrorToTheCauseAScreenExplains(_ error: NetworkError, expected: LocationsError) {
        #expect(LocationsError(error) == expected)
    }

    // MARK: Live and test values

    @Test("The feed URL is the assignment's locations.json")
    func feedURLIsTheAssignmentsLocationsJSON() {
        let expected = "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json"

        #expect(LocationsClient.feedURL.absoluteString == expected)
    }

    @Test("The live client uses a session without a cache, and the app's User-Agent")
    func liveClientUsesSessionWithoutCacheAndTheAppsUserAgent() {
        let httpClient = LocationsClient.liveHTTPClient

        #expect(httpClient.session.configuration.urlCache == nil)
        #expect(httpClient.userAgent == LocationsClient.userAgent)
        #expect(LocationsClient.userAgent.hasPrefix("ABNPlaces"))
    }

    @Test("The User-Agent is the app's name and version")
    func userAgentIsTheAppsNameAndVersion() {
        #expect(LocationsClient.makeUserAgent(appVersion: "1.2") == "ABNPlaces/1.2")
        #expect(LocationsClient.makeUserAgent(appVersion: nil) == "ABNPlaces")
    }

    /// `@DependencyClient` writes the unimplemented `fetch`. The test checks the exact message, so it fails if the
    /// call reports nothing, or something else.
    @Test("The test value reports an unimplemented fetch, then throws")
    func testValueReportsUnimplementedAndThrows() async {
        var thrownError: LocationsError?

        await withKnownIssue("LocationsClient.testValue is unimplemented on purpose") {
            do throws(LocationsError) {
                _ = try await LocationsClient.testValue.fetch()
            } catch {
                thrownError = error
            }
        } matching: { issue in
            issue.comments.map(\.rawValue) == ["Unimplemented: 'LocationsClient.fetch'"]
        }

        #expect(thrownError == .server)
    }

    // MARK: Canned clients

    @Test("The preview client returns the real feed's four places")
    func previewReturnsTheRealFeedsPlaces() async throws {
        let feedPlaces = try FeedFixture.places()

        #expect([Place].preview == feedPlaces)
        #expect(try await LocationsClient.preview.fetch() == feedPlaces)
        #expect(try await LocationsClient.previewValue.fetch() == feedPlaces)
    }

    @Test("The empty client returns no places")
    func emptyReturnsNoPlaces() async throws {
        #expect(try await LocationsClient.empty.fetch().isEmpty)
    }

    @Test(
        "The failing client throws the error it was given",
        arguments: [LocationsError.offline, .server, .unexpectedData]
    )
    func failingThrowsTheGivenError(_ error: LocationsError) async {
        await #expect(throws: error) {
            try await LocationsClient.failing(error).fetch()
        }
    }

    enum NeverOutcome: Equatable, Sendable {
        case returned
        case threw(LocationsError)
        case stillWaiting
    }

    @Test("The never client waits until it's cancelled, then throws .cancelled", .timeLimit(.minutes(1)))
    func neverWaitsUntilCancelled() async {
        let outcomes = await withTaskGroup(of: NeverOutcome.self) { group in
            group.addTask {
                do throws(LocationsError) {
                    _ = try await LocationsClient.never.fetch()
                    return .returned
                } catch {
                    return .threw(error)
                }
            }
            group.addTask {
                try? await Task.sleep(for: .milliseconds(100))
                return .stillWaiting
            }
            var outcomes: [NeverOutcome] = []
            for await outcome in group {
                outcomes.append(outcome)
                // The first outcome cancels whatever is still running.
                group.cancelAll()
            }
            return outcomes
        }

        #expect(outcomes == [.stillWaiting, .threw(.cancelled)])
    }

    @Test("DependencyValues gives the client that was set")
    func dependencyValuesGiveTheClientThatWasSet() async throws {
        let places = try await withDependencies {
            $0.locationsClient = .empty
        } operation: {
            @Dependency(\.locationsClient) var locationsClient
            return try await locationsClient.fetch()
        }

        #expect(places.isEmpty)
    }

    // MARK: Helpers

    private static func liveClient(url: URL) -> LocationsClient {
        LocationsClient.live(
            httpClient: HTTPClient(session: StubURLProtocol.session, userAgent: "LocationsClientTests/1.0"),
            url: url
        )
    }
}
