// swift-tools-version: 6.2

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
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.17.1")
    ],
    targets: [
        // Loggers that only log in DEBUG builds.
        .target(name: "ABNLogging", swiftSettings: coreSettings),
        // HTTP requests, their errors and JSON decoding.
        .target(name: "ABNNetworking", dependencies: ["ABNLogging"], swiftSettings: coreSettings),
        .testTarget(name: "ABNNetworkingTests", dependencies: ["ABNNetworking"], swiftSettings: coreSettings),
        .target(
            name: "ABNPlacesCore",
            dependencies: [
                "ABNLogging",
                "ABNNetworking",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ],
            swiftSettings: coreSettings
        ),
        .testTarget(
            name: "ABNPlacesCoreTests",
            dependencies: [
                "ABNPlacesCore",
                "ABNNetworking",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
            ],
            resources: [.process("Fixtures")],
            swiftSettings: coreSettings
        ),
        .target(
            name: "ABNPlacesFeature",
            dependencies: ["ABNPlacesCore", .product(name: "Dependencies", package: "swift-dependencies")],
            swiftSettings: uiSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
