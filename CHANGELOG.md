# Changelog

## 0.1.0

- Recommended AgentAtom XCFramework product and optional AgentAtomSource product
  from the same repository and version. Source imports become AgentAtomSource.
- Mac and iPhone support, with device/simulator slices and module interfaces.
- One shared implementation, embedded TypeDecoder, and packaged license notices.
- Binary-backed macOS demo, isolated consumer checks, and artifact release tooling.
- Main is the only integration branch. Version increases trigger verified
  automatic package/binary publication after merge; unchanged versions do not.
- Explicit public lifecycle members preserve the distributed module interface.
- Existing 0.0.1 tag and source-only product remain unchanged.

## 0.0.1

Initial standalone release under `abhi266raj/AgentAtom`.

- Typed specifications, JSON/schema derivation, and four operation modes.
- Injected session contracts, cancellation, reuse, and execution metadata.
- Apple Intelligence session with native guided generation on supported systems.
- Deterministic contract tests and opt-in live model checks.
- Runnable SwiftUI macOS example and standalone documentation.
- GNU AGPL v3 only; TypeDecoder remains Apache-2.0.
