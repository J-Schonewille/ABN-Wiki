internal import ABNLogging
import Foundation
import os

/// Decodes a JSON body into `T`, always off the caller's actor.
/// With `NonisolatedNonsendingByDefault`, async code runs on
/// the caller's actor. `@concurrent` makes sure it never runs on the main actor.
@concurrent
public func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) async throws(NetworkError) -> T {
    do {
        return try JSONDecoder().decode(type, from: data)
    } catch {
        let typeName = String(describing: type)
        let reason = String(describing: error)
        Logger.network.error("Decoding \(typeName, privacy: .public) failed: \(reason, privacy: .private)")
        throw .decoding
    }
}
