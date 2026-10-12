// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Every target in this package gets these.
let coreSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .treatAllWarnings(as: .error),
]

// UI modules also run on the main actor by default.
let uiSettings: [SwiftSetting] = coreSettings + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "ABNPlacesKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "ABNPlacesFeature",
            targets: ["ABNPlacesFeature"]
        )
    ],
    targets: [
        .target(name: "ABNPlacesCore", swiftSettings: coreSettings),
        .testTarget(
            name: "ABNPlacesCoreTests",
            dependencies: ["ABNPlacesCore"],
            resources: [.process("Fixtures")],
            swiftSettings: coreSettings
        ),
        .target(name: "ABNPlacesFeature", dependencies: ["ABNPlacesCore"], swiftSettings: uiSettings),

    ],
    swiftLanguageModes: [.v6]
)
