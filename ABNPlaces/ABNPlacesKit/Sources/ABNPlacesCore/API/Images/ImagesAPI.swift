internal import ABNLogging
internal import ABNNetworking
import CoreLocation
import Dependencies
import DependenciesMacros
import Foundation
import os

/// Finds a thumbnail for a place: the lead image of the best matching Wikipedia article near the place.
@DependencyClient
public struct ImagesAPI: Sendable {
    /// The thumbnail's URL. Throws `.noResult` when no article near `coordinate` matches `name` and has an image.
    public var search: @Sendable (_ name: String, _ coordinate: Coordinate) async throws(ImagesAPIError) -> URL = {
        _, _ in throw .server
    }
}

extension ImagesAPI: DependencyKey {
    /// Asks Wikipedia, and remembers the answers for as long as the app runs.
    public static let liveValue = ImagesAPI.live(httpClient: .live, url: searchURL)

    /// `search` is unimplemented, so a test that uses this client without setting it fails.
    public static let testValue = ImagesAPI()

    #if DEBUG
    /// The stub photo, without the network.
    public static let previewValue = ImagesAPI.preview
    #endif
}

extension DependencyValues {
    public var imagesAPI: ImagesAPI {
        get { self[ImagesAPI.self] }
        set { self[ImagesAPI.self] = newValue }
    }
}

// MARK: Helper clients
#if DEBUG
// Only in DEBUG builds, like the fixtures: Release builds need no helpers.
extension ImagesAPI {

    /// The same photo for every place.
    public static let preview = ImagesAPI { _, _ in .placeStubImage }

    public static let empty = ImagesAPI { (_: String, _: Coordinate) async throws(ImagesAPIError) in
        throw .noResult
    }

    public static func failing(_ error: ImagesAPIError) -> ImagesAPI {
        ImagesAPI { (_: String, _: Coordinate) async throws(ImagesAPIError) in
            throw error
        }
    }

    /// Never answers until its task is cancelled, then throws `.cancelled`. For loading states.
    public static let never = ImagesAPI { (_: String, _: Coordinate) async throws(ImagesAPIError) in
        try? await Task.never()
        throw .cancelled
    }
}
#endif

// MARK: - Live

extension ImagesAPI {
    static let searchURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "en.wikipedia.org"
        components.path = "/w/api.php"
        return components.validURL
    }()

    /// In pixels, for the shorter side: Wikipedia limits the longer one, and the tile crops to a square.
    static let thumbnailSize = 300

    /// How many matches to check for one near the place.
    static let searchLimit = 5

    /// In metres. A city's article sits at its centre, a few kilometres from a point in the city.
    static let maximumDistance: CLLocationDistance = 25_000

    /// Maps every `NetworkError` to an `ImagesAPIError`.
    static func live(httpClient: HTTPClient, url: URL) -> ImagesAPI {
        // Per place: the thumbnail, or nil when there is none. Failures aren't kept, so they're tried again.
        let answers = LockIsolated<[Lookup: URL?]>([:])
        return ImagesAPI { (name: String, coordinate: Coordinate) async throws(ImagesAPIError) in
            let lookup = Lookup(name: name, coordinate: coordinate)
            if let answer = answers.value[lookup] {
                guard let answer else { throw .noResult }
                return answer
            }

            let response: SearchResponse
            do throws(NetworkError) {
                let request = URLRequest(url: searchRequestURL(url, name: name))
                let (data, _) = try await httpClient.data(for: request)
                response = try await decode(SearchResponse.self, from: data)
            } catch {
                throw ImagesAPIError(error)
            }

            // Wikipedia answers errors, such as rate limiting, with status 200. Not kept, like other failures.
            if let error = response.error {
                Logger.places.warning("Wikipedia answered the image search with \(error.code, privacy: .public)")
                throw .server
            }

            let thumbnail = nearbyThumbnail(in: response.query?.pages ?? [], near: coordinate)
            answers.withValue { $0[lookup] = thumbnail }
            guard let thumbnail else { throw .noResult }
            return thumbnail
        }
    }

    /// Searches the articles, not the files: a file search matches words in file names, so it finds photos of
    /// people and paintings. Asks for each match's coordinates too, for `nearbyThumbnail(in:near:)`.
    static func searchRequestURL(_ url: URL, name: String) -> URL {
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host()
        components.path = url.path()
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: name),
            URLQueryItem(name: "gsrlimit", value: String(searchLimit)),
            URLQueryItem(name: "prop", value: "coordinates|pageimages"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            URLQueryItem(name: "pithumbsize", value: String(thumbnailSize)),
        ]
        // URLComponents leaves "+" as it is, and Wikipedia reads it as a space: "C++" would search for "C".
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.validURL
    }

    /// The image of the best ranked match within `maximumDistance`. A match without coordinates never counts:
    /// for a place called "Mom's house", the best match is a podcast.
    static func nearbyThumbnail(in pages: [SearchResultPage], near coordinate: Coordinate) -> URL? {
        let place = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return
            pages
            .sorted { $0.index < $1.index }
            .first { page in
                guard page.thumbnail != nil, let match = page.coordinates?.first else { return false }
                let location = CLLocation(latitude: match.lat, longitude: match.lon)
                return location.distance(from: place) <= maximumDistance
            }?
            .thumbnail?.source
    }
}

extension ImagesAPIError {
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

/// A place's name and coordinate: two places with the same name can be far apart.
private struct Lookup: Hashable {
    let name: String
    let coordinate: Coordinate
}

/// The parts of the answer we read. Without a match, the answer has no `query`.
struct SearchResponse: Decodable, Sendable {
    let query: Query?
    let error: APIError?

    struct Query: Decodable, Sendable {
        let pages: [SearchResultPage]
    }

    struct APIError: Decodable, Sendable {
        let code: String
    }
}

struct SearchResultPage: Decodable, Sendable {
    /// The rank in the search results: `pages` isn't in that order.
    let index: Int
    /// Missing for an article about something without a location.
    let coordinates: [Location]?
    /// Missing when the article has no lead image.
    let thumbnail: Thumbnail?

    struct Location: Decodable, Sendable {
        let lat: Double
        let lon: Double
    }

    struct Thumbnail: Decodable, Sendable {
        let source: URL
    }
}
