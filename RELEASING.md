# Releasing

AgentAtom is distributed through its public Git repository and semantic-version
tags. Swift Package Manager has no mandatory central publishing step. Consumers
add `https://github.com/abhi266raj/AgentAtom.git` and select version `0.0.1`.

The initial release is `0.0.1` (Git tag `0.0.1`). Pre-1.0 versions may change API;
use an exact version when reproducibility matters.

Before a release:

1. Update CHANGELOG.md and all affected documentation/examples.
2. Run `swift package resolve`, `swift build`, and `swift test` from a clean clone.
3. Build Examples/AgentAtomDemo as documented in its README.
4. Confirm macOS CI is green and a separate package resolves the proposed version.
5. Review the published files and license/dependency notices.
6. Tag the verified master commit and publish matching GitHub release notes.
7. Confirm the remote tag resolves through Swift Package Manager.

`master` is read-only, including for administrators. Only the repository owner
may temporarily unlock it to merge a reviewed update; restore the lock afterward.
Never enable force pushes or deletion. Never move an existing release tag.
The initial bootstrap publishes its first commit and verifies CI before tagging
and enabling the permanent master lock. No outside collaborators receive write access.

ScriptMakerServer currently retains a separate local snapshot. This repository
is the canonical source for future AgentAtom development. Synchronizing that
snapshot or replacing it with a remote dependency is an explicit separate change.
