# Contributing

The public repository is https://github.com/abhi266raj/AgentAtom.
The default branch, `main`, is locked against updates, force pushes, and deletion.
No public contributor has write access. Forks and proposed pull requests do not
change this repository. The owner controls whether an update is accepted.

Contributions are under AGPL-3.0-only; see [LICENSE](LICENSE). Submit an issue or
pull request with a concrete problem, focused change, and validation evidence.
Do not include credentials, model transcripts, build output, or personal data.

```sh
git clone https://github.com/abhi266raj/AgentAtom.git
cd AgentAtom
Scripts/build-xcframework.sh
swift build
swift test
Scripts/verify-products.sh
```

The root test suite imports AgentAtomSource. The consumer check tests both public
products separately. Changes to library code require a new versioned XCFramework;
see [distribution guidance](Distribution/README.md) and [RELEASING.md](RELEASING.md).

Tests use deterministic injected sessions. See [Tests/README.md](Tests/README.md)
for coverage and opt-in Apple model checks. Also build the
[macOS example](Examples/AgentAtomDemo/README.md) when changing public API.

AgentAtom owns generic specifications, operations, and sessions. Applications own
domain instructions, response decoding, factual validation, and retry policy.
Keep those boundaries intact. New behavior needs focused contract tests.
