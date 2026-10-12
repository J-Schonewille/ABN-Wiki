import Foundation
import Testing
@testable import WMF

/// The query contract of `wikipedia://places?lat=<degrees>&lon=<degrees>[&name=<label>]`.
struct PlacesLocationRequestTests {

    struct ValidCase: Sendable, CustomTestStringConvertible {
        let query: String
        let latitude: Double
        let longitude: Double
        var name: String?

        var testDescription: String { query }
    }

    static let validCases: [ValidCase] = [
        ValidCase(query: "lat=52.3547498&lon=4.8339215&name=Amsterdam", latitude: 52.3547498, longitude: 4.8339215, name: "Amsterdam"),
        // Madrid: a negative longitude and no name.
        ValidCase(query: "lat=40.4380638&lon=-3.7495758", latitude: 40.4380638, longitude: -3.7495758),
        ValidCase(query: "lat=90&lon=180", latitude: 90, longitude: 180),
        ValidCase(query: "lat=-90&lon=-180", latitude: -90, longitude: -180),
        ValidCase(query: "lat=0&lon=0", latitude: 0, longitude: 0),
        // Any order; unknown parameters are ignored.
        ValidCase(query: "lon=72.8111468&lat=19.0823998&zoom=12", latitude: 19.0823998, longitude: 72.8111468),
        // Fifteen fraction digits, the most the grammar allows.
        ValidCase(query: "lat=1.123456789012345&lon=-0.5", latitude: 1.123456789012345, longitude: -0.5),
        ValidCase(query: "lat=52.0799838&lon=4.3113461&name=Den%20Haag", latitude: 52.0799838, longitude: 4.3113461, name: "Den Haag"),
        // The Places app's own links (its WikipediaLinkTests): every link it sends is accepted here.
        ValidCase(query: "lat=90&lon=-180", latitude: 90, longitude: -180),
        ValidCase(query: "lat=52.3731&lon=4.8926&name=Dam%20%26%20Royal%20Palace", latitude: 52.3731, longitude: 4.8926, name: "Dam & Royal Palace"),
        // A repeated key: the first value wins.
        ValidCase(query: "lat=52.3&lat=10&lon=4.8", latitude: 52.3, longitude: 4.8),
        ValidCase(query: "lat=52.3&lon=4.8&lon=10", latitude: 52.3, longitude: 4.8),
        ValidCase(query: "lat=52.3&lon=4.8&name=A&name=B", latitude: 52.3, longitude: 4.8, name: "A")
    ]

    @Test(arguments: validCases)
    func acceptsValidLink(_ validCase: ValidCase) throws {
        let url = try Self.placesURL(query: validCase.query)

        let request = try #require(PlacesLocationRequest(url: url))

        #expect(request.latitude == validCase.latitude)
        #expect(request.longitude == validCase.longitude)
        #expect(request.name == validCase.name)
    }

    /// Each query changes one thing in a valid link, so it can only fail for that reason.
    static let invalidQueries: [String] = [
        "lat=200&lon=10",
        "lat=10&lon=540",
        "lat=90.1&lon=10",
        "lat=-90.1&lon=10",
        "lat=10&lon=180.1",
        "lat=10&lon=-180.1",
        "lat=nan&lon=4.8",
        "lat=inf&lon=4.8",
        "lat=1e309&lon=4.8", // Double(_:) reads it as infinity
        "lat=0x1p3&lon=4.8", // Double(_:) reads it as 8.0
        "lat=5.235e1&lon=4.8", // Double(_:) reads it as 52.35
        "lat=+52.3&lon=4.8",
        "lat=%2052.3&lon=4.8", // leading space
        "lat=52,35&lon=4.8", // decimal comma, as Dutch formatting writes it
        "lat=52.3abc&lon=4.8",
        "lat=.5&lon=4.8",
        "lat=5.&lon=4.8",
        "lat=0052&lon=4.8", // four integer digits
        "lat=1.1234567890123456&lon=4.8", // sixteen fraction digits
        "lat=%D9%A5%D9%A2&lon=4.8", // Arabic-Indic digits
        "lat=%EF%BC%95%EF%BC%92&lon=4.8", // fullwidth digits
        "lat=&lon=4.8", // an empty value counts as missing
        "lon=4.8",
        "lat=52.3",
        "LAT=52.3&LON=4.8", // keys are exact and lowercase
        ""
    ]

