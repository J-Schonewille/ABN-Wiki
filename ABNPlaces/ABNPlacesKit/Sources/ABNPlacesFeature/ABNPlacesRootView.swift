import ABNPlacesCore
import SwiftUI

public struct ABNPlacesRootView: View {

    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Spike for opening wikipedia")
                    .padding()

                Button("Open Amsterdam") {
                    guard let amsterdam = Coordinate(latitude: 52.3547498, longitude: 4.8339215) else { return }
                    openURL(WikipediaLink.places(coordinate: amsterdam, name: "Amsterdam"))
                }
            }.navigationTitle("ABN Places")
        }
    }
}

#Preview {
    ABNPlacesRootView()
}
