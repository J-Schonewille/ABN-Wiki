import Dependencies
import DependenciesMacros

/// The places people save with the create-place sheet. In memory only: they last until the app quits.
@DependencyClient
public struct PlacesLocalStorage: Sendable {
    /// The saved places, oldest first.
    public var places: @Sendable () -> [Place] = { [] }
    /// The saved places now, then again after every save.
    public var updates: @Sendable () -> AsyncStream<[Place]> = { .finished }
    /// Returns false when a place with the same id is saved already.
    public var save: @Sendable (_ place: Place) -> Bool = { _ in false }
}

extension PlacesLocalStorage: DependencyKey {
    /// One storage for the whole app, so every window shows the same places.
    public static let liveValue = PlacesLocalStorage.inMemory()

    /// Starts empty in each test. The cases of a parameterized test share it.
    public static var testValue: PlacesLocalStorage { .inMemory() }
}

extension DependencyValues {
    public var placesLocalStorage: PlacesLocalStorage {
        get { self[PlacesLocalStorage.self] }
        set { self[PlacesLocalStorage.self] = newValue }
    }
}

extension PlacesLocalStorage {
    public static func inMemory(_ places: [Place] = []) -> PlacesLocalStorage {
        let state = LockIsolated(State(places: places))
        return PlacesLocalStorage(
            places: { state.value.places },
            updates: {
                let (stream, continuation) = AsyncStream.makeStream(of: [Place].self)
                let id = state.withValue { state in
                    state.nextListenerID += 1
                    state.listeners[state.nextListenerID] = continuation
                    continuation.yield(state.places)
                    return state.nextListenerID
                }
                continuation.onTermination = { _ in
                    state.withValue { _ = $0.listeners.removeValue(forKey: id) }
                }
                return stream
            },
            save: { place in
                state.withValue { state in
                    guard !state.places.contains(where: { $0.id == place.id }) else { return false }
                    state.places.append(place)
                    for listener in state.listeners.values {
                        listener.yield(state.places)
                    }
                    return true
                }
            }
        )
    }

    private struct State {
        var places: [Place]
        var listeners: [Int: AsyncStream<[Place]>.Continuation] = [:]
        var nextListenerID = 0
    }
}
