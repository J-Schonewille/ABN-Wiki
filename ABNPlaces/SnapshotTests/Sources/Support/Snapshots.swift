import ABNDesignSystem
import AccessibilitySnapshot
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

// References live in `SnapshotTests/__Snapshots__`, in folders that mirror `Sources`.
// ⌘U with the Snapshots plan records missing references, `make snapshots-record` all, `make test-snapshots` none.

/// References only match on the simulator they're recorded on: text looks slightly different on each iOS.
private enum ReferenceSimulator {
    static let modelIdentifier = "iPhone18,3"  // iPhone 17
    static let systemVersion = "26.5"

    /// Records an issue when the tests run anywhere else.
    @MainActor
    static func isCurrent(at location: SourceLocation) -> Bool {
        let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "not a simulator"
        let version = UIDevice.current.systemVersion
        guard model == modelIdentifier, version == systemVersion else {
            Issue.record(
                """
                Snapshots are recorded on iPhone 17 (\(modelIdentifier)) with iOS \(systemVersion); \
                this is \(model) with iOS \(version). Run make test-snapshots, or choose that simulator.
                """,
                sourceLocation: location
            )
            return false
        }
        return true
    }
}

/// Lets a pixel differ by 2%, for smoothed edges.
private let perceptualPrecision: Float = 0.98

// MARK: - Components

/// Accessibility snapshots use `light`, or `lightAX5` where the layout changes.
enum ComponentVariant: String, CaseIterable, Sendable, CustomTestStringConvertible {
    case light
    case dark
    case lightAX5 = "light-ax5"
    case darkAX5 = "dark-ax5"
    case lightIncreasedContrast = "light-increased-contrast"

    var testDescription: String { rawValue }

    var colorScheme: ColorScheme {
        self == .dark || self == .darkAX5 ? .dark : .light
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .lightAX5 || self == .darkAX5 ? .accessibility5 : .large
    }

    /// Increase Contrast can only come from the traits: SwiftUI's `colorSchemeContrast` can't be set.
    @MainActor var traits: UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceStyle = UIUserInterfaceStyle(colorScheme)
            traits.preferredContentSizeCategory = UIContentSizeCategory(dynamicTypeSize)
            traits.accessibilityContrast = self == .lightIncreasedContrast ? .high : .normal
            traits.displayScale = 3
        }
    }
}

