import ABNPlacesCore
import Dependencies
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("Places list: created places", .timeLimit(.minutes(1)))
struct PlacesListCreatedPlacesTests {
    @Test("A saved place comes after the feed's places")
    func savedPlaceComesLast() async {
        let storage = PlacesLocalStorage.inMemory()
        let model = Self.model(.scripted(.success([.amsterdam])), storage: storage)
        await model.loadIfNeeded()
        let following = Task { await model.followCreatedPlaces() }
        defer { following.cancel() }

        #expect(storage.save(.mumbai))

        await waitUntil { model.places == [.amsterdam, .mumbai] }
        #expect(model.places == [.amsterdam, .mumbai])
    }

    @Test("A place saved in another window shows here too")
    func placeSavedInAnotherWindow() async {
        let listeners = LockIsolated(0)
        let storage = PlacesLocalStorage.inMemory(listeners: listeners)
        let model = Self.model(.scripted(), storage: storage)
        let otherWindowsSheet = withDependencies {
            $0.placesLocalStorage = storage
        } operation: {
            CreatePlaceModel()
        }
        let following = Task { await model.followCreatedPlaces() }
        defer { following.cancel() }
        await waitUntil { listeners.value == 1 }

        otherWindowsSheet.latitude = "19,0760"
        otherWindowsSheet.longitude = "72,8777"
        guard case .saved(let place) = otherWindowsSheet.save() else {
            Issue.record("The other window didn't save the place")
            return
        }

        await waitUntil { model.places == [place] }
        #expect(model.places == [place])
    }

    // No fetch: one would fail the test.
    @Test("A new list shows the places saved before, as in another window")
    func newListShowsSavedPlaces() {
        let model = Self.model(.scripted(), storage: .inMemory([.mumbai]))

        #expect(model.places == [.mumbai])
    }

    @Test("A saved place that the feed also has shows once")
    func placeInTheFeedShowsOnce() async {
        let model = Self.model(.scripted(.success(.preview)), storage: .inMemory([.amsterdam]))

        await model.loadIfNeeded()

        #expect(model.places == .preview)
    }

    @Test("Saved places show while the feed loads, and after it fails")
    func savedPlacesWithoutTheFeed() async {
        let model = Self.model(.scripted(.failure(.offline)), storage: .inMemory([.mumbai]))
        #expect(model.places == [.mumbai])

        await model.loadIfNeeded()

        #expect(model.content == .failed(.offline))
        #expect(model.places == [.mumbai])
    }

    @Test("A refresh keeps the saved places")
    func refreshKeepsTheSavedPlaces() async {
        let model = Self.model(
            .scripted(.success([.amsterdam]), .success([.copenhagen])),
            storage: .inMemory([.mumbai])
        )
        await model.loadIfNeeded()

        await model.refresh()

        #expect(model.places == [.copenhagen, .mumbai])
    }

    private static func model(_ client: PlacesAPI, storage: PlacesLocalStorage) -> PlacesListModel {
        withDependencies {
            $0.placesAPI = client
            $0.placesLocalStorage = storage
        } operation: {
            PlacesListModel()
        }
    }
}
