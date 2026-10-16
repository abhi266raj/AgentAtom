# Binary and source distribution

Version 0.1.0 offers two products from one package URL and version:
`AgentAtom` (recommended dynamic XCFramework, `import AgentAtom`) and
`AgentAtomSource` (source target, `import AgentAtomSource`). Both compile
`Sources/AgentAtom`; the framework project must include every Swift file there.
Do not combine the products in one dependency graph: their types have different
module identities.

## Build the XCFramework

Use a Mac with Xcode 26+ and all five Apple platform SDKs installed. Record the
exact Xcode/Swift versions used in the artifact release notes. Binary interfaces
are built with library evolution enabled. The source target supports Swift 6.0+;
the Apple provider additionally needs the FoundationModels SDK from Xcode 26+.

```sh
Scripts/build-xcframework.sh
```

The script archives nine destinations: universal macOS, iOS/device and simulator,
tvOS/device and simulator, watchOS/device and simulator, and visionOS/device and
simulator. Output is `.build/distribution/AgentAtom.xcframework.zip` and
`.build/distribution/checksum.txt`. Intermediate archives and logs stay in
`.build/distribution`. TypeDecoder 2.0.0 is linked statically into each framework;
it is not part of the public interface and consumers need no TypeDecoder module
to import the binary. Framework install names use `@rpath`.

The archive contains LICENSE, COPYRIGHT, and the Apache-2.0 dependency notices.
Artifacts are unsigned; the consuming application embeds and signs the dynamic
framework as part of its normal build. The sample app does this through SwiftPM.

## Artifact staging and package release

The binary must be publicly downloadable before a manifest referencing its URL
can resolve. Stage it in an immutable GitHub prerelease named
`artifacts-0.1.0`, separate from the semantic package tag `0.1.0`. This artifact tag
is not a SwiftPM semantic version. Its notes record the source commit and toolchain.
Keep the asset available after the package release; never replace a staged zip or
change its checksum in an existing package tag. A corrected binary needs a new
version and artifact URL.

Only after uploading, put the checksum in Package.swift and verify consumers.
The final `0.1.0` package tag points to the reviewed, merged manifest commit.
Do not publish that semantic tag while the PR is pending. See
[RELEASING.md](../RELEASING.md) for the full sequence.

## Verification

```sh
swift build
swift test
Scripts/verify-products.sh
xcodebuild -project Examples/AgentAtomDemo/AgentAtomDemo.xcodeproj \
  -scheme AgentAtomDemo -destination 'generic/platform=macOS' \
  -derivedDataPath .build/example CODE_SIGNING_ALLOWED=NO build
```

`verify-products.sh` makes separate temporary consumer packages and runs the same
public contract tests against each product. Internal instruction tests remain in
the normal source suite. Live model tests remain opt-in. CI also builds the demo
against the downloaded binary and compiles device/simulator binary consumers.
The repository remains public and AGPL-3.0-only; binary packaging does not make
its implementation secret or change source-distribution obligations.
