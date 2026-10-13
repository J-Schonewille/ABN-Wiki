import ABNPlacesFeature
import SwiftUI

@main struct ABNPlacesApp: App {
    init() {
        #if DEBUG
        PlacesLaunch.prepare()  // Applies the launch arguments from the scheme and the UI tests.
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ABNPlacesRootView()
        }
    }
}
