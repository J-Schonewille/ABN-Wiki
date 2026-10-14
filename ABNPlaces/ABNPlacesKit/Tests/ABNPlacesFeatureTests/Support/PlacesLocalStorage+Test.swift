import ABNPlacesCore
import Dependencies

extension PlacesLocalStorage {
    /// Like `inMemory`, but counts in `listeners` how often `updates()` is called, so a test can wait until the list
    /// listens.
    static func inMemory(_ places: [Place] = [], listeners: LockIsolated<Int>) -> PlacesLocalStorage {
        var storage = PlacesLocalStorage.inMemory(places)
        let updates = storage.updates
        storage.updates = {
            listeners.withValue { $0 += 1 }
            return updates()
        }
        return storage
    }
}
