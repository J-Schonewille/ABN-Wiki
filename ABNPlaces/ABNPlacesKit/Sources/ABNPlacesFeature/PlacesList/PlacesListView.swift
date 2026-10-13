import ABNDesignSystem
import ABNPlacesCore
import Dependencies
import SwiftUI

struct PlacesListView: View {
    let model: PlacesListModel

    @Environment(\.locale) private var locale
    /// Keeps the state views narrow enough to read on a wide iPad. Grows with the text.
    @ScaledMetric(relativeTo: .body) private var readableWidth = 600.0

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.small) {
                content
            }
            .padding(DSSpacing.medium)
        }
        .background(DSColor.background)
        .navigationTitle(Text("Places", bundle: #bundle, comment: "Title of the list of places."))
        .task {
            await model.loadIfNeeded()
        }
        .wikipediaNotInstalledAlert(model.opener)
        .onChange(of: model.failureCount) {
            announceFailure()
        }
        .onChange(of: model.updateCount) {
            announce(
                localized(
                    "Places updated",
                    locale: locale,
                    comment: "Announced by VoiceOver when a retry has loaded the places."
                )
            )
        }
    }

    @ViewBuilder private var content: some View {
        switch model.content {
        case .loading:
            skeleton
        case .failed(let failure):
            LoadFailureView(failure: failure) {
                Task { await model.refresh() }
            }
            .frame(maxWidth: readableWidth)
        case .loaded(let places) where places.isEmpty:
            DSStateView(
                symbol: .noMapPin,
                title: Text("No places yet", bundle: #bundle, comment: "Title when the feed has no places."),
                message: Text("Check back later.", bundle: #bundle, comment: "Message under “No places yet”.")
            )
            .frame(maxWidth: readableWidth)
        case .loaded(let places):
            PlacesGrid {
                ForEach(places) { place in
                    PlaceCard(place: place) {
                        Task { await model.open(place) }
                    }
                }
            }
        }
    }

    /// Placeholder cards in the grid the cards will use, read by VoiceOver as one element.
    private var skeleton: some View {
        PlacesGrid {
            // Six fill one, two or three columns. They have no state, so their position is their identity.
            ForEach(0..<6, id: \.self) { variant in
                DSSkeletonCard(titleWidthVariant: variant, trailingSymbol: PlaceCard.trailingSymbol)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text("Loading places", bundle: #bundle, comment: "VoiceOver label of the placeholders while places load.")
        )
    }

    /// Tells VoiceOver users what failed, once per failure. The state view doesn't announce itself, because `onAppear`
    /// can run more than once for one failure.
    private func announceFailure() {
        guard case .failed(let failure) = model.content else { return }
        announce(failure.loadAnnouncement(in: locale))
    }

    private func announce(_ message: String) {
        var announcement = AttributedString(message)
        // High priority, so the screen changing under VoiceOver's focus doesn't cut it off.
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}

// MARK: - Previews
#if DEBUG
#Preview("Loaded", traits: .dependency(\.locationsClient, .preview)) {
    ABNPlacesRootView()
}

#Preview("Loading", traits: .dependency(\.locationsClient, .never)) {
    ABNPlacesRootView()
}

#Preview("Offline", traits: .dependency(\.locationsClient, .failing(.offline))) {
    ABNPlacesRootView()
}

#Preview("Empty", traits: .dependency(\.locationsClient, .empty)) {
    ABNPlacesRootView()
}

#Preview("Dark", traits: .dependency(\.locationsClient, .preview)) {
    ABNPlacesRootView()
        .preferredColorScheme(.dark)
}

#Preview("AX5", traits: .dependency(\.locationsClient, .preview)) {
    ABNPlacesRootView()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dutch", traits: .dependency(\.locationsClient, .preview)) {
    ABNPlacesRootView()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
#endif
