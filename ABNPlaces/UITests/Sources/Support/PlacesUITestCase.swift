import ABNPlacesUITestContract
import XCTest

/// A fresh app per test, with a test feed and fixed settings:
/// - English, US region and a fixed text size, so a simulator left in Dutch or at AX5 changes nothing.
/// - Animations off, so tests wait for state, never for an animation.
class PlacesUITestCase: XCTestCase {
    enum TextSize: String {
        case large = "UICTContentSizeCategoryL"
        case accessibility5 = "UICTContentSizeCategoryAccessibilityXXXL"
    }

    /// Generous for a cold launch on a busy machine. A wait returns as soon as its condition holds.
    static let timeout: TimeInterval = 10

    /// Set and read on the main thread only.
    private var app: XCUIApplication?
    /// True while `record(_:)` gathers the diagnostics. Set and read on the main thread only.
    private var isAttachingDiagnostics = false

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func launch(_ scenario: LaunchArgument.Scenario, textSize: TextSize = .large) -> PlacesListScreen {
        let app = XCUIApplication()
        app.launchArguments = [
            "-\(LaunchArgument.scenario)", scenario.rawValue,
            "-\(LaunchArgument.animationsDisabled)", "YES",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", textSize.rawValue,
        ]
        XCUIDevice.shared.appearance = .light
        app.launch()
        self.app = app
        return PlacesListScreen(app: app)
    }

    /// Attaches the element tree and a screenshot to every failure. The tree only while the app runs: asking a
    /// crashed app records a new issue, which loops back here and crashes the test runner.
    override func record(_ issue: XCTIssue) {
        var issue = issue
        // XCTest records the tests' issues on the main thread, where XCUIApplication must be used.
        if Thread.isMainThread, !isAttachingDiagnostics, let app {
            isAttachingDiagnostics = true
            defer { isAttachingDiagnostics = false }
            let (tree, screenshot) = MainActor.assumeIsolated {
                let tree =
                    app.state == .runningForeground
                    ? app.debugDescription
                    : "No element tree: the app isn't running in the foreground."
                return (tree, XCUIScreen.main.screenshot().pngRepresentation)
            }
            let treeAttachment = XCTAttachment(string: tree)
            treeAttachment.name = "Element tree"
            issue.add(treeAttachment)
            let screenshotAttachment = XCTAttachment(data: screenshot, uniformTypeIdentifier: "public.png")
            screenshotAttachment.name = "Screen"
            issue.add(screenshotAttachment)
        }
        super.record(issue)
    }
}
