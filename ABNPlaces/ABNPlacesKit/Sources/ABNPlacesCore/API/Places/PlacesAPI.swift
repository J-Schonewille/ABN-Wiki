internal import ABNLogging
internal import ABNNetworking
import Dependencies
import DependenciesMacros
import Foundation
import os

@DependencyClient
public struct PlacesAPI: Sendable {
    public var fetch: @Sendable () async throws(PlacesAPIError) -> [Place] = { throw .server }
}

extension PlacesAPI: DependencyKey {
    /// Loads the assignment's `locations.json`, always from the server.
    public static let liveValue = PlacesAPI.live(httpClient: .live, url: feedURL)

    /// `fetch` is unimplemented, so a test that uses this client without setting it fails.
    public static let testValue = PlacesAPI()

    #if DEBUG
    /// The real feed's four places, without the network.
    public static let previewValue = PlacesAPI.preview
    #endif
}

extension DependencyValues {
    public var placesAPI: PlacesAPI {
        get { self[PlacesAPI.self] }
        set { self[PlacesAPI.self] = newValue }
    }
}

// MARK: Helper clients
#if DEBUG
// Only in DEBUG builds, like the fixtures: Release builds need no helpers.
extension PlacesAPI {

    public static let preview = PlacesAPI { [Place].preview }

    public static let empty = PlacesAPI { [] }

    public static func failing(_ error: PlacesAPIError) -> PlacesAPI {
        PlacesAPI { () throws(PlacesAPIError) in throw error }
    }

    /// Never answers until its task is cancelled, then throws `.cancelled`. For loading states.
    public static let never = PlacesAPI { () async throws(PlacesAPIError) in
        try? await Task.never()
        throw .cancelled
    }
}
#endif

// MARK: - Live

extension PlacesAPI {

    static let feedURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "raw.githubusercontent.com"
        components.path = "/abnamrocoesd/assignment-ios/main/locations.json"
        return components.validURL
    }()

    /// Maps every `NetworkError` to a `PlacesAPIError`.
    static func live(httpClient: HTTPClient, url: URL) -> PlacesAPI {
        PlacesAPI { () async throws(PlacesAPIError) in
            do throws(NetworkError) {
                let (data, _) = try await httpClient.data(for: URLRequest(url: url))
                let feed = try await decode(PlacesFeed.self, from: data)
                if feed.skippedCount > 0 {
                    Logger.places.warning("Skipped \(feed.skippedCount) invalid entries in locations.json")
                }
                return feed.places
            } catch {
                throw PlacesAPIError(error)
            }
        }
    }
}

extension PlacesAPIError {
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
