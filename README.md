# AgentAtom

Swift specifications, reusable operations, and injected sessions.

[Public repository](https://github.com/abhi266raj/AgentAtom) ·
[Releases](https://github.com/abhi266raj/AgentAtom/releases) ·
[macOS example](Examples/AgentAtomDemo/README.md) · [Testing](Tests/README.md)

## Install with Swift Package Manager

Add `https://github.com/abhi266raj/AgentAtom.git` in Xcode's package dependencies,
and select **Exact Version: 0.1.0**. Add the **AgentAtom** product to your target for the recommended precompiled XCFramework.
For a Swift package manifest:

```swift
.package(url: "https://github.com/abhi266raj/AgentAtom.git", exact: "0.1.0")
```

Use this product dependency in your target:

```swift
.product(name: "AgentAtom", package: "AgentAtom")
```

### Choose binary or source

Both products come from the same repository URL and version `0.1.0`:

| Product | Distribution | Import |
| --- | --- | --- |
| **AgentAtom** (recommended) | Precompiled dynamic XCFramework | `import AgentAtom` |
| **AgentAtomSource** | Compiles the same implementation from source | `import AgentAtomSource` |

For source builds, select **AgentAtomSource** in Xcode, or use:

```swift
.product(name: "AgentAtomSource", package: "AgentAtom")
```

Change your imports to `import AgentAtomSource`. The API declarations and behavior
are the same, but the modules define distinct Swift types: choose one product for
each dependency graph; do not mix values between them. SwiftPM has no automatic
default product; this guide and the example recommend the binary product.

The XCFramework contains macOS (Apple silicon and Intel), iOS, tvOS, watchOS, and
visionOS device/simulator slices. It includes public Swift module interfaces,
with TypeDecoder linked into the framework. App consumers must embed and sign the
dynamic framework; Xcode handles this when the package product is added to the app.
The package downloads the archive from GitHub Releases and verifies its SHA-256.

Both variants remain AGPL-3.0-only. Choosing binary distribution does not hide the
source in this public repository or change the license. SwiftPM may still fetch
repository sources and resolve declared dependencies for either product.

Version `0.0.1` remains the original source-only `AgentAtom` release. Starting at
`0.1.0`, existing `import AgentAtom` clients select the binary product; source-only
clients must explicitly select and import `AgentAtomSource`. See
[distribution details](Distribution/README.md) and [release procedure](RELEASING.md).

## Requirements

- Source: Swift 6.0+. Binary: Xcode 26.6+ (CI-validated baseline). Package deployment targets: macOS 14, iOS/tvOS 16, watchOS 9, visionOS 1.
- The Apple provider requires Xcode/SDK 26+ and macOS/iOS/visionOS 26+, with
  Apple Intelligence supported, enabled, downloaded, and available.
- The provider is excluded when FoundationModels or a supported platform is absent.
  Declared deployment targets do not imply the Apple model runs on older systems.
- Optional token usage metadata requires Swift 6.4/SDK 27 and OS 27+; otherwise it is absent.
- TypeDecoder is pinned to 2.0.0. See [third-party notices](THIRD_PARTY_NOTICES.md).

## Releases

`main` is the only integration branch. CI publishes a package tag and GitHub
Release after a merge increases the `VERSION` file and all checks pass. Merges
without a version increase run validation only. The workflow leaves the protected
branch locked; see [release procedure](RELEASING.md).

## License and repository access

AgentAtom and its example are **GNU AGPL v3 only (AGPL-3.0-only)**, not a
permission-required proprietary package. Use, modification, and redistribution
are permitted subject to [LICENSE](LICENSE). Review the applicable source-sharing
obligations before incorporating it into an application or network service.
Dependencies retain their own licenses. Copyright notices are in [COPYRIGHT](COPYRIGHT).

The default branch, `main`, is locked. Other users cannot directly change this
repository. Forks and AGPL-compliant modifications of other copies remain allowed.
See [contributor guidance](CONTRIBUTING.md) and [release procedure](RELEASING.md).

## Try the macOS app

Clone the repository and open
`Examples/AgentAtomDemo/AgentAtomDemo.xcodeproj`. The SwiftUI app demonstrates a
real local model request, streaming, cancellation, and final decoding. For a
development checkout, first run `Scripts/build-xcframework.sh` to prepare its
local binary; published version tags download the prebuilt archive automatically. See its
[README](Examples/AgentAtomDemo/README.md) for requirements and build commands.


## Specifications

`Spec` supplies identity, role, instructions, input JSON, and the expected output
JSON schema. `ModelledSpec<Input, Output>` derives JSON from an Encodable input and
schema from a Decodable output. Outputs need neither Encodable nor `@Generable`.
The spec's optional output storage is caller-owned; execution never writes to it.

`JSONString` preserves validated JSON text. Its dynamic initializer is failable;
invalid string literals are programmer errors. Foundation parsing accepts scalars
and null, and can accept extensions such as trailing commas on Apple platforms.

`JSONSchema` derives supported primitive, object, array, string-keyed dictionary,
and optional shapes through pinned TypeDecoder. Objects allow additional domain
keys; optional properties may be absent or null. Recursive/unsupported shapes and
excessive nesting fail derivation. Arbitrary raw-schema construction is not public.
Custom Decodable implementations are not guaranteed to be described completely by
model inspection. Domain validation, enum cases, and numeric-width rules are not
inferred. Existing ModelledSpec defaults use preconditionFailure on conversion
failure; these are programmer preconditions, not recoverable execution errors.

## Complete typed specification

```swift
import AgentAtom
import Foundation

struct SummaryOutput: Decodable, Sendable {
    let points: [String]
}

struct SummarySpec: ModelledSpec {
    static let identity = Identity(id: "summary", name: "Summary", version: "1")
    static let role = "Summarize supplied facts clearly."
    let instructions = "Return three distinct points supported by the input. Never invent facts."
    let input: String
    var output: SummaryOutput?
}

#if canImport(FoundationModels) && (os(macOS) || os(iOS) || os(visionOS))
@available(macOS 26, iOS 26, visionOS 26, *)
func summarize() async throws -> SummaryOutput? {
    guard let session = AppleIntelligenceSession() else { return nil }
    let spec = SummarySpec(input: "Asha opened a library. Ben donated books. Mira hosted a reading.")
    let operation = FailableAgenticOperation(spec: spec, session: session)
    let json = try await operation.execute().get()
    let output = try JSONDecoder().decode(SummaryOutput.self, from: Data(json.utf8))
    guard output.points.count == 3 else { return nil } // Caller-owned domain validation.
    return output
}
#endif
```

The following operation snippets assume the `spec` and caller's output type are
already defined, as in this example; the app provides a complete runnable project.

## Operations and results

Operations depend on `Spec` and an injected generic `AgenticSessionProtocol`.
They do not depend on `ModelledSpec` or decode domain output. Each operation
conforms to Swift's `Identifiable` and exposes its spec, `state`, `instructions()`,
and associated `Result` through `AgenticOperationProtocol`.

| Operation | `execute()` result | AI-declared failure allowed |
| --- | --- | --- |
| `AgenticOperation` | `Result<String, AgenticError>` | No |
| `FailableAgenticOperation` | `Result<String, AgenticError>` | Yes |
| `StreamingAgenticOperation` | `AsyncStream<Result<String, AgenticError>>` | No |
| `FailableStreamingAgenticOperation` | `AsyncStream<Result<String, AgenticError>>` | Yes |

All four can encounter provider errors or cancellation. Successful final content
is the session's response string. Operations preserve it unchanged. The caller
decodes and validates domain output afterward; the package never repairs JSON,
strips fences, unwraps success envelopes, or re-encodes domain output. Apple uses
native guided generation and returns `GeneratedContent.jsonString`. Shape enforcement
does not guarantee factual correctness or compliance with semantic instructions.

```swift
if #available(macOS 26, iOS 26, visionOS 26, *) {
    guard let session = AppleIntelligenceSession(configuration: .init(
        metadata: [.duration, .modelIdentifier]
    )) else {
        return
    }

    let operation = AgenticOperation(spec: spec, session: session)
    let response = await operation.execute()
    switch response {
    case .success(let json):
        let output = try JSONDecoder().decode(SummaryOutput.self, from: Data(json.utf8))
        // Retain and validate output in the caller.
    case .failure(let error):
        print(error.localizedDescription)
    }

    let nextResponse = await operation.execute()
    let records = session.executionMetadata
    // Same operation.id; each admitted run has a distinct records entry and executionID.
}
```

## Reuse, identity, and lifecycle

Operations use Identifiable's default ObjectIdentifier, stable for the object's
lifetime across runs. This identity is process-local and may be reused after the
object is deallocated; retain the operation when correlating its records.
Each operation is an actor retaining its immutable spec and session reference.
It owns its active task and execution state directly; callers need no task handle. Assigning another reference
preserves the same operation, identity, and active execution. Construct another
operation for independent identity and lifecycle control. There is no runner.

Call `execute()` again after completion or cancellation cleanup to start another
run. An overlapping call on the same operation returns `busy`. Only the active
producer Task is retained; operations store neither execution IDs nor result history.
They do not enqueue requests or retry automatically.

The session assigns a fresh execution UUID when it admits a run. Its read-only,
thread-safe `executionMetadata` array records the operation's ObjectIdentifier
and execution UUID after that run finishes, including provider failure and cancellation.
Identity is always recorded; configured metrics are optional. Admission failures
and instruction-assembly failures do not create an execution ID or record.

```swift
let latest = session.executionMetadata.last
let id = operation.id
let runs = session.executionMetadata.filter { $0.operationID == id }
```

`await operation.cancel()` cooperatively cancels the active producer. Cancellation
of a task awaiting a non-streaming operation also cancels its producer. Cancellation
does not free the session until its provider call returns and cleanup completes.
Cancelling an idle operation is a no-op and does not prevent a later execution.

`try await operation.pause()` and `resume()` delegate to the session for the active
operation. They throw `notRunning` when idle. Unsupported sessions throw
`unsupported` without changing the active execution.
`state` is ready, running, paused, cancelling, completed, cancelled, or failed.
Cancelling reserves the active slot until cleanup finishes. Terminal states permit
another execution. Pause/resume recheck the active task after suspension so a late
provider response cannot change a later run's state.
The Apple session has no native generation pause/resume support and uses these
explicit unsupported errors.

## Instructions and declared failures

Operations assemble final instructions on every call using the generic
strategy implementations; no forwarding-only assembler wrapper is needed. They send the spec role, rules, and original output
schema as provider instructions, with input JSON sent separately as prompt data.
They also send the response schema separately for provider-native generation.
Failable strategies add the reserved failure alternative to that request schema;
the spec schema itself remains unchanged.
A String input retains its JSON quoting and escaping. Session configuration does
not own roles, rules, or instruction overrides.

Failable operations append an alternative failure schema derived from a
Decodable shape. The model must use this reserved failure format:

```json
{"domain":"AgentAtom.Operation","code":422,"reason":"The input is insufficient."}
```

The original success schema remains unchanged. Failable operations convert a valid
reserved failure response into `generationFailed(reason:)`; standard operations
return `operationFailed` for it. Malformed reserved failure responses are also
invalid. All other final text passes through unchanged, including malformed domain
JSON for the caller to decode. Failure inspection uses one JSONDecoder pass. Malformed reserved failures remain
errors; unrelated domain output still passes through unchanged.
Intermediate streaming snapshots are not decoded.

Keep reference-backed spec input and computed request values stable during a run.
Domain constraints, fact checking, output decoding, and retry decisions belong to
the caller.

## Sessions and configuration

The class-bound, Sendable session protocol supplies generation primitives accepting finalized
instructions, input, response schema JSON, and an operation ObjectIdentifier. Streaming forwards snapshots through a
nonescaping async callback and returns the final result. Sessions own provider access,
configuration, per-run IDs, and execution records. Operations own lifecycle control
and final failure interpretation.
Sessions reject cancellation before admission and rely on provider cancellation during generation; operations
use that result without checking cancellation again after the session returns.
Non-streaming caller cancellation reaches the worker through a cancellation handler.
Streaming checks the caller before launching its independent producer; provider
stream cancellation and consumer termination handle the active run without snapshot polling.

`AppleIntelligenceSession` is a final Sendable class, compiled only where FoundationModels is supported
and is available on macOS/iOS/visionOS 26+. Its failable initializer checks device,
settings, and model readiness once. It uses `SystemLanguageModel.default` and one
file-level platform guard. The package retains its older deployment minimums.

Normal and streaming generation call the provider directly and share admission,
per-run identity, error mapping, and metadata helpers.
A mutex protects admission and record snapshots; provider work and callbacks run
outside the lock. The session does not create producer tasks.

The Apple adapter decodes the request schema with Apple's native Codable
`GenerationSchema`, supplying required object ordering and alternative names.
It uses native schema-based `respond`/`streamResponse` and exposes the generated
content's native JSON string, without requiring consumer output to be `@Generable`.
Objects use Apple's closed-property representation. Supported constraints include
required fields, nullable alternatives, arrays, string enums, numeric bounds,
and array counts. Unsupported keywords (including `format` and `contentEncoding`)
and non-string enums fail before admission instead of silently losing constraints.
The caller's spec owns domain rules such as result count; AgentAtom has no
KeyPoints-specific rules, count checks, extra feasibility calls, or automatic retries.

One Apple session admits one generation at a time; overlap returns `busy`. Use
independent sessions for concurrency. Every run uses a fresh provider conversation;
execution records are diagnostic metadata, not conversation history.

Configuration is fixed at initialization. Temperature defaults to 1 and clamps to
0...1 using Swift's min/max; NaN uses the default and infinities
clamp to the bounds. Response length follows the provider context limit.

`AgenticExecutionMetadata.Fields` is an OptionSet selecting independent metrics,
for example `metadata: [.duration, .tokenUsage]`. Optional metrics default to disabled.
Apple can collect model identifier, monotonic
generation duration, and token usage. Token counts use the guarded OS 27 SDK API;
unavailable counts stay absent and actual zero is preserved. The identifier is
`SystemLanguageModel.default`, not an invented model version. Unpopulated tier,
reasoning-effort, and finish-reason fields are omitted.

## Streaming

```swift
let operation = FailableStreamingAgenticOperation(spec: spec, session: session)
let stream = await operation.execute()
for await result in stream {
    switch result {
    case .success(let snapshot):
        print(snapshot) // Replace display content with the cumulative text.
    case .failure(let error):
        print(error.localizedDescription)
    }
}
```

Each stream has one consumer and buffers only its newest result. Intermediate
successes contain cumulative snapshots and can coalesce; they need not be prefix
extensions. After normal completion, the last element is the final success or
failure. Do not decode a partial snapshot as a completed result.

Call `await operation.cancel()` to stop generation without losing the consumer's
ability to receive the final cancellation failure. Cancelling the consuming task
also cancels the producer but terminates delivery, so its last received snapshot
might remain partial. Breaking the loop alone does not guarantee prompt cancellation.
Call `await operation.cancel()` before breaking early when generation should stop.
A rerun is available after the producer finishes cleanup.

## Errors and validation

`AgenticError` is a Sendable, Equatable Swift error with LocalizedError
descriptions. Its six cases are operationFailed(reason:), generationFailed(reason:), cancelled,
busy, notRunning, and unsupported. Provider, instruction, and response failures use
operationFailed with a diagnostic reason; AI-declared failure retains its reason separately. Public results do not require
NSError. Provider errors are mapped
once at the session boundary; the operation interprets only the reserved final
model-failure format.

Protocol extensions live with their declarations. Concrete implementations and
the typed error occupy separate files.
Each worker completes its lifecycle and releases its task before returning a result.
The four operation actors own their tasks directly; an internal actor protocol shares
lifecycle and execution defaults without adding a controller. Normal and streaming
execution each have one implementation; concrete actors only provide their stored
state, strategy, and a forwarding execute() method. Immutable generic strategies
share instruction assembly and final failure interpretation. The final session
class shares admission and completion helpers; it has no runner or unchecked Sendable conformance.
Concrete Result aliases witness the protocol using native Result or AsyncStream.
No public execution handle, response wrapper, queue, or schema translator is introduced.
Existing Spec, ModelledSpec, and JSONSchema implementations are unchanged.

## Build, test, and release

```sh
git clone https://github.com/abhi266raj/AgentAtom.git
cd AgentAtom
swift package resolve
Scripts/build-xcframework.sh
swift build
swift test
Scripts/verify-products.sh
```

Deterministic CI runs on macOS 26 and builds the library and example app. Live
Apple model checks remain opt-in. See [Tests/README.md](Tests/README.md) for
coverage, commands, and platform limitations; [CHANGELOG.md](CHANGELOG.md) for
version history; and [RELEASING.md](RELEASING.md) for versioned SwiftPM releases.

This repository starts with a reviewed package snapshot and a clean initial
commit. It contains no monorepo history. ScriptMakerServer temporarily keeps a
local snapshot; migration of its consumers to this repository is tracked separately.
