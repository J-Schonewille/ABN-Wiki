internal import ABNLogging
internal import ABNNetworking
import Dependencies
import DependenciesMacros
import Foundation
import os

@DependencyClient
public struct LocationsClient: Sendable {
    public var fetch: @Sendable () async throws(LocationsError) -> [Place] = { throw .server }
}

extension LocationsClient: DependencyKey {
    /// Loads the assignment's `locations.json`, always from the server.
    public static let liveValue = LocationsClient.live(httpClient: liveHTTPClient, url: feedURL)

    /// `fetch` is unimplemented, so a test that uses this client without setting it fails.
    public static let testValue = LocationsClient()

    #if DEBUG
    /// The real feed's four places, without the network.
    public static let previewValue = LocationsClient.preview
    #endif
}

extension DependencyValues {
    public var locationsClient: LocationsClient {
        get { self[LocationsClient.self] }
        set { self[LocationsClient.self] = newValue }
    }
}

// MARK: Helper clients
#if DEBUG
// Only in DEBUG builds, like the fixtures: Release builds need no helpers.
extension LocationsClient {

    public static let preview = LocationsClient { [Place].preview }

    public static let empty = LocationsClient { [] }

    public static func failing(_ error: LocationsError) -> LocationsClient {
        LocationsClient { () throws(LocationsError) in throw error }
    }

    /// Never answers: waits until its task is cancelled, then throws `.cancelled` ->. For loading states.
    public static let never = LocationsClient { () async throws(LocationsError) in
        try? await Task.never()
        throw .cancelled
    }
}
#endif

// MARK: - Live

extension LocationsClient {

    static let feedURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "raw.githubusercontent.com"
        components.path = "/abnamrocoesd/assignment-ios/main/locations.json"
        return components.validURL
    }()

    static let userAgent = makeUserAgent(
        appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    )

    static func makeUserAgent(appVersion: String?) -> String {
        appVersion.map { "ABNPlaces/\($0)" } ?? "ABNPlaces"
    }

    /// The live value's HTTP client: a session without a cache, and the app's User-Agent.
    static let liveHTTPClient = HTTPClient(session: HTTPClient.makeEphemeralSession(), userAgent: userAgent)

    /// The live client, loading from `url`.  transforms error's into LocationsError
    static func live(httpClient: HTTPClient, url: URL) -> LocationsClient {
        LocationsClient { () async throws(LocationsError) in
            do throws(NetworkError) {
                let (data, _) = try await httpClient.data(for: URLRequest(url: url))
                let feed = try await decode(LocationsFeed.self, from: data)
                if feed.skippedCount > 0 {
                    Logger.locations.warning("Skipped \(feed.skippedCount) invalid entries in locations.json")
                }
                return feed.places
            } catch {
                throw LocationsError(error)
            }
        }
    }
}

extension LocationsError {
    init(_ error: NetworkError) {
        switch error {
        case .offline:
            self = .offline
        case .timedOut, .server, .invalidResponse, .transport:
            self = .server
        case .decoding:
            self = .unexpectedData
        case .cancelled:
            self = .cancelled
        }
    }
}
