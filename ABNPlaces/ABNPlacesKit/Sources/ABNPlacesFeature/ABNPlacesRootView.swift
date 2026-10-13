import SwiftUI

/// The app's first screen: the places list in a navigation stack. The model lives here in `@State`, so it lasts as
/// long as the window.
public struct ABNPlacesRootView: View {

    @State private var model = PlacesListModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            PlacesListView(model: model)
        }
    }
}
