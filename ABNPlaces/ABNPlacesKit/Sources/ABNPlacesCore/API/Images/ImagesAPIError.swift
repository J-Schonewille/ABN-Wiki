/// Why there's no thumbnail. A card shows its map pin tile in every case.
public enum ImagesAPIError: Error, Equatable, Sendable {
    case offline
    case server
    case unexpectedData
    /// No article matches the name, or the best match has no image.
    case noResult
    case cancelled
}
