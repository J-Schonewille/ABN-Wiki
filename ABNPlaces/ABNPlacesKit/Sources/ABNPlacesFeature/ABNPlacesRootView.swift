import ABNPlacesCore
import Dependencies
import SwiftUI

// TODO: remove spike code, add actual viewmodel, ui / design system module, etc
// this is just for testing the networking
public struct ABNPlacesRootView: View {

    @Dependency(\.locationsClient) private var locationsClient
    @Environment(\.openURL) private var openURL
    @State private var places: [Place]?
    @State private var failure: LocationsError?

    public init() {}

    public var body: some View {
        NavigationStack {
            List(places ?? []) { place in
                Button {
                    openURL(WikipediaLink.places(coordinate: place.coordinate, name: place.name))
                } label: {
                    Text(verbatim: place.name ?? "\(place.coordinate.latitude), \(place.coordinate.longitude)")
                }
            }
            .overlay {
                if let failure {
                    Text(verbatim: "Couldn't load the places: \(failure)")
                } else if places == nil {
                    ProgressView()
                }
            }
            .navigationTitle("ABN Places")
            .task { await load() }
        }
    }

    private func load() async {
        do throws(LocationsError) {
            places = try await locationsClient.fetch()
        } catch {
            // A cancelled load means the view went away, so there's nothing to show.
            if error != .cancelled {
                failure = error
            }
        }
    }
}

#Preview {
    ABNPlacesRootView()
}
