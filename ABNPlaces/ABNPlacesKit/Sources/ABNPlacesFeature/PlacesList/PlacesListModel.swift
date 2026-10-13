import ABNPlacesCore
import Dependencies
import Observation

/// What the places screen shows, and what it can do: load the feed, try again, and open a place in Wikipedia.
@Observable
final class PlacesListModel {
    nonisolated enum Content: Equatable, Sendable {
        case loading
        case loaded([Place])
        case failed(LoadFailure)
    }

    private(set) var content: Content = .loading
    private(set) var isLoading = false
    private(set) var failureCount = 0
    private(set) var updateCount = 0

    /// Opens places in Wikipedia, and holds the "Wikipedia isn't installed" alert.
    let opener = WikipediaOpener()

    @ObservationIgnored @Dependency(\.locationsClient) private var locationsClient

    /// The screen appeared. Loads the first time only: after a failure, trying again is the user's call.
    func loadIfNeeded() async {
        guard content == .loading else { return }
        await load()
    }

    /// Retry: loads again, unless a request is already running.
    func refresh() async {
        await load()
    }

    /// A tap on a card. Two quick taps open Wikipedia once.
    @discardableResult
    func open(_ place: Place) async -> WikipediaOpener.Outcome {
        await opener.open(place)
    }
}

private extension PlacesListModel {
    /// Runs one request at a time: a call while one runs returns straight away.
    func load() async {
        guard !isLoading else { return }
        let isFirstLoad = content == .loading
        if case .failed = content {
            content = .loading  // A retry shows the skeleton again.
        }
        isLoading = true
        defer { isLoading = false }

        do throws(LocationsError) {
            let places = try await locationsClient.fetch()
            content = .loaded(places)
            if !isFirstLoad {
                updateCount += 1
            }
        } catch {
            // Nil for `.cancelled`: the screen went away.
            guard let failure = LoadFailure(error) else { return }
            content = .failed(failure)
            failureCount += 1
        }
    }
}
