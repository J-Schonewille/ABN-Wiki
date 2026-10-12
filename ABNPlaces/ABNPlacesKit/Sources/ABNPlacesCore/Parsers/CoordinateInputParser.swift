import Foundation

public enum CoordinateInputError: Error, Equatable, Sendable {
    case empty
    case notANumber
    case outOfRange(ClosedRange<Double>)
}

/// Turns text a person typed into degrees, whether they write Dutch or English decimals.
///
/// Accepted: an optional minus (`-`, or the typographic `−` U+2212), digits, and at most one decimal separator,
/// which may be a comma or a dot: `52,3547`, `52.3547`, `-3.75`, `−3.75`. Surrounding whitespace is ignored.
/// A single separator is always the decimal separator; coordinates never need grouping. Everything else is
/// rejected: grouping (`1.234,5`), several separators, exponents (`5e1`), hex, `nan`, `inf` and letters.
///
/// It doesn't use a locale's `NumberFormatter`. In Dutch the dot is the grouping separator, so lenient parsing
/// reads `52.3547` as `523547`.
public enum CoordinateInputParser {
    // Degrees in -90...90.
    public static func latitude(from text: String) throws(CoordinateInputError) -> Double {
        try degrees(from: text, in: Coordinate.latitudeRange)
    }

    // Degrees in -180...180.
    public static func longitude(from text: String) throws(CoordinateInputError) -> Double {
        try degrees(from: text, in: Coordinate.longitudeRange)
    }

    private static func degrees(
        from text: String,
        in range: ClosedRange<Double>
    ) throws(CoordinateInputError) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw .empty
        }

        let normalized =
            trimmed
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: ",", with: ".")
        // The shape is checked first: Double(_:) alone also accepts "5e1", "0x1p3", "nan" and "inf".
        guard normalized.wholeMatch(of: #/-?[0-9]+(?:\.[0-9]+)?/#) != nil, let value = Double(normalized) else {
            throw .notANumber
        }
        // Many digits can still overflow to infinity, which the range check rejects too.
        guard range.contains(value) else {
            throw .outOfRange(range)
        }
        return value
    }
}