    @Test(arguments: invalidQueries)
    func rejectsInvalidLink(_ query: String) throws {
        let url = try Self.placesURL(query: query)

        #expect(PlacesLocationRequest(url: url) == nil)
    }

    // MARK: Name

    struct NameCase: Sendable, CustomTestStringConvertible {
        let testDescription: String
        let rawName: String
        let expectedName: String?
    }

    static let nameCases: [NameCase] = [
        NameCase(testDescription: "right-to-left override removed", rawName: "\u{202E}madretsmA", expectedName: "madretsmA"),
        NameCase(testDescription: "zero-width characters removed", rawName: "Am\u{200B}ster\u{200D}dam\u{FEFF}", expectedName: "Amsterdam"),
        NameCase(testDescription: "control characters removed", rawName: "Amsterdam\u{0000}\u{0007}", expectedName: "Amsterdam"),
        NameCase(testDescription: "surrounding whitespace trimmed", rawName: "  Den Haag \n", expectedName: "Den Haag"),
        NameCase(testDescription: "whitespace only is no name", rawName: " \t\u{00A0}\n ", expectedName: nil),
        NameCase(testDescription: "format characters only is no name", rawName: "\u{200B}\u{2066}", expectedName: nil),
        NameCase(testDescription: "literal plus kept", rawName: "C++ Café", expectedName: "C++ Café"),
        NameCase(testDescription: "10,000 characters capped at 100", rawName: String(repeating: "a", count: 10_000), expectedName: String(repeating: "a", count: 100)),
        NameCase(testDescription: "a cut that ends on whitespace is trimmed", rawName: String(repeating: "a", count: 99) + " b", expectedName: String(repeating: "a", count: 99))
    ]

    @Test(arguments: nameCases)
    func sanitizesName(_ nameCase: NameCase) throws {
        let url = try Self.placesURL(lat: "52.3547498", lon: "4.8339215", name: nameCase.rawName)

        let request = try #require(PlacesLocationRequest(url: url))

        #expect(request.name == nameCase.expectedName)
    }

    @Test
    func readsPlusInRawLinkAsPlus() throws {
        let url = try Self.placesURL(query: "lat=52.08&lon=4.31&name=Den+Haag")

        let request = try #require(PlacesLocationRequest(url: url))

        #expect(request.name == "Den+Haag")
    }

    @Test
    func normalizesNameToNFC() throws {
        let url = try Self.placesURL(lat: "48.8566", lon: "2.3522", name: "Ope\u{0301}ra")

        let name = try #require(PlacesLocationRequest(url: url)?.name)

        // String == compares canonical equivalents, so compare the scalars.
        #expect(Array(name.unicodeScalars) == Array("Op\u{00E9}ra".unicodeScalars))
    }

    @Test
    func keepsLocationWhenNameIsNotUTF8() throws {
        let url = try Self.placesURL(query: "lat=52.3&lon=4.8&name=%FF")

        let request = try #require(PlacesLocationRequest(url: url))

        #expect(request.name == nil)
    }

    // MARK: Map centre

    struct MapCenterCase: Sendable, CustomTestStringConvertible {
        let query: String
        let centerLatitude: Double

        var testDescription: String { query }
    }

    static let mapCenterCases: [MapCenterCase] = [
        // MapKit can't centre on a pole, nor at 85°, where its map ends.
        MapCenterCase(query: "lat=90&lon=0", centerLatitude: 84.5),
        MapCenterCase(query: "lat=-90&lon=0", centerLatitude: -84.5),
        MapCenterCase(query: "lat=90&lon=180", centerLatitude: 84.5),
        MapCenterCase(query: "lat=-90&lon=-180", centerLatitude: -84.5),
        MapCenterCase(query: "lat=85&lon=4.8", centerLatitude: 84.5),
        MapCenterCase(query: "lat=-85&lon=4.8", centerLatitude: -84.5),
        MapCenterCase(query: "lat=84.5000001&lon=-42.5", centerLatitude: 84.5),
        MapCenterCase(query: "lat=-86.5&lon=166.6", centerLatitude: -84.5),
        // 84.5° itself, and everything closer to the equator, stays as it is.
        MapCenterCase(query: "lat=84.5&lon=4.8", centerLatitude: 84.5),
        MapCenterCase(query: "lat=-84.5&lon=4.8", centerLatitude: -84.5),
        MapCenterCase(query: "lat=84.4999999&lon=4.8", centerLatitude: 84.4999999),
        MapCenterCase(query: "lat=52.3547498&lon=4.8339215", centerLatitude: 52.3547498),
        MapCenterCase(query: "lat=-33.8567844&lon=151.213108", centerLatitude: -33.8567844),
        MapCenterCase(query: "lat=0&lon=0", centerLatitude: 0)
    ]

