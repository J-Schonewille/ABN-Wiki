import Foundation

/// Why a request failed.
public enum NetworkError: Error, Equatable, Sendable {
    /// The device can't reach the server: there's no connection, it dropped, mobile data is off, etc
    case offline
    /// The server didn't answer in time.
    case timedOut
    /// Our task was cancelled, because whoever asked went away. Not an error to show.
    case cancelled
    /// The server answered with a status outside 200...299.
    case server(statusCode: Int)
    /// The answer wasn't an HTTP response.
    case invalidResponse
    /// Any other failure, such as a failed TLS handshake. Unlike `.offline`, checking the connection won't fix it.
    case transport(code: URLError.Code)
    /// The body isn't the JSON we expected. The details go to the log, so this case stays simple to compare.
    case decoding
}

extension NetworkError {
    /// Turns an error from `URLSession`, or from a cancelled task, into a `NetworkError`.
    init(_ error: any Error) {
        switch error {
        case is CancellationError:
            self = .cancelled
        case let urlError as URLError:
            switch urlError.code {
            // A host we can't find or connect to counts as offline too: for the one public host this app calls,
            // that's the network (a dead Wi-Fi, a captive portal), not the server.
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff,
                .callIsActive, .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost:
                self = .offline
            case .timedOut:
                self = .timedOut
            case .cancelled:
                self = .cancelled
            default:
                self = .transport(code: urlError.code)
            }
        default:
            // URLSession only throws URLError, so this is just a safety net.
            self = .transport(code: .unknown)
        }
    }
}
