import ABNPlacesCore
import Dependencies
import SwiftUI
import Testing

@testable import ABNPlacesFeature

/// The places screen in every state: what it looks like, and what VoiceOver gets from it.
/// Each model gets its state first, by awaiting its load, so no snapshot depends on `.task` running.
@MainActor
@Suite("PlacesListView snapshots")
struct PlacesListViewTests {
    @Test("Loaded: a card per place, Refresh, and Add place", arguments: ScreenVariant.allCases)
    func loaded(_ variant: ScreenVariant) async {
        let screen = Self.screen(await Self.model(loadedFrom: .preview))

        assertScreenSnapshot(of: screen, as: variant, named: "places-list", state: "loaded-\(variant)")
    }

    @Test(
        "Loaded, for VoiceOver: one button per place, Add place, Refresh and the title",
        arguments: [ScreenVariant.light, .ax5]
    )
    func loadedAccessibility(_ variant: ScreenVariant) async {
        let screen = Self.screen(await Self.model(loadedFrom: .preview))

        assertScreenAccessibilitySnapshot(of: screen, as: variant, named: "places-list", state: "loaded-\(variant)")
    }

    @Test("Loading: the placeholders, read as one element, \"Loading places\"", .timeLimit(.minutes(1)))
    func loading() async {
        // A fetch that answers once the snapshots are taken.
        let (snapshotsTaken, finishSnapshots) = AsyncStream.makeStream(of: Void.self)
        let model = Self.model(
            fetchingFrom: PlacesAPI { () async throws(PlacesAPIError) in
                for await _ in snapshotsTaken {}
                return []
            }
        )
        // Waits until the load has started, so the snapshots show the placeholders.
        let load = Task { await model.loadIfNeeded() }
        while !model.isLoading, !Task.isCancelled {
            await Task.yield()
        }
        let screen = Self.screen(model)

        assertScreenSnapshot(of: screen, named: "places-list", state: "loading")
        assertScreenAccessibilitySnapshot(of: screen, named: "places-list", state: "loading")

        finishSnapshots.finish()
        await load.value
    }

    @Test("First load failed: the heading, the message and Retry, and Add place stays")
    func offline() async {
        let screen = Self.screen(await Self.model(loadedFrom: .failing(.offline)))

        assertScreenSnapshot(of: screen, named: "places-list", state: "offline")
        assertScreenAccessibilitySnapshot(of: screen, named: "places-list", state: "offline")
    }

    @Test("Empty: a heading, a message, and Add place")
    func empty() async {
        let screen = Self.screen(await Self.model(loadedFrom: .empty))

        assertScreenSnapshot(of: screen, named: "places-list", state: "empty")
        assertScreenAccessibilitySnapshot(of: screen, named: "places-list", state: "empty")
    }

    @Test("Refresh failed: the banner and its Retry above the earlier places")
    func refreshFailed() async {
        let model = await Self.model(loadedFrom: Self.placesThenOffline())
        await model.refresh()
        let screen = Self.screen(model)

        assertScreenSnapshot(of: screen, named: "places-list", state: "refresh-failed")
        assertScreenAccessibilitySnapshot(of: screen, named: "places-list", state: "refresh-failed")
    }

    @Test("A created place: after the feed's places, like any other card")
    func createdPlace() async throws {
        let coordinate = try #require(Coordinate(latitude: 52.358, longitude: 4.8686))
        let model = withDependencies {
            $0.placesAPI = .preview
            $0.placesLocalStorage = .inMemory([Place(name: "Vondelpark", coordinate: coordinate)])
        } operation: {
            PlacesListModel()
        }
        await model.loadIfNeeded()
        let screen = Self.screen(model)

        assertScreenSnapshot(of: screen, named: "places-list", state: "created-place")
        assertScreenAccessibilitySnapshot(of: screen, named: "places-list", state: "created-place")
    }

    // No Refresh in the legend: UIKit drops a bar button past the iPhone host's screen edge. A real iPad has it.
    @Test("iPad at regular width: the cards in a grid, read row by row")
    func iPad() async {
        let screen = Self.screen(await Self.model(loadedFrom: .preview))

        assertScreenSnapshot(of: screen, on: .iPadPortrait, named: "places-list", state: "ipad")
        assertScreenAccessibilitySnapshot(of: screen, on: .iPadPortrait, named: "places-list", state: "ipad")
    }

    // MARK: Helpers

    /// A model that has finished its first load from `client`.
    private static func model(loadedFrom client: PlacesAPI) async -> PlacesListModel {
        let model = Self.model(fetchingFrom: client)
        await model.loadIfNeeded()
        return model
    }

    private static func model(fetchingFrom client: PlacesAPI) -> PlacesListModel {
        withDependencies {
            $0.placesAPI = client
        } operation: {
            PlacesListModel()
        }
    }

    private static func placesThenOffline() -> PlacesAPI {
        let fetches = LockIsolated(0)
        return PlacesAPI { () throws(PlacesAPIError) in
            let fetch = fetches.withValue { count in
                count += 1
                return count
            }
            guard fetch > 1 else { return .preview }
            throw .offline
        }
    }

    private static func screen(_ model: PlacesListModel) -> some View {
        NavigationStack {
            PlacesListView(model: model)
        }
    }
}