@MainActor
func assertComponentSnapshot(
    of view: some View,
    as variant: ComponentVariant,
    named name: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    verify(
        framed(view, as: variant),
        as: .image(perceptualPrecision: perceptualPrecision, layout: .sizeThatFits, traits: variant.traits),
        testName: name,
        named: variant.rawValue,
        at: CallSite(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}

@MainActor
func assertComponentAccessibilitySnapshot(
    of view: some View,
    as variant: ComponentVariant = .light,
    named name: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    verify(
        framed(view, as: variant),
        as: .accessibilityImage(shouldRunInHostApplication: true, perceptualPrecision: perceptualPrecision),
        testName: name,
        named: "\(variant.rawValue)-accessibility",
        at: CallSite(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}

/// 390 pt wide: an iPhone less its margins. The scheme and text size also go into the environment, or an AX5 view
/// is measured at the default size and cut off.
@MainActor
private func framed(_ view: some View, as variant: ComponentVariant) -> some View {
    view
        .padding(DSSpacing.medium)
        .frame(width: 390)
        .fixedSize(horizontal: false, vertical: true)
        .background(DSColor.background)
        .environment(\.colorScheme, variant.colorScheme)
        .environment(\.dynamicTypeSize, variant.dynamicTypeSize)
        .environment(\.locale, Locale(identifier: "en_US"))
}

// MARK: - Screens

enum ScreenVariant: String, CaseIterable, Sendable, CustomTestStringConvertible {
    case light
    case dark
    case ax5
    case dutch

    var testDescription: String { rawValue }

    var colorScheme: ColorScheme { self == .dark ? .dark : .light }
    var dynamicTypeSize: DynamicTypeSize { self == .ax5 ? .accessibility5 : .large }
    /// Always set, or the simulator's region picks the decimal separator.
    var locale: Locale { Locale(identifier: self == .dutch ? "nl_NL" : "en_US") }
}

struct SnapshotDevice {
    let size: CGSize
    let safeArea: UIEdgeInsets
    let idiom: UIUserInterfaceIdiom
    let horizontalSizeClass: UIUserInterfaceSizeClass
    let displayScale: CGFloat

    static let iPhone17 = SnapshotDevice(
        size: CGSize(width: 402, height: 874),
        safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        idiom: .phone,
        horizontalSizeClass: .compact,
        displayScale: 3
    )

    static let iPadPortrait = SnapshotDevice(
        size: CGSize(width: 1024, height: 1366),
        safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
        idiom: .pad,
        horizontalSizeClass: .regular,
        displayScale: 2
    )

    @MainActor var traits: UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceIdiom = idiom
            traits.horizontalSizeClass = horizontalSizeClass
            traits.verticalSizeClass = .regular
            traits.displayScale = displayScale
        }
    }
}

/// Liquid Glass isn't drawn in snapshots, so glass controls look faint.
@MainActor
func assertScreenSnapshot(
    of screen: some View,
    on device: SnapshotDevice = .iPhone17,
    as variant: ScreenVariant = .light,
    named name: String,
    state: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    let config = ViewImageConfig(safeArea: device.safeArea, size: device.size, traits: device.traits)
    // On top of the device's traits: the renderer takes its scale from them.
    let traits = device.traits.modifyingTraits { traits in
        traits.userInterfaceStyle = UIUserInterfaceStyle(variant.colorScheme)
        traits.preferredContentSizeCategory = UIContentSizeCategory(variant.dynamicTypeSize)
    }
    verify(
        configured(screen, as: variant),
        as: .image(perceptualPrecision: perceptualPrecision, layout: .device(config: config), traits: traits),
        testName: name,
        named: state,
        at: CallSite(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}

/// Hosted in a window and laid out first, or a `NavigationStack` draws nothing.
@MainActor
func assertScreenAccessibilitySnapshot(
    of screen: some View,
    on device: SnapshotDevice = .iPhone17,
    as variant: ScreenVariant = .light,
    named name: String,
    state: String,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    let host = UIHostingController(rootView: configured(screen, as: variant))
    host.traitOverrides.userInterfaceStyle = UIUserInterfaceStyle(variant.colorScheme)
    host.traitOverrides.userInterfaceIdiom = device.idiom
    host.traitOverrides.horizontalSizeClass = device.horizontalSizeClass
    host.traitOverrides.preferredContentSizeCategory = UIContentSizeCategory(variant.dynamicTypeSize)
    let window = UIWindow(frame: CGRect(origin: .zero, size: device.size))
    window.rootViewController = host
    window.makeKeyAndVisible()
    host.view.layoutIfNeeded()
    defer { window.isHidden = true }
    verify(
        host,
        as: .accessibilityImage(shouldRunInHostApplication: true, perceptualPrecision: perceptualPrecision),
        testName: name,
        named: "\(state)-accessibility",
        at: CallSite(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}

@MainActor
private func configured(_ screen: some View, as variant: ScreenVariant) -> some View {
    screen
        .environment(\.colorScheme, variant.colorScheme)
        .environment(\.dynamicTypeSize, variant.dynamicTypeSize)
        .environment(\.locale, variant.locale)
        .modifier(ScrollEdgeEffectsHidden())
}

/// Snapshots leave out the content under iOS 26's scroll-edge effects, so whole lists came out blank.
private struct ScrollEdgeEffectsHidden: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectHidden(true, for: .all)
        } else {
            content
        }
    }
}

// MARK: - References

/// Where a test called an assert: failures show there, and its file decides the reference folder.
private struct CallSite {
    let fileID: StaticString
    let filePath: StaticString
    let line: UInt
    let column: UInt

    var location: SourceLocation {
        SourceLocation(fileID: "\(fileID)", filePath: "\(filePath)", line: Int(line), column: Int(column))
    }
}

/// `assertSnapshot` can't take a reference folder, so this calls `verifySnapshot` and records the failure itself.
@MainActor
private func verify<Value, Format>(
    _ value: Value,
    as strategy: Snapshotting<Value, Format>,
    testName: String,
    named name: String,
    at callSite: CallSite
) {
    guard ReferenceSimulator.isCurrent(at: callSite.location) else { return }
    let failure = verifySnapshot(
        of: value,
        as: strategy,
        named: name,
        snapshotDirectory: referenceDirectory(for: callSite.filePath),
        fileID: callSite.fileID,
        file: callSite.filePath,
        testName: testName,
        line: callSite.line,
        column: callSite.column
    )
    if let failure {
        Issue.record(Comment(rawValue: failure), sourceLocation: callSite.location)
    }
}

private func referenceDirectory(for testFilePath: StaticString) -> String {
    let testFile = URL(filePath: "\(testFilePath)").deletingPathExtension().path(percentEncoded: false)
    guard let sources = testFile.range(of: "/SnapshotTests/Sources/", options: .backwards) else {
        preconditionFailure("Snapshot tests live in SnapshotTests/Sources, not in \(testFilePath)")
    }
    return testFile.replacingCharacters(in: sources, with: "/SnapshotTests/__Snapshots__/")
}
