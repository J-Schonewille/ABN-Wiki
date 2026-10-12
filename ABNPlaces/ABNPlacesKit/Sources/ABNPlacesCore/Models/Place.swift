// A location to show, with or without a name.
public struct Place: Identifiable, Hashable, Sendable {
    // a "strong" ID tied to the actual name & coordinate, so swiftUI can handle reloading & refreshing etc
    public let id: String
    public let name: String?  // non empty name
    public let coordinate: Coordinate

    /// - Parameter name: Trimmed. An empty or whitespace-only name becomes nil.
    public init(name: String?, coordinate: Coordinate) {
        let name = name?.trimmedNonEmpty
        self.id = [coordinate.latitudeText, coordinate.longitudeText, name].compactMap { $0 }.joined(separator: ",")
        self.name = name
        self.coordinate = coordinate
    }
}
