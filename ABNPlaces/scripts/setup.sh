#!/usr/bin/env bash
# One-step developer setup. It is safe to re-run.
#
# You don't need it to build and run on a simulator: clone, open ABNPlaces.xcodeproj and press Run.
# It prepares the tools a developer uses before committing (make check): it checks Xcode, the pinned
# SwiftLint and swift-format, and it resolves the Swift packages.
set -euo pipefail
cd "$(dirname "$0")/.."

readonly MINIMUM_XCODE_MAJOR=26
readonly SWIFTLINT_VERSION="$(cat .swiftlint-version)"
problems=0

step() { printf '\n▸ %s\n' "$1"; }
ok() { printf '  ✓ %s\n' "$1"; }
problem() { printf '  ✗ %s\n' "$1"; problems=$((problems + 1)); }

step "Xcode"
xcode_version="$(xcodebuild -version | awk 'NR == 1 { print $2 }')"
if [ "${xcode_version%%.*}" -ge "$MINIMUM_XCODE_MAJOR" ]; then
    ok "Xcode $xcode_version ($(xcode-select -p))"
else
    problem "Xcode $xcode_version is too old: install Xcode $MINIMUM_XCODE_MAJOR or later, then run xcode-select -s"
fi

step "SwiftLint $SWIFTLINT_VERSION (pinned in .swiftlint-version)"
export PATH="$PATH:/opt/homebrew/bin"
if ! command -v swiftlint >/dev/null && command -v brew >/dev/null; then
    echo "  Installing SwiftLint with Homebrew…"
    brew install swiftlint
fi
if command -v swiftlint >/dev/null; then
    installed="$(swiftlint version)"
    if [ "$installed" = "$SWIFTLINT_VERSION" ]; then
        ok "SwiftLint $installed"
    else
        problem "SwiftLint $installed differs from the pinned $SWIFTLINT_VERSION: lint results can differ (brew upgrade swiftlint)"
    fi
else
    problem "SwiftLint isn't installed and Homebrew isn't available: see https://github.com/realm/SwiftLint"
fi

step "swift-format (ships with Xcode)"
if xcrun --find swift-format >/dev/null 2>&1; then
    ok "swift-format found in the Xcode toolchain"
else
    problem "swift-format not found: it ships with Xcode 16 and later"
fi

step "Swift packages"
if xcodebuild -resolvePackageDependencies -project ABNPlaces.xcodeproj -scheme ABNPlaces >/dev/null; then
    ok "Packages resolved"
else
    problem "Package resolution failed: check your network connection and run this script again"
fi

if [ -d ../Wikipedia ]; then
    step "Wikipedia"
    ok "Builds on a simulator without setup. For a device, run Wikipedia/scripts/setup_bundle_id <TEAM_ID>, and don't commit the xcconfig it changes"
fi

echo
if [ "$problems" -eq 0 ]; then
    echo "All set. Open ABNPlaces.xcodeproj and run the ABNPlaces scheme. Before committing, run make check."
else
    echo "$problems problem(s) above. The app still builds and runs; these only affect make check."
    exit 1
fi
