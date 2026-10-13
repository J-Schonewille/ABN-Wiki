import ABNPlacesCore
import Foundation
import Testing

@testable import ABNPlacesFeature

/// The expected strings use the real minus sign "−" (U+2212), which looks like the hyphen "-".
@Suite("Coordinate input error messages")
struct CoordinateInputErrorMessageTests {
    @Test(
        "Latitude out of range, with a real minus sign",
        arguments: [
            ("en_US", "Enter a number between −90 and 90."),
            ("nl_NL", "Vul een getal tussen −90 en 90 in."),
        ]
    )
    func latitudeOutOfRange(locale: String, expected: String) {
        let error = CoordinateInputError.outOfRange(-90...90)

        #expect(error.latitudeMessage(in: Locale(identifier: locale)) == expected)
    }

    @Test(
        "Longitude out of range, with a real minus sign",
        arguments: [
            ("en_US", "Enter a number between −180 and 180."),
            ("nl_NL", "Vul een getal tussen −180 en 180 in."),
        ]
    )
    func longitudeOutOfRange(locale: String, expected: String) {
        let error = CoordinateInputError.outOfRange(-180...180)

        #expect(error.longitudeMessage(in: Locale(identifier: locale)) == expected)
    }

    @Test(
        "An empty field or text that isn't a number, in Dutch with a comma",
        arguments: [
            (CoordinateInputError.empty, "Vul een breedtegraad in."),
            (.notANumber, "Vul een getal in, bijvoorbeeld 52,3547."),
        ]
    )
    func dutchLatitude(error: CoordinateInputError, expected: String) {
        #expect(error.latitudeMessage(in: Locale(identifier: "nl_NL")) == expected)
    }
}