    @Test(arguments: mapCenterCases)
    func capsMapCenterLatitude(_ mapCenterCase: MapCenterCase) throws {
        let url = try Self.placesURL(query: mapCenterCase.query)

        let request = try #require(PlacesLocationRequest(url: url))

        #expect(request.mapCenter.latitude == mapCenterCase.centerLatitude)
        #expect(request.mapCenter.longitude == request.longitude)
    }

    @Test
    func keepsPoleInCoordinateWhileMapCenterMoves() throws {
        let url = try Self.placesURL(query: "lat=90&lon=0&name=North%20Pole")

        let request = try #require(PlacesLocationRequest(url: url))

        // The pin goes on `coordinate`, exactly where the link says. Only the map centre is capped.
        #expect(request.coordinate.latitude == 90)
        #expect(request.coordinate.longitude == 0)
        #expect(request.mapCenter.latitude == 84.5)
    }

    // MARK: Totality

    /// Thousands of arbitrary inputs from a fixed seed: the same inputs on every run.
    @Test
    func neverTrapsAndOnlyReturnsInRangeLocations() throws {
        var generator = SplitMix64(seed: 2026_10_09)
        let iterations = 2_000
        var acceptedCount = 0

        for _ in 0..<iterations {
            let latitudeText = Self.randomDegreesText(using: &generator)
            let longitudeText = Self.randomDegreesText(using: &generator)
            let rawName = Self.randomText(from: Self.nameAlphabet, maxLength: 120, using: &generator)
            let url = try Self.placesURL(lat: latitudeText, lon: longitudeText, name: rawName)

            guard let request = PlacesLocationRequest(url: url) else {
                continue
            }

            acceptedCount += 1
            #expect((-90...90).contains(request.latitude), "lat=\(latitudeText.debugDescription)")
            #expect((-180...180).contains(request.longitude), "lon=\(longitudeText.debugDescription)")
            #expect((-84.5...84.5).contains(request.mapCenter.latitude), "lat=\(latitudeText.debugDescription)")
            if let name = request.name {
                #expect(Self.isSanitized(name), "name=\(rawName.debugDescription)")
            }
        }

        // Otherwise the loop proves little.
        #expect(acceptedCount >= 100, "accepted \(acceptedCount) of \(iterations)")
        #expect(iterations - acceptedCount >= 100, "rejected \(iterations - acceptedCount) of \(iterations)")
    }

    // MARK: Helpers

    static func placesURL(query: String) throws -> URL {
        try #require(URL(string: "wikipedia://places?" + query))
    }

    /// Builds the link the way a sending app should, with URLComponents, so each value is percent-encoded once.
    static func placesURL(lat: String, lon: String, name: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "wikipedia"
        components.host = "places"
        components.queryItems = [
            URLQueryItem(name: "lat", value: lat),
            URLQueryItem(name: "lon", value: lon),
            URLQueryItem(name: "name", value: name)
        ]
        return try #require(components.url)
    }

    static func isSanitized(_ name: String) -> Bool {
        let hasNoInvisibles = name.unicodeScalars.allSatisfy { scalar in
            let category = scalar.properties.generalCategory
            return category != .control && category != .format
        }
        let isNFC = Array(name.unicodeScalars) == Array(name.precomposedStringWithCanonicalMapping.unicodeScalars)
        let isTrimmed = name == name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.count <= PlacesLocationRequest.maximumNameLength && hasNoInvisibles && isNFC && isTrimmed
    }

    static let digits = (0...9).map { String($0) }
    static let edgeDegrees = ["90", "-90", "180", "-180", "90.000000000000001", "180.000000000000001", "-0", "000"]
    static let junkAlphabet = digits + ["-", "+", ".", ",", "e", "E", "x", "p", "n", "a", "i", "f", " ", "\t", "%", "&", "=", "#", "\u{0665}", "\u{FF15}", "\u{202E}", "\u{200B}", "é", "😀"]
    static let nameAlphabet = ["A", "m", "s", "t", "e", "r", "d", "a", " ", " ", "\t", "\n", "\u{0000}", "\u{0007}", "\u{00A0}", "\u{2028}", "\u{202E}", "\u{200B}", "\u{200D}", "\u{FEFF}", "\u{2066}", "\u{0301}", "e\u{0301}", "é", "+", "%", "&", "=", "#", "日本", "😀", "👨‍👩‍👧"]

