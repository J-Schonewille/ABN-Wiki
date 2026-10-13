import ABNPlacesCore
import Dependencies
import Observation

@Observable
final class PlacesListModel {
    nonisolated enum Content: Equatable, Sendable {
        case loading
        case loaded([Place])
        case failed(LoadFailure)
    }

    private(set) var content: Content = .loading
    /// Why the last refresh failed; the earlier places stay. Nil once a refresh works.
    private(set) var refreshFailure: LoadFailure?
    /// Saved with the create-place sheet, in any window.
    private(set) var createdPlaces: [Place] = []
    private(set) var isLoading = false
    private(set) var failureCount = 0
    private(set) var updateCount = 0

    let opener = WikipediaOpener()

    @ObservationIgnored @Dependency(\.placesAPI) private var placesAPI
    @ObservationIgnored @Dependency(\.placesLocalStorage) private var placesLocalStorage

    init() {
        createdPlaces = placesLocalStorage.places()
    }

    /// Loads the first time only: after a failure, retrying is the user's call.
    func loadIfNeeded() async {
        guard content == .loading else { return }
        await load()
    }

    /// Does nothing while a request runs.
    func refresh() async {
        await load()
    }

    /// The feed's places, then the saved ones that aren't in the feed.
    var places: [Place] {
        let feed: [Place] = if case .loaded(let places) = content { places } else { [] }
        let feedIDs = Set(feed.map(\.id))
        return feed + createdPlaces.filter { !feedIDs.contains($0.id) }
    }

    /// Shows the places saved in any window, until the screen goes away.
    func followCreatedPlaces() async {
        for await places in placesLocalStorage.updates() {
            createdPlaces = places
        }
    }

    /// A tap on a card. Two quick taps open Wikipedia once.
    @discardableResult
    func open(_ place: Place) async -> WikipediaOpener.Outcome {
        await opener.open(place)
    }
}

private extension PlacesListModel {
    func load() async {
        guard !isLoading else { return }
        let isFirstLoad = content == .loading
        if case .failed = content {
            content = .loading  // A retry shows the skeleton again.
        }
        isLoading = true
        defer { isLoading = false }

        do throws(PlacesAPIError) {
            let places = try await placesAPI.fetch()
            content = .loaded(places)
            refreshFailure = nil
            if !isFirstLoad {
                updateCount += 1
            }
        } catch {
            // Nil for `.cancelled`: the screen left during the first load, and it loads again on return.
            guard let failure = LoadFailure(error) else { return }
            if case .loaded = content {
                refreshFailure = failure  // Keeps the places on screen.
            } else {
                content = .failed(failure)
            }
            failureCount += 1
        }
    }
}
