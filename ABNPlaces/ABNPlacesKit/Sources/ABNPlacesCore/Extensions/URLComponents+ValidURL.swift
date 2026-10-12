import Foundation

extension URLComponents {

    /// The URL of components that are valid by construction.
    ///
    /// `url` is only nil when the path conflicts with the authority, such as a host with a path that doesn't start
    /// with "/". Callers set the scheme, host and path from constants, and a query item can't make it nil, whatever
    /// its value: `URLComponents` percent-encodes it. So nil would be a programming error, not a runtime condition.
    var validURL: URL {
        guard let url else {
            preconditionFailure("Invalid URL components: \(self)")
        }
        return url
    }
}
