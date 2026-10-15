# AgentAtom macOS example

A real SwiftUI app demonstrating a typed specification,
`FailableStreamingAgenticOperation`, the local Apple Intelligence session,
cancellation, raw streaming snapshots, and caller-owned final JSON decoding and
three-point validation. The sample input is fictional demonstration text.

## Run

Requires Xcode 26+ and macOS 26+ for the Apple provider. Enable Apple Intelligence
on a supported Mac and wait for model downloads. No API key or server is needed.

Open `AgentAtomDemo.xcodeproj` in Xcode, select the **AgentAtomDemo** scheme and
**My Mac**, then Run. The project references AgentAtom at the repository root,
so clone the complete repository before opening it.

Use the supplied sample, or enter at least three distinct facts. Choose Generate.
Try a greeting to see a model-declared failure. Cancel waits for provider cleanup;
Generate stays disabled until the run actually ends. If the model is unavailable,
the app displays a message instead of inventing a response.

## Build without signing

From the repository root:

```sh
xcodebuild -project Examples/AgentAtomDemo/AgentAtomDemo.xcodeproj \
  -scheme AgentAtomDemo -destination 'generic/platform=macOS' \
  -derivedDataPath .build/example CODE_SIGNING_ALLOWED=NO build
```

This builds an unsigned local demonstration app; it is not a notarized release.
For your own project, use the remote package URL and exact version `0.0.1` as
shown in the root README. The example app and package use AGPL-3.0-only.
