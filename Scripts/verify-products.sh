#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
version="${1:-}"
identity="$(basename "$root" | tr '[:upper:]' '[:lower:]')"
dependency=".package(path: \"$root\")"
if [ -n "$version" ]; then
    swift Scripts/Release.swift compare "$version" 0.0.0 > /dev/null
    dependency=".package(url: \"https://github.com/abhi266raj/AgentAtom.git\", exact: \"$version\")"
    identity=agentatom
fi
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
    dependencies: [$dependency],
    targets: [
        .executableTarget(name: "FailureProbe", dependencies: [.product(name: "$product", package: "$identity")], path: "Tests/FailureProbe", linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"])]),
        .testTarget(name: "AgentAtomTests", dependencies: [.product(name: "$product", package: "$identity"), "FailureProbe"])
    ],
    swiftLanguageModes: [.v6]
)
SWIFT
    printf 'Testing %s from a separate consumer\n' "$product"
    swift test --package-path "$consumer"
    rm -rf "$consumer"
    trap - EXIT
done
