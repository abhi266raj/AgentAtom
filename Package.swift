// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AgentAtom",
    platforms: [.macOS(.v14), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "AgentAtom", targets: ["AgentAtom"]),
        .library(name: "AgentAtomSource", targets: ["AgentAtomSource"])
    ],
    dependencies: [
        .package(url: "https://github.com/Kitura/TypeDecoder.git", exact: "2.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "AgentAtom",
            url: "https://github.com/abhi266raj/AgentAtom/releases/download/artifacts-0.1.0/AgentAtom.xcframework.zip",
            checksum: "978a80b2318df4e940c8dc86814a7dd6fcf526455a039548c337a4f76b6ecd2e"
        ),
        .target(
            name: "AgentAtomSource",
            dependencies: [.product(name: "TypeDecoder", package: "TypeDecoder")],
            path: "Sources/AgentAtom"
        ),
        .executableTarget(
            name: "FailureProbe", dependencies: ["AgentAtomSource"], path: "Tests/FailureProbe"
        ),
        .testTarget(name: "AgentAtomTests", dependencies: ["AgentAtomSource", "FailureProbe"])
    ],
    swiftLanguageModes: [.v6]
)
