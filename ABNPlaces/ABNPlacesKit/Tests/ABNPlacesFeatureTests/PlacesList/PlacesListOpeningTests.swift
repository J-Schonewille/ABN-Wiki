import ABNPlacesCore
import Dependencies
import Foundation
import Testing

@testable import ABNPlacesFeature

@MainActor
@Suite("Places list: opening a place", .timeLimit(.minutes(1)))
struct PlacesListOpeningTests {
    nonisolated static let amsterdamLink = "wikipedia://places?lat=52.3547498&lon=4.8339215&name=Amsterdam"

    @Test(
        "Opening a place opens its exact Wikipedia link",
        arguments: [
            (Place.amsterdam, amsterdamLink),
            (.unnamedMadrid, "wikipedia://places?lat=40.4380638&lon=-3.7495758"),
        ]
    )
    func opensTheLink(place: Place, link: String) async throws {
        let opened = LockIsolated<[URL]>([])
        let model = Self.model(openURL: .recording(into: opened) { true })

        let outcome = await model.open(place)

        #expect(outcome == .opened)
        #expect(opened.value == [try #require(URL(string: link))])
        #expect(!model.opener.showsNotInstalledAlert)
    }

    @Test("When Wikipedia isn't installed, the alert shows and nothing else opens")
    func notInstalledShowsTheAlert() async throws {
        let opened = LockIsolated<[URL]>([])
        let model = Self.model(openURL: .recording(into: opened) { false })

        let outcome = await model.open(.amsterdam)

        #expect(outcome == .notInstalled)
        #expect(model.opener.showsNotInstalledAlert)
        #expect(opened.value == [try #require(URL(string: Self.amsterdamLink))])
    }

    @Test("Two quick taps open Wikipedia once")
    func doubleTapOpensOnce() async {
        let gate = Gate<Bool>()
        let opened = LockIsolated<[URL]>([])
        let model = Self.model(openURL: .recording(into: opened) { await gate.wait() })

        let firstTap = Task { await model.open(.amsterdam) }
        await gate.waitForArrival()  // The first open is waiting for the system.
        let secondTap = await model.open(.amsterdam)
        gate.open(with: true)

        #expect(secondTap == .alreadyOpening)
        #expect(await firstTap.value == .opened)
        #expect(opened.value.count == 1)
    }

    @Test("A cancelled open shows no alert")
    func cancelledOpenShowsNoAlert() async {
        let gate = Gate<Bool>()
        let opened = LockIsolated<[URL]>([])
        let model = Self.model(openURL: .recording(into: opened) { await gate.wait() })

        let tap = Task { await model.open(.amsterdam) }
        await gate.waitForArrival()  // The open is waiting for the system.
        tap.cancel()  // `openURL` answers a cancelled open with false.
        gate.open(with: true)  // An open the cancel missed would now succeed, not hang.

        #expect(await tap.value == .cancelled)
        #expect(!model.opener.showsNotInstalledAlert)
    }

    @Test("Once an open has finished, the next tap opens again")
    func tapAfterFinishingOpensAgain() async {
        let opened = LockIsolated<[URL]>([])
        let model = Self.model(openURL: .recording(into: opened) { true })

        await model.open(.amsterdam)
        await model.open(.amsterdam)

        #expect(opened.value.count == 2)
    }

    /// A model whose opener opens through `openURL`.
    private static func model(openURL: OpenURLEffect) -> PlacesListModel {
        withDependencies {
            $0.openURL = openURL
        } operation: {
            PlacesListModel()
        }
    }
}
