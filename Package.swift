// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AgentAtom",
    platforms: [.macOS(.v14), .iOS(.v16)],
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
            checksum: "4664c6a1726478a8dbe1e202699a14b40b3d5a9904445118860aa4f6842776f4"
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
