public enum PlacesAPIError: Error, Equatable, Sendable {
    case offline
    case server
    case unexpectedData
    case cancelled
}