    /// Mostly number-shaped text around the grammar's limits, plus edge values and junk.
    private static func randomDegreesText(using generator: inout SplitMix64) -> String {
        switch Int.random(in: 0..<4, using: &generator) {
        case 0:
            return randomText(from: junkAlphabet, maxLength: 12, using: &generator)
        case 1:
            return edgeDegrees.randomElement(using: &generator)!
        default:
            let sign = Bool.random(using: &generator) ? "-" : ""
            let integerPart = randomText(from: digits, length: Int.random(in: 1...4, using: &generator), using: &generator)
            let fractionLength = Int.random(in: 0...17, using: &generator)
            let fraction = fractionLength == 0 ? "" : "." + randomText(from: digits, length: fractionLength, using: &generator)
            return sign + integerPart + fraction
        }
    }

    private static func randomText(from alphabet: [String], maxLength: Int, using generator: inout SplitMix64) -> String {
        randomText(from: alphabet, length: Int.random(in: 0...maxLength, using: &generator), using: &generator)
    }

    private static func randomText(from alphabet: [String], length: Int, using generator: inout SplitMix64) -> String {
        (0..<length).map { _ in alphabet.randomElement(using: &generator)! }.joined()
    }
}

/// Links go through the real Objective-C router, the same way SceneDelegate sends them.
@MainActor struct PlacesLinkRoutingTests {

    @Test(arguments: [
        "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam",
        "wikipedia://places/?lat=52.3547498&lon=4.8339215&name=Amsterdam",
        "wikipedia-official://places?lat=52.3547498&lon=4.8339215&name=Amsterdam"
    ])
    func placesLinkCarriesLocation(_ link: String) throws {
        let activity = try Self.activity(for: link)

        let request = try #require(activity.wmf_placesLocationRequest)

        #expect(activity.wmf_type() == .places)
        #expect(request.latitude == 52.3547498)
        #expect(request.longitude == 4.8339215)
        #expect(request.name == "Amsterdam")
    }

    @Test
    func plainPlacesLinkHasNoLocation() throws {
        let activity = try Self.activity(for: "wikipedia://places")

        #expect(activity.wmf_type() == .places)
        #expect(activity.wmf_linkURL() == nil)
        #expect(activity.wmf_placesLocationRequest == nil)
    }

    @Test
    func invalidLocationStillOpensPlaces() throws {
        let activity = try Self.activity(for: "wikipedia://places?lat=200&lon=10")

        #expect(activity.wmf_type() == .places)
        #expect(activity.wmf_placesLocationRequest == nil)
    }

    /// Wikipedia's own "show on map" link must still open its article.
    @Test
    func showOnMapLinkStillShowsTheArticle() throws {
        let articleURL = try #require(URL(string: "https://en.wikipedia.org/wiki/Amsterdam"))
        let link = NSUserActivity.wmf_URLForActivity(of: .places, withArticleURL: articleURL)

        let activity = try #require(NSUserActivity.wmf_activity(forWikipediaScheme: link))

        #expect(activity.wmf_type() == .places)
        #expect(activity.wmf_linkURL() == articleURL)
        #expect(activity.wmf_placesLocationRequest == nil)
    }

    /// A link with both an article and coordinates opens the article.
    @Test
    func articleTakesPrecedenceOverCoordinates() throws {
        let activity = try Self.activity(for: "wikipedia://places?WMFArticleURL=https://en.wikipedia.org/wiki/Amsterdam&lat=40.4380638&lon=-3.7495758")

        #expect(activity.wmf_linkURL()?.absoluteString == "https://en.wikipedia.org/wiki/Amsterdam")
        #expect(activity.wmf_placesLocationRequest == nil)
    }

    static func activity(for link: String) throws -> NSUserActivity {
        let url = try #require(URL(string: link))
        return try #require(NSUserActivity.wmf_activity(forWikipediaScheme: url))
    }
}

/// SplitMix64: a tiny seeded generator, so a failure reproduces on every run.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
