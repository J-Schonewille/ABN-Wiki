# Shortcuts for the ABNPlaces app. Each target is one xcodebuild, SwiftLint or swift-format command.
#
#   make setup             one-time developer setup: checks Xcode, the snapshot simulator and the linters, and
#                          resolves the packages
#   make check             the linters, the Unit and Snapshots plans, the app build, and the UI tests compiled
#   make test              the Unit test plan: every ABNPlacesKit test target
#   make test-snapshots    the Snapshots test plan: every image and accessibility snapshot
#   make snapshots-record  records every snapshot again; then review the images like code
#   make test-ui           the UI test plan, with the accessibility audits
#   make lint              SwiftLint (strict) and swift-format's lint (strict)
#   make format            swift-format rewrites the Swift sources in place (.swift-format)
#   make build             the ABNPlaces app
#
# Another simulator:    make test DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'
# A DerivedData folder: make check DERIVED_DATA=/tmp/abnplaces-dd
#
# Snapshots are recorded on iPhone 17 with iOS 26.5 and only match there, so test-snapshots, snapshots-record and
# check need that simulator. The other targets run on any iPhone 17, such as a stock Xcode's iOS 27 one.

DESTINATION ?= platform=iOS Simulator,name=iPhone 17
SNAPSHOT_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.5
DERIVED_DATA ?=

XCODEBUILD_ANY = xcodebuild -project ABNPlaces.xcodeproj -scheme ABNPlaces \
	-skipMacroValidation -disableAutomaticPackageResolution $(if $(DERIVED_DATA),-derivedDataPath '$(DERIVED_DATA)')
XCODEBUILD = $(XCODEBUILD_ANY) -destination '$(DESTINATION)'
XCODEBUILD_SNAPSHOTS = $(XCODEBUILD_ANY) -destination '$(SNAPSHOT_DESTINATION)'

SWIFT_SOURCES = ABNPlaces SnapshotTests UITests ABNPlacesKit/Sources ABNPlacesKit/Tests ABNPlacesKit/Package.swift

.PHONY: setup check lint format test test-snapshots snapshots-record test-ui build build-ui-tests

setup:
	./scripts/setup.sh

check: lint test test-snapshots build build-ui-tests

lint:
	@command -v swiftlint >/dev/null || { echo "SwiftLint isn't installed: brew install swiftlint"; exit 1; }
	swiftlint lint --strict --quiet
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)

format:
	swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)

# No diagnostics collection: after a failed run, xcodebuild would otherwise spend up to 10 minutes gathering logs.
test:
	$(XCODEBUILD) -collect-test-diagnostics never -testPlan Unit test

test-snapshots:
	TEST_RUNNER_SNAPSHOT_TESTING_RECORD=never $(XCODEBUILD_SNAPSHOTS) -collect-test-diagnostics never -testPlan Snapshots test

# Every snapshot reports "Record mode is on" as a failure, so the run always ends in TEST FAILED.
snapshots-record:
	-TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all $(XCODEBUILD_SNAPSHOTS) -collect-test-diagnostics never -testPlan Snapshots test
	@echo "If the tests ran, the snapshots were recorded again. Review them (git status, git diff), then run make check."

# Runs on any simulator. For the iPad audits:
# make test-ui DESTINATION='platform=iOS Simulator,name=iPad Pro 13-inch (M5)'
test-ui:
	$(XCODEBUILD) -collect-test-diagnostics never -testPlan UI test

build:
	$(XCODEBUILD) build

# Compiles the UI tests, so a renamed identifier or scenario breaks make check.
build-ui-tests:
	$(XCODEBUILD) -testPlan UI build-for-testing
