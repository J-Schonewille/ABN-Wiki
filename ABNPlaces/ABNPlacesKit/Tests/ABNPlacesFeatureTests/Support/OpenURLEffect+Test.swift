import Dependencies
import Foundation

extension OpenURLEffect {
    /// Records each URL it's asked to open in `opened`, then answers with `answer()`: true like when Wikipedia opens
    /// it, false like when Wikipedia isn't installed. `{ await gate.wait() }` holds the open until the test lets it go.
    static func recording(
        into opened: LockIsolated<[URL]>,
        answer: @escaping @Sendable () async -> Bool
    ) -> OpenURLEffect {
        OpenURLEffect { url in
            opened.withValue { $0.append(url) }
            return await answer()
        }
    }
}
