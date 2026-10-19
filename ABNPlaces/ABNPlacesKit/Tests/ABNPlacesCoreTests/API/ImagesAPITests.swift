import Dependencies
import Foundation
import Testing

@testable import ABNNetworking
@testable import ABNPlacesCore

@Suite("Images API")
struct ImagesAPITests {
    // MARK: The live client, with a fake connection

    @Test("The live client sends the article search, with the coordinates and a 300 px thumbnail")
    func liveClientSendsTheArticleSearch() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Self.answer(Self.amsterdamArticle))

        _ = try await Self.liveClient(url: url).search("Amsterdam", Self.amsterdam)

        let request = try #require(StubURLProtocol.receivedRequest(for: url))
        let requestURL = try #require(request.url)
        let items = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let expected = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: "Amsterdam"),
            URLQueryItem(name: "gsrlimit", value: "5"),
            URLQueryItem(name: "prop", value: "coordinates|pageimages"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            URLQueryItem(name: "pithumbsize", value: "300"),
        ]
        #expect(Set(items) == Set(expected))
    }

    /// Checked on the URL as sent: reading it back with `URLComponents` turns "%2B" into "+" again.
    @Test("A \"+\" in the name is sent as %2B, or Wikipedia reads it as a space")
    func plusIsPercentEncoded() throws {
        let url = ImagesAPI.searchRequestURL(ImagesAPI.searchURL, name: "C++ & co")

        #expect(url.absoluteString.contains("gsrsearch=C%2B%2B%20%26%20co"))
    }

    @Test("The live client returns the image of the best ranked match near the place")
    func liveClientReturnsTheBestRankedMatchNearby() async throws {
        // In the answer's order, which isn't the ranking: the best match is far away, the second one is near.
        let body = Self.answer(
            Self.page(index: 3, at: Self.amsterdamCentre, image: "third"),
            Self.page(index: 1, at: Self.mumbai, image: "first"),
            Self.page(index: 2, at: Self.amsterdamCentre, image: "second")
        )
        let url = try StubURLProtocol.register(statusCode: 200, body: body)

        let thumbnail = try await Self.liveClient(url: url).search("Amsterdam", Self.amsterdam)

        #expect(thumbnail.lastPathComponent == "second.jpg")
    }

    @Test(
        "No nearby match with an image is no result",
        arguments: [
            ("no match", #"{"batchcomplete":true}"#),
            ("no coordinates, like a podcast", Self.answerText(Self.page(index: 1, at: nil, image: "podcast"))),
            ("too far away", Self.answerText(Self.page(index: 1, at: Self.mumbai, image: "mumbai"))),
            ("near, without an image", Self.answerText(Self.page(index: 1, at: Self.amsterdamCentre, image: nil))),
        ]
    )
    func liveClientThrowsNoResult(_ situation: String, _ body: String) async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(body.utf8))

        await #expect(throws: ImagesAPIError.noResult) {
            try await Self.liveClient(url: url).search("Amsterdam", Self.amsterdam)
        }
    }

    @Test("The live client asks once per place, and remembers no result too")
    func liveClientAsksOncePerPlace() async throws {
        let found = try StubURLProtocol.register(statusCode: 200, body: Self.answer(Self.amsterdamArticle))
        let notFound = try StubURLProtocol.register(statusCode: 200, body: Data(#"{"batchcomplete":true}"#.utf8))
        let foundClient = Self.liveClient(url: found)
        let notFoundClient = Self.liveClient(url: notFound)

        _ = try await foundClient.search("Amsterdam", Self.amsterdam)
        _ = try await foundClient.search("Amsterdam", Self.amsterdam)
        _ = try? await notFoundClient.search("Nowhere", Self.amsterdam)
        _ = try? await notFoundClient.search("Nowhere", Self.amsterdam)

        #expect(StubURLProtocol.requestCount(for: found) == 1)
        #expect(StubURLProtocol.requestCount(for: notFound) == 1)
    }

    @Test("The same name somewhere else is asked again")
    func liveClientAsksAgainForTheSameNameElsewhere() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Self.answer(Self.amsterdamArticle))
        let client = Self.liveClient(url: url)

        _ = try await client.search("Home", Self.amsterdam)
        _ = try? await client.search("Home", Place.mumbai.coordinate)

        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test("A failure isn't remembered, so the next search asks again")
    func liveClientAsksAgainAfterAFailure() async throws {
        let url = try StubURLProtocol.register(statusCode: 503, body: Data())
        let client = Self.liveClient(url: url)

        await #expect(throws: ImagesAPIError.server) { try await client.search("Amsterdam", Self.amsterdam) }
        await #expect(throws: ImagesAPIError.server) { try await client.search("Amsterdam", Self.amsterdam) }

        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    /// Wikipedia answers errors, such as rate limiting, with status 200.
    @Test("A Wikipedia error is a server failure, and isn't remembered either")
    func liveClientTreatsAWikipediaErrorAsAFailure() async throws {
        let body = #"{"error":{"code":"ratelimited","info":"You've exceeded your rate limit."}}"#
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(body.utf8))
        let client = Self.liveClient(url: url)

        await #expect(throws: ImagesAPIError.server) { try await client.search("Amsterdam", Self.amsterdam) }
        await #expect(throws: ImagesAPIError.server) { try await client.search("Amsterdam", Self.amsterdam) }

        #expect(StubURLProtocol.requestCount(for: url) == 2)
    }

    @Test("A different payload is unexpected data")
    func liveClientThrowsUnexpectedDataForADifferentPayload() async throws {
        let url = try StubURLProtocol.register(statusCode: 200, body: Data(#"{"query":{"pages":"none"}}"#.utf8))

        await #expect(throws: ImagesAPIError.unexpectedData) {
            try await Self.liveClient(url: url).search("Amsterdam", Self.amsterdam)
        }
    }

    // MARK: Errors

    @Test(
        "Each network error becomes an images error",
        arguments: [
            (NetworkError.offline, ImagesAPIError.offline),
            (.timedOut, .server),
            (.server(statusCode: 503), .server),
            (.invalidResponse, .server),
            (.transport(code: .secureConnectionFailed), .server),
            (.transport(code: .cancelled), .server),
            (.decoding, .unexpectedData),
            (.cancelled, .cancelled),
        ]
    )
    func mapsEachNetworkError(_ error: NetworkError, expected: ImagesAPIError) {
        #expect(ImagesAPIError(error) == expected)
    }

    // MARK: Live and test values

    @Test("The search URL is English Wikipedia's API")
    func searchURLIsEnglishWikipediasAPI() {
        #expect(ImagesAPI.searchURL.absoluteString == "https://en.wikipedia.org/w/api.php")
    }

    /// `@DependencyClient` writes the unimplemented `search`. The test checks the exact message, so it fails if the
    /// call reports nothing, or something else.
    @Test("The test value reports an unimplemented search, then throws")
    func testValueReportsUnimplementedAndThrows() async {
        var thrownError: ImagesAPIError?

        await withKnownIssue("ImagesAPI.testValue is unimplemented on purpose") {
            do throws(ImagesAPIError) {
                _ = try await ImagesAPI.testValue.search("Amsterdam", Self.amsterdam)
            } catch {
                thrownError = error
            }
        } matching: { issue in
            issue.comments.map(\.rawValue) == ["Unimplemented: 'ImagesAPI.search'"]
        }

        #expect(thrownError == .server)
    }

    // MARK: Canned clients

    @Test("The preview client returns the stub photo from the package's resources")
    func previewReturnsTheStubPhoto() async throws {
        #expect(URL.placeStubImage.isFileURL)
        #expect(FileManager.default.fileExists(atPath: URL.placeStubImage.path()))
        #expect(try await ImagesAPI.preview.search("Amsterdam", Self.amsterdam) == .placeStubImage)
        #expect(try await ImagesAPI.previewValue.search("Amsterdam", Self.amsterdam) == .placeStubImage)
    }

    @Test("The empty client has no result")
    func emptyHasNoResult() async {
        await #expect(throws: ImagesAPIError.noResult) {
            try await ImagesAPI.empty.search("Amsterdam", Self.amsterdam)
        }
    }

    @Test(
        "The failing client throws the error it was given",
        arguments: [ImagesAPIError.offline, .server, .unexpectedData, .noResult]
    )
    func failingThrowsTheGivenError(_ error: ImagesAPIError) async {
        await #expect(throws: error) {
            try await ImagesAPI.failing(error).search("Amsterdam", Self.amsterdam)
        }
    }

    enum NeverOutcome: Equatable, Sendable {
        case returned
        case threw(ImagesAPIError)
        case stillWaiting
    }

    @Test("The never client waits until it's cancelled, then throws .cancelled", .timeLimit(.minutes(1)))
    func neverWaitsUntilCancelled() async {
        let outcomes = await withTaskGroup(of: NeverOutcome.self) { group in
            group.addTask {
                do throws(ImagesAPIError) {
                    _ = try await ImagesAPI.never.search("Amsterdam", Self.amsterdam)
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
    func dependencyValuesGiveTheClientThatWasSet() async {
        await #expect(throws: ImagesAPIError.noResult) {
            try await withDependencies {
                $0.imagesAPI = .empty
            } operation: {
                @Dependency(\.imagesAPI) var imagesAPI
                return try await imagesAPI.search("Amsterdam", Self.amsterdam)
            }
        }
    }

    // MARK: Helpers

    /// The feed's Amsterdam, in the west of the city.
    private static let amsterdam = Place.amsterdam.coordinate
    /// Where Wikipedia puts the Amsterdam article: about 4.5 km from `amsterdam`.
    private static let amsterdamCentre = (lat: 52.37277778, lon: 4.89361111)
    private static let mumbai = (lat: 19.076, lon: 72.8777)

    private static let amsterdamArticle = page(index: 1, at: amsterdamCentre, image: "amsterdam")

    /// A search result, with its coordinates and image when it has them.
    private static func page(index: Int, at location: (lat: Double, lon: Double)?, image: String?) -> String {
        var fields = [#""index":\#(index)"#, #""title":"Page \#(index)""#]
        if let location {
            fields.append(#""coordinates":[{"lat":\#(location.lat),"lon":\#(location.lon),"primary":true}]"#)
        }
        if let image {
            fields.append(#""thumbnail":{"source":"https://upload.wikimedia.org/\#(image).jpg","width":300}"#)
        }
        return "{\(fields.joined(separator: ","))}"
    }

    private static func answer(_ pages: String...) -> Data {
        Data(#"{"batchcomplete":true,"query":{"pages":[\#(pages.joined(separator: ","))]}}"#.utf8)
    }

    /// `answer(_:)` as text, for the arguments of a test.
    private static func answerText(_ page: String) -> String {
        #"{"batchcomplete":true,"query":{"pages":[\#(page)]}}"#
    }

    private static func liveClient(url: URL) -> ImagesAPI {
        ImagesAPI.live(
            httpClient: HTTPClient(session: StubURLProtocol.session, userAgent: "ImagesAPITests/1.0"),
            url: url
        )
    }
}
