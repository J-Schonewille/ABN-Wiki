import ABNPlacesCore
import Testing

@Suite("Places local storage", .timeLimit(.minutes(1)))
struct PlacesLocalStorageTests {
    @Test("Saved places come back oldest first")
    func keepsTheOrder() {
        let storage = PlacesLocalStorage.inMemory()

        #expect(storage.save(.mumbai))
        #expect(storage.save(.amsterdam))

        #expect(storage.places() == [.mumbai, .amsterdam])
    }

    @Test("A place with the same id is saved once")
    func savesAPlaceOnce() {
        let storage = PlacesLocalStorage.inMemory([.mumbai])

        #expect(!storage.save(.mumbai))

        #expect(storage.places() == [.mumbai])
    }

    @Test("Updates start with the saved places, then follow every save")
    func updatesFollowEverySave() async {
        let storage = PlacesLocalStorage.inMemory([.mumbai])
        var updates = storage.updates().makeAsyncIterator()

        #expect(await updates.next() == [.mumbai])
        #expect(storage.save(.amsterdam))
        #expect(await updates.next() == [.mumbai, .amsterdam])
    }

    @Test("Every window gets the updates")
    func everyWindowGetsTheUpdates() async {
        let storage = PlacesLocalStorage.inMemory()
        var first = storage.updates().makeAsyncIterator()
        var second = storage.updates().makeAsyncIterator()

        #expect(storage.save(.mumbai))

        #expect(await first.next() == [])
        #expect(await first.next() == [.mumbai])
        #expect(await second.next() == [])
        #expect(await second.next() == [.mumbai])
    }

    @Test("Saving a place that is there already sends no update")
    func noUpdateForADuplicate() async {
        let storage = PlacesLocalStorage.inMemory([.mumbai])
        var updates = storage.updates().makeAsyncIterator()
        #expect(await updates.next() == [.mumbai])

        #expect(!storage.save(.mumbai))
        #expect(storage.save(.amsterdam))

        #expect(await updates.next() == [.mumbai, .amsterdam])
    }
}
