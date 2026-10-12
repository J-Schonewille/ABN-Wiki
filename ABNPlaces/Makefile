# Shortcuts for the ABNPlaces app. Each target is one xcodebuild, SwiftLint or swift-format command.
#
#   make setup    one-time developer setup: checks Xcode and the linters, resolves the packages
#   make check    the linters, the Unit test plan, then a build of the app
#   make test     the Unit test plan: every ABNPlacesKit test target
#   make lint     SwiftLint (strict) and swift-format's lint (strict)
#   make format   swift-format rewrites the Swift sources in place (.swift-format)
#   make build    the ABNPlaces app
#
# Another simulator:    make check DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'
# A DerivedData folder: make check DERIVED_DATA=/tmp/abnplaces-dd

DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=26.5
DERIVED_DATA ?=

XCODEBUILD = xcodebuild -project ABNPlaces.xcodeproj -scheme ABNPlaces -destination '$(DESTINATION)' \
	-skipMacroValidation -disableAutomaticPackageResolution $(if $(DERIVED_DATA),-derivedDataPath '$(DERIVED_DATA)')

SWIFT_SOURCES = ABNPlaces ABNPlacesKit/Sources ABNPlacesKit/Tests ABNPlacesKit/Package.swift

.PHONY: setup check lint format test build

setup:
	./scripts/setup.sh

check: lint test build

lint:
	@command -v swiftlint >/dev/null || { echo "SwiftLint isn't installed: brew install swiftlint"; exit 1; }
	swiftlint lint --strict --quiet
	swift format lint --strict --recursive --parallel $(SWIFT_SOURCES)

format:
	swift format format --in-place --recursive --parallel $(SWIFT_SOURCES)

test:
	$(XCODEBUILD) -testPlan Unit test

build:
	$(XCODEBUILD) build
