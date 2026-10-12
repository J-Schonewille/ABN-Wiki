#if DEBUG
// The real feed's four places, with its exact values, for previews, tests and the DEBUG launch scenarios.
extension Place {
    public static let amsterdam = Place(fixtureName: "Amsterdam", latitude: 52.3547498, longitude: 4.8339215)
    public static let mumbai = Place(fixtureName: "Mumbai", latitude: 19.0823998, longitude: 72.8111468)
    public static let copenhagen = Place(fixtureName: "Copenhagen", latitude: 55.6713442, longitude: 12.523785)
    /// The feed's fourth place, which has no name.
    public static let unnamedMadrid = Place(fixtureName: nil, latitude: 40.4380638, longitude: -3.7495758)

    private init(fixtureName name: String?, latitude: Double, longitude: Double) {
        guard let coordinate = Coordinate(latitude: latitude, longitude: longitude) else {
            preconditionFailure("Fixture coordinate out of range: \(latitude), \(longitude)")
        }
        self.init(name: name, coordinate: coordinate)
    }
}

extension [Place] {
    /// The real feed's places, in the feed's order.
    public static var preview: [Place] {
        [.amsterdam, .mumbai, .copenhagen, .unnamedMadrid]
    }
}
#endif
