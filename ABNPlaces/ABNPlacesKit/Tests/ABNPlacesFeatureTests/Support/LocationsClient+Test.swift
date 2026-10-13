import ABNPlacesCore
import Dependencies
import Testing

typealias FetchResult = Result<[Place], LocationsError>

extension LocationsClient {
    /// Answers each fetch with the next of `results`, in order. A fetch beyond them fails the test.
    static func scripted(_ results: FetchResult...) -> LocationsClient {
        let remaining = LockIsolated(results)
        return LocationsClient { () throws(LocationsError) in
            let next = remaining.withValue { $0.isEmpty ? nil : $0.removeFirst() }
            guard let next else {
                Issue.record("A fetch the test didn't expect")
                throw .server
            }
            return try next.get()
        }
    }

    /// Every fetch counts itself in `fetches`, then waits at `gate` until the test opens it.
    static func gated(by gate: Gate<FetchResult>, counting fetches: LockIsolated<Int>) -> LocationsClient {
        LocationsClient { () async throws(LocationsError) in
            fetches.withValue { $0 += 1 }
            return try await gate.wait().get()
        }
    }

    /// Every fetch counts itself in `fetches`. The first answers `first` straight away; later ones wait at `gate`
    /// until the test opens it. For a retry in flight.
    static func answering(
        _ first: FetchResult,
        thenGatedBy gate: Gate<FetchResult>,
        counting fetches: LockIsolated<Int>
    ) -> LocationsClient {
        LocationsClient { () async throws(LocationsError) in
            let number = fetches.withValue { count in
                count += 1
                return count
            }
            if number == 1 {
                return try first.get()
            }
            return try await gate.wait().get()
        }
    }
}
