import Foundation

/// The link that shows a coordinate in Wikipedia.
///
/// Numbers are written for machines, never for people: POSIX (dot decimal, no grouping), fixed notation, at most
/// 7 decimals. The receiving parser accepts only `-?[0-9]{1,3}(\.[0-9]{1,15})?`, so `1e-07` or `52,35` would fail.
public enum WikipediaLink {
    // `wikipedia://places?lat=…&lon=…[&name=…]`, which the modified Wikipedia app opens in the Places tab.
    public static func places(coordinate: Coordinate, name: String? = nil) -> URL {
        var queryItems = [
            URLQueryItem(name: "lat", value: coordinate.latitudeText),
            URLQueryItem(name: "lon", value: coordinate.longitudeText),
        ]
        if let name = name?.trimmedNonEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }

        var components = URLComponents()
        components.scheme = "wikipedia"
        components.host = "places"
        components.queryItems = queryItems
        return components.validURL
    }
}
