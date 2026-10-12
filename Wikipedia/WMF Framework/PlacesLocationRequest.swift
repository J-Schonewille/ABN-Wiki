import CoreLocation
import Foundation

/// A place that another app asks the Places tab to show, such as
/// "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam".
///
/// Any app or web page can open this link. For invalid links we still open the Places tab.
///
/// This type only reads the query. Which screen opens is decided in
/// `NSUserActivity.wmf_activity(forWikipediaScheme:)`.
nonisolated public struct PlacesLocationRequest: Equatable, Sendable {
    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees
    /// Only for showing on screen. Never put it into a search query, a predicate or HTML.
    public let name: String?

    /// Longer names are cut to this many characters.
    static let maximumNameLength = 100

    public init?(url: URL) {

        func value(_ key: String) -> String? {
            guard let value = queryItems.first(where: { $0.name == key })?.value, !value.isEmpty else {
                return nil
            }
            return value
        }
        
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        guard let latitude = value("lat").flatMap(Self.degrees), (-90...90).contains(latitude),
              let longitude = value("lon").flatMap(Self.degrees), (-180...180).contains(longitude) else {
            return nil
        }

        self.latitude = latitude
        self.longitude = longitude
        self.name = value("name").flatMap(Self.sanitizedName)
    }

    /// The number in the text, or nil if the text isn't a plain decimal number.
    ///
    /// We check the text before converting it, because `Double` also accepts things like
    /// "0x1p3" (hex for 8), "5.235e1", "+52.3", ".5", "nan" and "inf".
    private static func degrees(_ text: String) -> CLLocationDegrees? {
        guard text.wholeMatch(of: #/-?[0-9]{1,3}(?:\.[0-9]{1,15})?/#) != nil,
              let degrees = Double(text), degrees.isFinite else {
            return nil
        }
        return degrees
    }

    /// Cleans up the name so it's safe to show, or returns nil when nothing is left.
    ///
    /// 1. Removes invisible characters, such as ones that flip text right-to-left or have no width.
    /// 2. Joins each letter and its accent into one character, so the same name always looks the same.
    /// 3. Trims spaces at the start and the end.
    /// 4. Cuts it to `maximumNameLength` characters.
    static func sanitizedName(_ raw: String) -> String? {
        // Remove invisible characters first: one between a letter and its accent would stop them joining.
        let visibleScalars = raw.unicodeScalars.filter { scalar in
            let category = scalar.properties.generalCategory
            return category != .control && category != .format
        }
        let name = String(visibleScalars).precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }
        // Cutting can leave a space at the end, so trim again.
        return String(name.prefix(maximumNameLength)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
