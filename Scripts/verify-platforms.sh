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
sdks=(macosx macosx iphoneos iphonesimulator iphonesimulator appletvos appletvsimulator appletvsimulator watchos watchos watchsimulator watchsimulator xros xrsimulator xrsimulator)
triples=(arm64-apple-macosx14.0 x86_64-apple-macosx14.0 arm64-apple-ios16.0 arm64-apple-ios16.0-simulator x86_64-apple-ios16.0-simulator arm64-apple-tvos16.0 arm64-apple-tvos16.0-simulator x86_64-apple-tvos16.0-simulator arm64_32-apple-watchos9.0 arm64-apple-watchos9.0 arm64-apple-watchos9.0-simulator x86_64-apple-watchos9.0-simulator arm64-apple-xros1.0 arm64-apple-xros1.0-simulator x86_64-apple-xros1.0-simulator)
for index in "${!triples[@]}"; do
    printf 'Compiling binary consumer: %s\n' "${triples[$index]}"
    swift build --package-path "$consumer" --triple "${triples[$index]}" \
        --sdk "$(xcrun --sdk "${sdks[$index]}" --show-sdk-path)"
done
