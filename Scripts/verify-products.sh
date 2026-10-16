#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-only
# Run the public contract suite against each product in an isolated consumer.
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
for product in AgentAtom AgentAtomSource; do
    consumer="$(mktemp -d "${TMPDIR:-/tmp}/agentatom-consumer.XXXXXX")"
    trap 'rm -rf "$consumer"' EXIT
    mkdir -p "$consumer/Tests/AgentAtomTests/Support" "$consumer/Tests/FailureProbe"
    # These tests intentionally use only the public interface of either variant.
    for name in ContractTests SchemaTests JSONStringTests FailureTests OperationTests StreamingOperationTests SessionConfigurationTests; do
        sed -e 's/@testable import/import/' -e "s/import AgentAtomSource/import $product/" \
            "$root/Tests/AgentAtomTests/$name.swift" > "$consumer/Tests/AgentAtomTests/$name.swift"
    done
    for file in "$root"/Tests/AgentAtomTests/Support/*.swift; do
        sed "s/import AgentAtomSource/import $product/" "$file" > "$consumer/Tests/AgentAtomTests/Support/$(basename "$file")"
    done
    sed "s/import AgentAtomSource/import $product/" Tests/FailureProbe/main.swift > "$consumer/Tests/FailureProbe/main.swift"
    cat > "$consumer/Package.swift" <<SWIFT
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "DistributionConsumer",
    platforms: [.macOS(.v14)],
    dependencies: [.package(path: "$root")],
    targets: [
        .executableTarget(name: "FailureProbe", dependencies: [.product(name: "$product", package: "AgentAtom-publication")], path: "Tests/FailureProbe", linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"])]),
        .testTarget(name: "AgentAtomTests", dependencies: [.product(name: "$product", package: "AgentAtom-publication"), "FailureProbe"])
    ],
    swiftLanguageModes: [.v6]
)
SWIFT
    # A local dependency's identity is the checkout directory, not its package name.
    identity="$(basename "$root" | tr '[:upper:]' '[:lower:]')"
    sed -i '' "s/AgentAtom-publication/$identity/g" "$consumer/Package.swift"
    printf 'Testing %s from a separate consumer\n' "$product"
    swift test --package-path "$consumer"
    rm -rf "$consumer"
    trap - EXIT
done
