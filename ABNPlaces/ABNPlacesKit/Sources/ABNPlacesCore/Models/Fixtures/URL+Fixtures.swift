#if DEBUG
import Foundation

// A place photo from this package's resources, for previews and tests. A file URL, so `AsyncImage` loads it too.
extension URL {
    public static let placeStubImage: URL = {
        guard let url = Bundle.module.url(forResource: "place_stub", withExtension: "jpg") else {
            preconditionFailure("place_stub.jpg is missing from ABNPlacesCore's resources")
        }
        return url
    }()
}
#endif
