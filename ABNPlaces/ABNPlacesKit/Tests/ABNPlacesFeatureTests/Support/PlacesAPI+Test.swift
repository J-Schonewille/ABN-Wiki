import ABNPlacesCore
import Dependencies
import Testing

typealias FetchResult = Result<[Place], PlacesAPIError>

extension PlacesAPI {
    /// Answers each fetch with the next of `results`, in order. A fetch beyond them fails the test.
    static func scripted(_ results: FetchResult...) -> PlacesAPI {
        let remaining = LockIsolated(results)
        return PlacesAPI { () throws(PlacesAPIError) in
            let next = remaining.withValue { $0.isEmpty ? nil : $0.removeFirst() }
            guard let next else {
                Issue.record("A fetch the test didn't expect")
                throw .server
            }
            return try next.get()
        }
    }

    static func gated(by gate: Gate<FetchResult>, counting fetches: LockIsolated<Int>) -> PlacesAPI {
        PlacesAPI { () async throws(PlacesAPIError) in
            fetches.withValue { $0 += 1 }
            return try await gate.wait().get()
        }
    }

    /// Answers the first fetches with `first`, in order; later ones wait at `gate`.
    static func answering(
        _ first: FetchResult...,
        thenGatedBy gate: Gate<FetchResult>,
        counting fetches: LockIsolated<Int>
    ) -> PlacesAPI {
        PlacesAPI { () async throws(PlacesAPIError) in
            let number = fetches.withValue { count in
                count += 1
                return count
            }
            if number <= first.count {
                return try first[number - 1].get()
            }
            return try await gate.wait().get()
        }
    }
}
