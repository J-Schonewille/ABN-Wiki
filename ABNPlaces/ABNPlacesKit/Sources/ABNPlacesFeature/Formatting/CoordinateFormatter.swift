import ABNPlacesCore
import Foundation

/// Writes a coordinate for people, in their language.
/// |VoiceOver | "52.35 degrees north, 4.83 degrees east" | "52,35 graden noord, 4,83 graden oost" |
/// - On screen 4 decimals (about 10 m), spoken 2 decimals (about 1 km), so it stays short to listen to.
/// Only for showing: links and ids use ABNPlacesCore's fixed format, which people never see.
nonisolated struct CoordinateFormatter {
    /// The language and number format. Views pass `@Environment(\.locale)`.
    let locale: Locale

    /// `52.3547° N, 4.8339° E`.
    func text(for coordinate: Coordinate) -> String {
        pair(
            latitudeText(Degrees(coordinate.latitude, fractionLength: 4, locale: locale)),
            longitudeText(Degrees(coordinate.longitude, fractionLength: 4, locale: locale))
        )
    }

    /// "52.35 degrees north, 4.83 degrees east", for VoiceOver.
    func spokenText(for coordinate: Coordinate) -> String {
        pair(
            spokenLatitude(Degrees(coordinate.latitude, fractionLength: 2, locale: locale)),
            spokenLongitude(Degrees(coordinate.longitude, fractionLength: 2, locale: locale))
        )
    }

    private func pair(_ latitude: String, _ longitude: String) -> String {
        localized(
            "\(latitude), \(longitude)",
            locale: locale,
            comment: "A label in two parts, already written out: latitude and longitude, or name and coordinates."
        )
    }

    private func latitudeText(_ degrees: Degrees) -> String {
        let number = degrees.number
        return switch degrees.side {
        case .positive:
            localized("\(number)° N", locale: locale, comment: "A latitude north of the equator, such as 52.3547° N.")
        case .negative:
            localized("\(number)° S", locale: locale, comment: "A latitude south of the equator, such as 54.8019° S.")
        case .zero:
            localized("\(number)°", locale: locale, comment: "Zero degrees: on the equator or the prime meridian.")
        }
    }

    private func longitudeText(_ degrees: Degrees) -> String {
        let number = degrees.number
        return switch degrees.side {
        case .positive:
            localized("\(number)° E", locale: locale, comment: "A longitude east of Greenwich, such as 4.8339° E.")
        case .negative:
            localized("\(number)° W", locale: locale, comment: "A longitude west of Greenwich, such as 3.7496° W.")
        case .zero:
            localized("\(number)°", locale: locale, comment: "Zero degrees: on the equator or the prime meridian.")
        }
    }

    private func spokenLatitude(_ degrees: Degrees) -> String {
        let number = degrees.number
        return switch degrees.side {
        case .positive:
            localized("\(number) degrees north", locale: locale, comment: "Spoken by VoiceOver: a latitude north.")
        case .negative:
            localized("\(number) degrees south", locale: locale, comment: "Spoken by VoiceOver: a latitude south.")
        case .zero:
            localized("\(number) degrees", locale: locale, comment: "Spoken by VoiceOver: zero degrees.")
        }
    }

    private func spokenLongitude(_ degrees: Degrees) -> String {
        let number = degrees.number
        return switch degrees.side {
        case .positive:
            localized("\(number) degrees east", locale: locale, comment: "Spoken by VoiceOver: a longitude east.")
        case .negative:
            localized("\(number) degrees west", locale: locale, comment: "Spoken by VoiceOver: a longitude west.")
        case .zero:
            localized("\(number) degrees", locale: locale, comment: "Spoken by VoiceOver: zero degrees.")
        }
    }
}

/// A coordinate value as a number without a sign, and which side of zero it's on once rounded.
nonisolated private struct Degrees {
    enum Side {
        case positive, negative, zero
    }

    let number: String
    let side: Side

    init(_ value: Double, fractionLength: Int, locale: Locale) {
        let rule = FloatingPointRoundingRule.toNearestOrEven
        let style = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(fractionLength))
            .rounded(rule: rule)
            .grouping(.never)
            .locale(locale)
        number = abs(value).formatted(style)
        // The side is decided after rounding the same way, so "0.0000" never
        let scale = pow(10, Double(fractionLength))
        let rounded = (value * scale).rounded(rule)
        side = rounded > 0 ? .positive : rounded < 0 ? .negative : .zero
    }
}
