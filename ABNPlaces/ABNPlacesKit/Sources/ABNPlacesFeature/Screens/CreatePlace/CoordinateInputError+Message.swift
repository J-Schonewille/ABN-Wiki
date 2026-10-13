import ABNPlacesCore
import Foundation

nonisolated extension CoordinateInputError {
    func latitudeMessage(in locale: Locale) -> String {
        switch self {
        case .empty:
            localized("Enter a latitude.", locale: locale, comment: "Error under an empty latitude field.")
        case .notANumber:
            localized(
                "Enter a number, for example 52.3547.",
                locale: locale,
                comment: "Error under a latitude that isn't a number. Use your language's decimal separator."
            )
        case .outOfRange(let range):
            rangeMessage(range, locale: locale)
        }
    }

    func longitudeMessage(in locale: Locale) -> String {
        switch self {
        case .empty:
            localized("Enter a longitude.", locale: locale, comment: "Error under an empty longitude field.")
        case .notANumber:
            localized(
                "Enter a number, for example 4.8339.",
                locale: locale,
                comment: "Error under a longitude that isn't a number. Use your language's decimal separator."
            )
        case .outOfRange(let range):
            rangeMessage(range, locale: locale)
        }
    }

    private func rangeMessage(_ range: ClosedRange<Double>, locale: Locale) -> String {
        let lowest = boundText(range.lowerBound, locale: locale)
        let highest = boundText(range.upperBound, locale: locale)
        return localized(
            "Enter a number between \(lowest) and \(highest).",
            locale: locale,
            comment: "Error under a latitude or longitude out of range, such as “between −90 and 90”."
        )
    }

    /// With a real minus sign ("−180"), not the hyphen that number formatting writes.
    private func boundText(_ value: Double, locale: Locale) -> String {
        let magnitude = value.magnitude.formatted(.number.locale(locale))
        return value < 0 ? "\u{2212}\(magnitude)" : magnitude
    }
}
