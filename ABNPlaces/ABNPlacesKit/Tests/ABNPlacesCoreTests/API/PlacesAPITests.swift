import Dependencies
import Foundation
import Testing

@testable import ABNNetworking
@testable import ABNPlacesCore

@Suite("Places API")
struct PlacesAPITests {
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

        await #expect(throws: PlacesAPIError.server) {
            try await Self.liveClient(url: url).fetch()
        }
    }

    @Test("A different payload is unexpected data")
    func liveClientThrowsUnexpectedDataForADifferentPayload() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(#"{"places":[]}"#.utf8))

        await #expect(throws: PlacesAPIError.unexpectedData) {
            try await Self.liveClient(url: url).fetch()
        }
    }

    // MARK: Errors

    /// Every network error becomes a cause a screen can explain, and only a cancelled caller is `.cancelled`.
    @Test(
        "Each network error becomes the cause a screen explains",
        arguments: [
            (NetworkError.offline, PlacesAPIError.offline),
            (.timedOut, .server),
            (.server(statusCode: 503), .server),
            (.invalidResponse, .server),
            (.transport(code: .secureConnectionFailed), .server),
            (.transport(code: .cancelled), .server),
            (.decoding, .unexpectedData),
            (.cancelled, .cancelled),
        ]
    )
    func mapsEachNetworkErrorToTheCauseAScreenExplains(_ error: NetworkError, expected: PlacesAPIError) {
        #expect(PlacesAPIError(error) == expected)
    }

    // MARK: Live and test values

    @Test("The feed URL is the assignment's locations.json")
    func feedURLIsTheAssignmentsLocationsJSON() {
        let expected = "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json"

        #expect(PlacesAPI.feedURL.absoluteString == expected)
    }

    /// `@DependencyClient` writes the unimplemented `fetch`. The test checks the exact message, so it fails if the
    /// call reports nothing, or something else.
    @Test("The test value reports an unimplemented fetch, then throws")
    func testValueReportsUnimplementedAndThrows() async {
        var thrownError: PlacesAPIError?

        await withKnownIssue("PlacesAPI.testValue is unimplemented on purpose") {
            do throws(PlacesAPIError) {
                _ = try await PlacesAPI.testValue.fetch()
            } catch {
                thrownError = error
            }
        } matching: { issue in
            issue.comments.map(\.rawValue) == ["Unimplemented: 'PlacesAPI.fetch'"]
        }

        #expect(thrownError == .server)
    }

    // MARK: Canned clients

    @Test("The preview client returns the real feed's four places")
    func previewReturnsTheRealFeedsPlaces() async throws {
        let feedPlaces = try FeedFixture.places()

        #expect([Place].preview == feedPlaces)
        #expect(try await PlacesAPI.preview.fetch() == feedPlaces)
        #expect(try await PlacesAPI.previewValue.fetch() == feedPlaces)
    }

    @Test("The empty client returns no places")
    func emptyReturnsNoPlaces() async throws {
        #expect(try await PlacesAPI.empty.fetch().isEmpty)
    }

    @Test(
        "The failing client throws the error it was given",
        arguments: [PlacesAPIError.offline, .server, .unexpectedData]
    )
    func failingThrowsTheGivenError(_ error: PlacesAPIError) async {
        await #expect(throws: error) {
            try await PlacesAPI.failing(error).fetch()
        }
    }

    enum NeverOutcome: Equatable, Sendable {
        case returned
        case threw(PlacesAPIError)
        case stillWaiting
    }

    @Test("The never client waits until it's cancelled, then throws .cancelled", .timeLimit(.minutes(1)))
    func neverWaitsUntilCancelled() async {
        let outcomes = await withTaskGroup(of: NeverOutcome.self) { group in
            group.addTask {
                do throws(PlacesAPIError) {
                    _ = try await PlacesAPI.never.fetch()
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
            $0.placesAPI = .empty
        } operation: {
            @Dependency(\.placesAPI) var placesAPI
            return try await placesAPI.fetch()
        }

        #expect(places.isEmpty)
    }

    // MARK: Helpers

    private static func liveClient(url: URL) -> PlacesAPI {
        PlacesAPI.live(
            httpClient: HTTPClient(session: StubURLProtocol.session, userAgent: "PlacesAPITests/1.0"),
            url: url
        )
    }
}
