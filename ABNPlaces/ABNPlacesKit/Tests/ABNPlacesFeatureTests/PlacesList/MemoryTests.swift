import ABNPlacesCore
import Dependencies
import Testing

@testable import ABNPlacesFeature

/// Swift 6 catches data races, not retain cycles. These tests check that the model, and the opener it owns, are
/// released once their work is done.
/// Each test creates the model in a `do` block, keeps a `weak` reference, finishes the work, then checks after the
/// block that the reference is nil. A cycle, such as a stored closure or an opener that holds the model, keeps it
/// alive and fails the check.
@MainActor
@Suite("Memory: the list model is released", .timeLimit(.minutes(1)))
struct MemoryTests {
    @Test("After a load")
    func afterLoad() async {
        weak var weakModel: PlacesListModel?
        do {
            let model = withDependencies {
                $0.locationsClient = .preview
            } operation: {
                PlacesListModel()
            }
            weakModel = model

            await model.loadIfNeeded()

            #expect(model.content == .loaded(.preview))
        }
        #expect(weakModel == nil)
    }

    @Test("With its opener, after opening a place", arguments: [true, false])
    func afterOpening(wikipediaInstalled: Bool) async {
        weak var weakModel: PlacesListModel?
        weak var weakOpener: WikipediaOpener?
        do {
            let model = withDependencies {
                $0.openURL = OpenURLEffect { _ in wikipediaInstalled }
            } operation: {
                PlacesListModel()
            }
            weakModel = model
            weakOpener = model.opener

            let outcome = await model.open(.amsterdam)

            #expect(outcome == (wikipediaInstalled ? .opened : .notInstalled))
        }
        #expect(weakModel == nil)
        #expect(weakOpener == nil)
    }

    @Test("After a cancelled load")
    func afterCancelledLoad() async {
        weak var weakModel: PlacesListModel?
        let gate = Gate<FetchResult>()
        let load: Task<Void, Never>
        do {
            let model = withDependencies {
                $0.locationsClient = .gated(by: gate, counting: LockIsolated(0))
            } operation: {
                PlacesListModel()
            }
            weakModel = model
            load = Task { await model.loadIfNeeded() }
        }
        await gate.waitForArrival()
        load.cancel()  // What SwiftUI does to `.task` when the screen goes away.
        gate.open(with: .success(.preview))  // A request the cancel missed would now load, not hang.
        await load.value

        #expect(weakModel == nil)
    }
}
