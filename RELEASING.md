# Releasing

AgentAtom uses one public repository, immutable semantic-version tags, and two
SwiftPM products. The next package release is **0.1.0**. Release **0.0.1** remains
unchanged and source-only. Pre-1.0 releases may change integration requirements;
prefer exact versions for reproducibility.

## Prepare an artifact and PR

1. Create a feature branch. Update source, tests, README, demo version, changelog,
   and distribution guidance. Both products must build the same implementation.
2. Run `Scripts/build-xcframework.sh` on a Mac with all supported SDKs. Inspect
   all nine slices, public interfaces, `@rpath` linkage, and packaged notices.
3. Commit the artifact inputs. Publish an immutable **prerelease** artifact tag
   `artifacts-0.1.0` at that commit, attaching AgentAtom.xcframework.zip and
   checksum.txt. Record source SHA, Xcode/Swift versions, deployment targets, and
   the archive checksum in its release notes. This is staging, not the package
   release. Never reuse or replace an artifact URL after publication.
4. Set the manifest binary URL and SHA-256 to those staged assets. Commit the
   manifest and open a PR targeting master. Never move the 0.0.1 tag.
5. Run `swift build`, `swift test`, `Scripts/verify-products.sh`, and build the
   example as documented in Examples/AgentAtomDemo/README.md. Confirm CI is green,
   including binary consumer builds on the supported platforms.
6. Review licenses and notices. The XCFramework includes AGPL and TypeDecoder's
   Apache-2.0 notices; the public source is the corresponding implementation.

## Publish the package after approval

`master` is locked for administrators too. Only the repository owner may
explicitly approve a merge and temporarily unlock it. Merge the reviewed PR,
restore the lock immediately, and confirm the merged commit passes CI. Never
permit force pushes or deletion or grant outsiders direct write access.

Tag that verified master commit **0.1.0** and publish matching release notes.
Link the immutable artifact prerelease and describe both products, import names,
minimum toolchain, and the 0.0.1 source-to-binary integration change. Do not retag
or replace assets. Confirm an independent consumer resolves exact version 0.1.0
for each product and runs the public contract suite before announcing completion.

ScriptMakerServer retains its separate local snapshot until its migration task is
implemented. Publishing AgentAtom does not change that application's dependencies.
