public enum LocationsError: Error, Equatable, Sendable {
    case offline
    case server
    case unexpectedData
    case cancelled
}
