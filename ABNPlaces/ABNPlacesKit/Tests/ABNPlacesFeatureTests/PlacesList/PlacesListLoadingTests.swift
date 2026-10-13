import ABNPlacesCore
import Dependencies
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("Places list: loading", .timeLimit(.minutes(1)))
struct PlacesListLoadingTests {
    // MARK: First load

    @Test("A first load shows the places")
    func loadsPlaces() async {
        let model = Self.model(.preview)

        await model.loadIfNeeded()

        #expect(model.content == .loaded(.preview))
        #expect(model.failureCount == 0)
        #expect(model.updateCount == 0)  // The screen appearing with its places isn't announced.
        #expect(!model.isLoading)
    }

    @Test("An empty feed is an empty list, not an error")
    func loadsAnEmptyFeed() async {
        let model = Self.model(.empty)

        await model.loadIfNeeded()

        #expect(model.content == .loaded([]))
        #expect(model.failureCount == 0)
    }

    @Test(
        "A failed first load shows its cause and counts for an announcement",
        arguments: [
            (LocationsError.offline, LoadFailure.offline),
            (.server, .server),
            (.unexpectedData, .unexpectedData),
        ]
    )
    func firstLoadFails(error: LocationsError, expected: LoadFailure) async {
        let model = Self.model(.failing(error))

        await model.loadIfNeeded()

        #expect(model.content == .failed(expected))
        #expect(model.failureCount == 1)
        #expect(!model.isLoading)
    }

    // One fetch only: a second one would fail the test.
    @Test("The screen appearing again after a load doesn't fetch again")
    func appearingAgainDoesNotReload() async {
        let model = Self.model(.scripted(.success(.preview)))

        await model.loadIfNeeded()
        await model.loadIfNeeded()

        #expect(model.content == .loaded(.preview))
    }

    // One fetch only: a second one would fail the test.
    @Test("The screen appearing again doesn't retry a failed load: retrying is the user's call")
    func appearingAgainDoesNotRetry() async {
        let model = Self.model(.scripted(.failure(.offline)))

        await model.loadIfNeeded()
        await model.loadIfNeeded()

        #expect(model.content == .failed(.offline))
        #expect(model.failureCount == 1)
    }

    // MARK: Retry

    @Test("A retry after a failed first load shows the skeleton, then the places")
    func retryAfterFailure() async {
        let gate = Gate<FetchResult>()
        let fetches = LockIsolated(0)
        let model = Self.model(.answering(.failure(.offline), thenGatedBy: gate, counting: fetches))
        await model.loadIfNeeded()
        #expect(model.content == .failed(.offline))

        let retry = Task { await model.refresh() }
        await gate.waitForArrival()
        #expect(model.content == .loading)

        gate.open(with: .success(.preview))
        await retry.value

        #expect(model.content == .loaded(.preview))
        #expect(model.failureCount == 1)
        #expect(model.updateCount == 1)  // VoiceOver hears that the places are back.
        #expect(fetches.value == 2)
    }

    @Test("Every failure counts for an announcement, also the same one twice")
    func repeatedFailureCountsAgain() async {
        let model = Self.model(.scripted(.failure(.offline), .failure(.offline)))

        await model.loadIfNeeded()
        await model.refresh()

        #expect(model.content == .failed(.offline))
        #expect(model.failureCount == 2)
        #expect(model.updateCount == 0)
    }

    // MARK: While a request runs

    @Test("A cancelled first load keeps the skeleton, and loads when the screen is back")
    func cancelledFirstLoadLoadsAgain() async {
        let gate = Gate<FetchResult>()
        let fetches = LockIsolated(0)
        let model = Self.model(.gated(by: gate, counting: fetches))

        let load = Task { await model.loadIfNeeded() }
        await gate.waitForArrival()  // The request is in flight.
        load.cancel()  // What SwiftUI does to `.task` when the screen goes away.
        gate.open(with: .success(.preview))  // A request the cancel missed would now load, not hang.
        await load.value
        #expect(model.content == .loading)
        #expect(!model.isLoading)

        await model.loadIfNeeded()  // The screen is back.

        #expect(model.content == .loaded(.preview))
        #expect(fetches.value == 2)
        #expect(model.updateCount == 0)  // Still the first load, so not announced.
    }

    @Test("A refresh while a request runs does nothing: one fetch")
    func refreshDuringLoadDoesNothing() async {
        let gate = Gate<FetchResult>()
        let fetches = LockIsolated(0)
        let model = Self.model(.gated(by: gate, counting: fetches))

        let load = Task { await model.loadIfNeeded() }
        await gate.waitForArrival()  // The first load's request is in flight.
        await model.refresh()  // Returns straight away.
        #expect(model.isLoading)

        gate.open(with: .success(.preview))
        await load.value

        #expect(model.content == .loaded(.preview))
        #expect(fetches.value == 1)
        #expect(model.updateCount == 0)  // The first load isn't announced.
        #expect(!model.isLoading)
    }

    // MARK: Helpers

    /// A model whose requests go to `client`.
    /// Made inside `withDependencies`, because `@Dependency` reads its values when the model is created, and the
    /// gated clients only exist inside a test.
    private static func model(_ client: LocationsClient) -> PlacesListModel {
        withDependencies {
            $0.locationsClient = client
        } operation: {
            PlacesListModel()
        }
    }
}
