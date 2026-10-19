#if DEBUG
import ABNPlacesCore
import ABNPlacesUITestContract
import Dependencies
import Foundation
import UIKit

/// For demos and UI tests.
public enum PlacesLaunch {
    /// Applies the launch arguments. Call it first in the app's `init()`, before any view reads a dependency.
    public static func prepare() {
        let arguments = UserDefaults.standard
        if let scenario = LaunchArgument.Scenario(launchArguments: arguments) {
            prepareDependencies {
                $0.placesAPI = scenario.placesAPI
                // The map pin tiles, as before the images: no network in UI tests.
                $0.imagesAPI = .empty
            }
        }
        if animationsDisabled(by: arguments) {
            UIView.setAnimationsEnabled(false)
        }
    }

    nonisolated static func animationsDisabled(by arguments: UserDefaults) -> Bool {
        arguments.bool(forKey: LaunchArgument.animationsDisabled)
    }
}

nonisolated extension LaunchArgument.Scenario {
    init?(launchArguments: UserDefaults) {
        guard let name = launchArguments.string(forKey: LaunchArgument.scenario) else { return nil }
        self.init(rawValue: name)
    }

    var placesAPI: PlacesAPI {
        switch self {
        case .success: .preview
        case .empty: .empty
        case .offline: .failing(.offline)
        case .slow: .never
        case .recovers: .answering(.failure(.offline), thenSlowly: .preview)
        case .updates: .answering(.success(.preview), thenSlowly: [.amsterdam])
        }
    }
}

nonisolated extension PlacesAPI {
    /// `first` for the first fetch, then `later` after two seconds, so the refresh is visible.
    fileprivate static func answering(
        _ first: Result<[Place], PlacesAPIError>,
        thenSlowly later: [Place]
    ) -> PlacesAPI {
        let fetches = LockIsolated(0)
        return PlacesAPI { () async throws(PlacesAPIError) in
            let number = fetches.withValue { count in
                count += 1
                return count
            }
            if number == 1 {
                return try first.get()
            }
            @Dependency(\.continuousClock) var clock
            do {
                try await clock.sleep(for: .seconds(2))
            } catch {
                throw .cancelled
            }
            return later
        }
    }
}
#endif
