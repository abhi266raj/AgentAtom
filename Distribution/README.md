# Binary and source distribution

Version 0.1.0 offers two products from one package URL and version:
`AgentAtom` (recommended dynamic XCFramework, `import AgentAtom`) and
`AgentAtomSource` (source target, `import AgentAtomSource`). Both compile
`Sources/AgentAtom`; include every new library Swift file in the framework project.
Choose one product per dependency graph because their types have different module
identities. Both remain AGPL-3.0-only and the source repository remains public.

## Build and verify a development checkout

Use Xcode 26.6+ with all five platform SDKs installed. The source product requires
Swift 6.0+; its Apple provider additionally requires the FoundationModels SDK from
Xcode 26+. The binary baseline is verified by CI and recorded with each artifact.

```sh
Scripts/test-release.sh
Scripts/build-xcframework.sh
swift build
swift test
Scripts/verify-products.sh
Scripts/verify-platforms.sh
xcodebuild -project Examples/AgentAtomDemo/AgentAtomDemo.xcodeproj \
  -scheme AgentAtomDemo -destination 'generic/platform=macOS' \
  -derivedDataPath .build/example CODE_SIGNING_ALLOWED=NO build
```

Build the framework first: development manifests use the local artifact under
`.build/distribution/AgentAtom.xcframework`. Published semantic-version tags use
an immutable GitHub archive URL and checksum, generated automatically by CI.
Consumers selecting a published tag need no local artifact-generation step.

The build script archives universal macOS and device/simulator variants for iOS,
tvOS, watchOS, and visionOS. It produces AgentAtom.xcframework.zip and checksum.txt
under `.build/distribution`, alongside intermediate archives and logs. Library
evolution emits public module interfaces. TypeDecoder 2.0.0 is linked statically
and is absent from the public interface; consumers need no TypeDecoder module to
import the binary. Framework install names use `@rpath`.

The archive includes LICENSE, COPYRIGHT, and the Apache-2.0 dependency notices.
Frameworks are unsigned; consuming applications embed and sign the dynamic
framework during their normal build. The demo does this through SwiftPM.

`verify-products.sh` creates isolated consumers and tests the same public
contracts against each product. Internal instruction tests stay in the normal
source suite. Live model tests are opt-in. `verify-platforms.sh` discovers and
checks all nine platform slices, then compiles a binary consumer for every
architecture in the archive, including an available Apple provider reference.

## Automatic publication

Increase VERSION in a PR to main. After its approved merge and successful CI,
the workflow publishes the immutable binary asset, verifies its public download,
and creates the semantic package tag and GitHub Release. An unchanged VERSION
never publishes. The protected main branch is never modified by automation.
See [RELEASING.md](../RELEASING.md) for generated manifest commits, retry behavior,
permissions, and version validation. Version 0.0.1 stays untouched.
