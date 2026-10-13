import ABNPlacesCore
import Foundation
import Testing

@testable import ABNPlacesFeature

@Suite("Coordinate formatter")
struct CoordinateFormatterTests {
    struct Example: Sendable, CustomTestStringConvertible {
        let latitude: Double
        let longitude: Double
        let locale: String
        let text: String
        let spoken: String

        var testDescription: String { "\(locale): \(text)" }
    }

    static let examples: [Example] = [
        // The feed's places: north and east, then the unnamed Madrid, west of Greenwich.
        Example(
            latitude: 52.3547498, longitude: 4.8339215, locale: "en_US",
            text: "52.3547° N, 4.8339° E", spoken: "52.35 degrees north, 4.83 degrees east"
        ),
        Example(
            latitude: 52.3547498, longitude: 4.8339215, locale: "nl_NL",
            text: "52,3547° N, 4,8339° O", spoken: "52,35 graden noord, 4,83 graden oost"
        ),
        Example(
            latitude: 40.4380638, longitude: -3.7495758, locale: "en_US",
            text: "40.4381° N, 3.7496° W", spoken: "40.44 degrees north, 3.75 degrees west"
        ),
        Example(
            latitude: 40.4380638, longitude: -3.7495758, locale: "nl_NL",
            text: "40,4381° N, 3,7496° W", spoken: "40,44 graden noord, 3,75 graden west"
        ),
        // The southern hemisphere: Ushuaia. Dutch writes south as Z (zuid).
        Example(
            latitude: -54.8019, longitude: -68.303, locale: "en_US",
            text: "54.8019° S, 68.3030° W", spoken: "54.80 degrees south, 68.30 degrees west"
        ),
        Example(
            latitude: -54.8019, longitude: -68.303, locale: "nl_NL",
            text: "54,8019° Z, 68,3030° W", spoken: "54,80 graden zuid, 68,30 graden west"
        ),
        // The ends of the ranges.
        Example(
            latitude: 90, longitude: -180, locale: "en_US",
            text: "90.0000° N, 180.0000° W", spoken: "90.00 degrees north, 180.00 degrees west"
        ),
        // Zero has no hemisphere, also a value that only rounds to zero.
        Example(
            latitude: 0, longitude: -0.00004, locale: "en_US",
            text: "0.0000°, 0.0000°", spoken: "0.00 degrees, 0.00 degrees"
        ),
        // Negative zero, and 0.00005, which rounds half to even: no hemisphere either.
        Example(
            latitude: -0.0, longitude: 0.00005, locale: "en_US",
            text: "0.0000°, 0.0000°", spoken: "0.00 degrees, 0.00 degrees"
        ),
        // Just past half, on both sides: the number and the hemisphere round the same way.
        Example(
            latitude: -0.00006, longitude: 0.00006, locale: "en_US",
            text: "0.0001° S, 0.0001° E", spoken: "0.00 degrees, 0.00 degrees"
        ),
        // Rounding decides per precision: shown as north, spoken as zero.
        Example(
            latitude: 0.004, longitude: 0.0001, locale: "nl_NL",
            text: "0,0040° N, 0,0001° O", spoken: "0,00 graden, 0,00 graden"
        ),
    ]

    @Test("On screen: hemisphere letters and the locale's decimal separator", arguments: examples)
    func text(_ example: Example) throws {
        let coordinate = try #require(Coordinate(latitude: example.latitude, longitude: example.longitude))
        let formatter = CoordinateFormatter(locale: Locale(identifier: example.locale))

        #expect(formatter.text(for: coordinate) == example.text)
    }

    @Test("VoiceOver: words instead of N, S, E and W", arguments: examples)
    func spokenText(_ example: Example) throws {
        let coordinate = try #require(Coordinate(latitude: example.latitude, longitude: example.longitude))
        let formatter = CoordinateFormatter(locale: Locale(identifier: example.locale))

        #expect(formatter.spokenText(for: coordinate) == example.spoken)
    }

    @Test("A language the app isn't translated into keeps its own number format")
    func untranslatedLocaleKeepsItsNumbers() throws {
        let coordinate = try #require(Coordinate(latitude: 52.3547498, longitude: 4.8339215))
        let formatter = CoordinateFormatter(locale: Locale(identifier: "de_DE"))

        // The words come from the app's own language (English or Dutch), so only the numbers are checked.
        #expect(formatter.text(for: coordinate).hasPrefix("52,3547° N, 4,8339° "))
        #expect(formatter.spokenText(for: coordinate).hasPrefix("52,35 "))
    }
}
