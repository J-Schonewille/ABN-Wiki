import SwiftUI

/// The host app of `ABNPlacesSnapshotTests`: an empty window and nothing else.
/// Accessibility snapshots need a real app. Without one, UIKit's accessibility support never loads,
@main
struct ABNPlacesTestHostApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
                // Without the status bar, an iPad screen's navigation bar keeps the iPad's own top inset instead of
                // sitting below this iPhone's status bar.
                .statusBarHidden()
        }
    }
}
