#if DEBUG
import ABNPlacesCore
import ABNPlacesUITestContract
import Dependencies
import Foundation
import Testing

@testable import ABNPlacesFeature

@Suite("Launch scenarios", .timeLimit(.minutes(1)))
struct PlacesLaunchTests {
    @Test("-PlacesScenario names a scenario", arguments: LaunchArgument.Scenario.allCases)
    func readsTheScenario(_ scenario: LaunchArgument.Scenario) throws {
        try Self.withLaunchArguments([LaunchArgument.scenario: scenario.rawValue]) { arguments in
            #expect(LaunchArgument.Scenario(launchArguments: arguments) == scenario)
        }
    }

    @Test("No argument, or an unknown name, means the live app", arguments: [nil, "offlin", "Success"])
    func noScenario(_ name: String?) throws {
        try Self.withLaunchArguments(name.map { [LaunchArgument.scenario: $0] } ?? [:]) { arguments in
            #expect(LaunchArgument.Scenario(launchArguments: arguments) == nil)
        }
    }

    @Test(
        "-PlacesAnimationsDisabled YES turns animations off; anything else leaves them on",
        arguments: [("YES", true), ("NO", false), (nil, false)] as [(String?, Bool)]
    )
    func readsTheAnimationsFlag(_ value: String?, disabled: Bool) throws {
        try Self.withLaunchArguments(value.map { [LaunchArgument.animationsDisabled: $0] } ?? [:]) { arguments in
            #expect(PlacesLaunch.animationsDisabled(by: arguments) == disabled)
        }
    }

    @Test("Each scenario's client does what its name says")
    func scenarioClients() async throws {
        try await withDependencies {
            $0.continuousClock = ImmediateClock()
        } operation: { () async throws in
            #expect(try await LaunchArgument.Scenario.success.placesAPI.fetch() == .preview)
            #expect(try await LaunchArgument.Scenario.empty.placesAPI.fetch() == [])
            #expect(await Self.error(fetching: LaunchArgument.Scenario.offline.placesAPI) == .offline)

            let recovers = LaunchArgument.Scenario.recovers.placesAPI
            #expect(await Self.error(fetching: recovers) == .offline)
            #expect(try await recovers.fetch() == .preview)

            let updates = LaunchArgument.Scenario.updates.placesAPI
            #expect(try await updates.fetch() == .preview)
            #expect(try await updates.fetch() == [.amsterdam])
        }
    }

    @Test("The slow scenario answers only when it's cancelled")
    func slowScenario() async throws {
        let hasAnswered = LockIsolated(false)
        let slow = Task {
            let error = await Self.error(fetching: LaunchArgument.Scenario.slow.placesAPI)
            hasAnswered.setValue(true)
            return error
        }

        try await Task.sleep(for: .milliseconds(100))  // A client that answers straight away has done so by now.
        #expect(!hasAnswered.value)

        slow.cancel()
        #expect(await slow.value == .cancelled)
    }

    /// Uses defaults of its own, so tests running in parallel share nothing.
    private static func withLaunchArguments(_ values: [String: String], _ body: (UserDefaults) -> Void) throws {
        let suiteName = "PlacesLaunchTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        for (key, value) in values {
            defaults.set(value, forKey: key)
        }
        body(defaults)
    }

    private static func error(fetching client: PlacesAPI) async -> PlacesAPIError? {
        do throws(PlacesAPIError) {
            _ = try await client.fetch()
            return nil
        } catch {
            return error
        }
    }
}
#endif
