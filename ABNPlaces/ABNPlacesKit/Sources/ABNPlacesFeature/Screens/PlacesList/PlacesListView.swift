import ABNDesignSystem
import ABNPlacesCore
import ABNPlacesUITestContract
import Dependencies
import SwiftUI

/// One `ScrollView` holds every state, so each can be pulled to refresh. Refresh is also a button, because a pull
/// is hard for some people. "Add place" shows in every state: it doesn't need the feed.
struct PlacesListView: View {
    let model: PlacesListModel

    @State private var isAddingPlace = false
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Keeps the state views narrow enough to read on a wide iPad. Grows with the text.
    @ScaledMetric(relativeTo: .body) private var readableWidth = 600.0

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.small) {
                if let refreshFailure = model.refreshFailure {
                    refreshBanner(for: refreshFailure)
                }
                content
                if !pinsAddPlaceButton {
                    addPlaceButton
                        .buttonStyle(.dsPrimary(fullWidth: true))
                        .padding(.top, DSSpacing.small)
                }
            }
            .padding(DSSpacing.medium)
        }
        // Before `.sheet`, or the sheet gets the pull too. Its own task: SwiftUI cancels the pull's task when the
        // screen changes. At least a second: a refresh that ends mid-pull makes the list jump.
        .refreshable {
            await Task {
                let start = ContinuousClock.now
                await model.refresh()
                try? await Task.sleep(until: start + .seconds(1))
            }.value
        }
        .background(DSColor.background)
        .navigationTitle(Text("Places", bundle: #bundle, comment: "Title of the list of places."))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                refreshButton
            }
        }
        .dsBottomAction(isPinned: pinsAddPlaceButton) {
            addPlaceButton
        }
        .sheet(isPresented: $isAddingPlace) {
            CreatePlaceSheet()
        }
        .task {
            await model.loadIfNeeded()
        }
        .task {
            await model.followCreatedPlaces()
        }
        .wikipediaOpenFailedAlert(model.opener)
        .onChange(of: model.failureCount) {
            announceFailure()
        }
        .onChange(of: model.updateCount) {
            announce(
                localized(
                    "Places updated",
                    locale: locale,
                    comment: "Announced by VoiceOver when a refresh or a retry has loaded the places."
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
        case .loaded(let places) where places.isEmpty && model.createdPlaces.isEmpty:
            DSStateView(
                symbol: .noMapPin,
                title: Text("No places yet", bundle: #bundle, comment: "Title when the feed has no places."),
                message: Text(
                    "Refresh to check again, or add a place.",
                    bundle: #bundle,
                    comment: "Message under “No places yet”."
                )
            )
            .frame(maxWidth: readableWidth)
        case .loaded:
            EmptyView()
        }
        // Saved places show even while the feed loads or fails.
        if !model.places.isEmpty {
            PlacesGrid {
                ForEach(model.places) { place in
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
            // Six fill 1, 2 or 3 columns. Stateless, so the index is their identity.
            ForEach(0..<6, id: \.self) { variant in
                DSSkeletonCard(titleWidthVariant: variant, trailingSymbol: PlaceCard.trailingSymbol)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text("Loading places", bundle: #bundle, comment: "VoiceOver label of the placeholders while places load.")
        )
    }

    private func refreshBanner(for failure: LoadFailure) -> some View {
        DSBanner(Text(failure.refreshMessage(in: locale)), symbol: failure.symbol) {
            Button {
                Task { await model.refresh() }
            } label: {
                Text("Retry", bundle: #bundle, comment: "Button that tries to load the places again.")
            }
            .disabled(model.isLoading)
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await model.refresh() }
        } label: {
            Label {
                Text("Refresh", bundle: #bundle, comment: "Toolbar button that reloads the places.")
            } icon: {
                Image(.refresh)
            }
        }
        .keyboardShortcut("r")
        // Not disabled while loading: that lays out the bar again mid-pull, and the list jumps.
        // Bar buttons don't grow with the text; a long press shows them large.
        .accessibilityShowsLargeContentViewer()
        .accessibilityIdentifier(AccessibilityID.PlacesList.refresh)
    }

    /// At accessibility text sizes a pinned button covers too much, so it's the list's last item instead.
    private var pinsAddPlaceButton: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    private var addPlaceButton: some View {
        Button {
            isAddingPlace = true
        } label: {
            Label {
                Text("Add place", bundle: #bundle, comment: "Button that opens the create-place sheet.")
            } icon: {
                Image(.add)
            }
        }
        .keyboardShortcut("n")
        .frame(maxWidth: readableWidth)
        .accessibilityIdentifier(AccessibilityID.PlacesList.addPlace)
    }

    /// Announces each failure once. Not from the views' `onAppear`, which can run more than once.
    private func announceFailure() {
        if case .failed(let failure) = model.content {
            announce(failure.loadAnnouncement(in: locale))
        } else if let failure = model.refreshFailure {
            announce(failure.refreshMessage(in: locale))
        }
    }
}

private extension View {
    @ViewBuilder
    func dsBottomAction<Action: View>(isPinned: Bool, @ViewBuilder _ action: () -> Action) -> some View {
        if isPinned {
            dsBottomAction(action)
        } else {
            self
        }
    }
}

// MARK: - Previews
#if DEBUG
#Preview("Loaded", traits: .dependency(\.placesAPI, .preview)) {
    ABNPlacesRootView()
}

#Preview("Loading", traits: .dependency(\.placesAPI, .never)) {
    ABNPlacesRootView()
}

#Preview("Offline", traits: .dependency(\.placesAPI, .failing(.offline))) {
    ABNPlacesRootView()
}

#Preview("Empty", traits: .dependency(\.placesAPI, .empty)) {
    ABNPlacesRootView()
}

#Preview("Dark", traits: .dependency(\.placesAPI, .preview)) {
    ABNPlacesRootView()
        .preferredColorScheme(.dark)
}

#Preview("AX5", traits: .dependency(\.placesAPI, .preview)) {
    ABNPlacesRootView()
        .environment(\.dynamicTypeSize, .accessibility5)
}

#Preview("Dutch", traits: .dependency(\.placesAPI, .preview)) {
    ABNPlacesRootView()
        .environment(\.locale, Locale(identifier: "nl_NL"))
}
#endif
