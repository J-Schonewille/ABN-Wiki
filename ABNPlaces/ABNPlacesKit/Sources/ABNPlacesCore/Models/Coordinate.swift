import Foundation

public struct Coordinate: Hashable, Sendable {
    static let latitudeRange: ClosedRange<Double> = -90...90
    static let longitudeRange: ClosedRange<Double> = -180...180

    public let latitude: Double
    public let longitude: Double

    public init?(latitude: Double, longitude: Double) {
        // The range check also rejects NaN and infinity
        guard Self.latitudeRange.contains(latitude), Self.longitudeRange.contains(longitude) else {
            return nil
        }
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension Coordinate {
    // The latitude as text for URLs and ids. See "machineReadable(_:)".
    var latitudeText: String { Self.machineReadable(latitude) }

    // The longitude as text for URLs and ids. See "machineReadable(_:)".
    var longitudeText: String { Self.machineReadable(longitude) }

    // to make it locale independent, otherwise the locale format could mess up what wikipedia expects
    static func machineReadable(_ degrees: Double) -> String {
        let text = degrees.formatted(machineReadableStyle)
        // A negative value that rounds to zero, and -0.0 itself, format as "-0". It's the same place as "0".
        return text == "-0" ? "0" : text
    }

    private static let machineReadableStyle = FloatingPointFormatStyle<Double>.number
        .locale(Locale(identifier: "en_US_POSIX"))
        .precision(.fractionLength(0...7))
        .grouping(.never)
}
