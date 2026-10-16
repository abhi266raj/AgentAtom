#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-only
# Compile an external binary consumer for every shipped architecture/SDK.
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
consumer="$(mktemp -d "${TMPDIR:-/tmp}/agentatom-platforms.XXXXXX")"
trap 'rm -rf "$consumer"' EXIT
identity="$(basename "$root" | tr '[:upper:]' '[:lower:]')"
mkdir -p "$consumer/Sources/Consumer"
cat > "$consumer/Package.swift" <<SWIFT
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "PlatformConsumer",
    platforms: [.macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [.library(name: "PlatformConsumer", targets: ["Consumer"])],
    dependencies: [.package(path: "$root")],
    targets: [.target(name: "Consumer", dependencies: [.product(name: "AgentAtom", package: "$identity")])],
    swiftLanguageModes: [.v6]
)
SWIFT
cat > "$consumer/Sources/Consumer/Consumer.swift" <<'SWIFT'
import AgentAtom
public struct Example: ModelledSpec {
    public struct Output: Decodable, Sendable { public let text: String }
    public static let identity = Identity(id: "distribution", name: "Distribution", version: "0.1.0")
    public static let role = "Echo input."
    public let instructions = "Return the supplied text."
    public let input = "Hello"
    public var output: Output?
    public init() {}
}
public func schema() -> String { Example.outputSchema.rawValue }
#if os(macOS) || os(iOS) || os(visionOS)
@available(macOS 26, iOS 26, visionOS 26, *)
public func appleSession() -> AppleIntelligenceSession? { AppleIntelligenceSession() }
#endif
SWIFT
platforms="$(swift Scripts/ArtifactPlatforms.swift)"
while read -r sdk triple; do
    architecture="${triple%%-apple-*}"
    case "$sdk" in
        macosx) destination='generic/platform=macOS' ;;
        iphoneos) destination='generic/platform=iOS' ;;
        iphonesimulator) destination='generic/platform=iOS Simulator' ;;
        appletvos) destination='generic/platform=tvOS' ;;
        appletvsimulator) destination='generic/platform=tvOS Simulator' ;;
        watchos) destination='generic/platform=watchOS' ;;
        watchsimulator) destination='generic/platform=watchOS Simulator' ;;
        xros) destination='generic/platform=visionOS' ;;
        xrsimulator) destination='generic/platform=visionOS Simulator' ;;
        *) exit 1 ;;
    esac
    printf 'Compiling binary consumer with Xcode: %s\n' "$triple"
    (cd "$consumer" && xcodebuild -scheme PlatformConsumer -configuration Debug \
        -destination "$destination" -arch "$architecture" \
        -derivedDataPath "$consumer/DerivedData" CODE_SIGNING_ALLOWED=NO build) \
        > "$consumer/$triple.log" 2>&1 || {
            tail -80 "$consumer/$triple.log" >&2
            exit 1
        }
done <<< "$platforms"
