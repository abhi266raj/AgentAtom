#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-only
# Called by CI only after merged source and binary checks pass.
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(cat VERSION)"
source_commit="$(git rev-parse HEAD)"
artifact_tag="artifacts-$version"
repo="abhi266raj/AgentAtom"
archive=".build/distribution/AgentAtom.xcframework.zip"
checksum="$(cat .build/distribution/checksum.txt)"
test "$(swift package compute-checksum "$archive")" = "$checksum"
test -z "$(git status --porcelain)"
existing_tag="$(git rev-parse --verify "refs/tags/$version^{commit}" 2>/dev/null || true)"
notes="$(mktemp)"
trap 'rm -f "$notes"' EXIT
cat > "$notes" <<TEXT
AgentAtom $version XCFramework artifact.

Corresponding source commit: $source_commit (merged main).
SHA-256: $checksum

Deployment targets: macOS 14, iOS/tvOS 16, watchOS 9, visionOS 1.
Nine platform variants, including device/simulator architectures.
AGPL-3.0-only; TypeDecoder 2.0.0 is statically linked under Apache-2.0.

Toolchain:
TEXT
cat .build/distribution/toolchain.txt >> "$notes"
if gh release view "$artifact_tag" --repo "$repo" > /dev/null 2>&1; then
    # Retry with the original bytes only for the same merged source commit.
    previous="$(mktemp -d)"
    gh release download "$artifact_tag" --repo "$repo" --pattern AgentAtom.xcframework.zip \
        --pattern checksum.txt --pattern toolchain.txt --dir "$previous"
    test "$(tail -1 "$previous/toolchain.txt")" = "$source_commit"
    checksum="$(cat "$previous/checksum.txt")"
    test "$(swift package compute-checksum "$previous/AgentAtom.xcframework.zip")" = "$checksum"
    cp "$previous/AgentAtom.xcframework.zip" "$previous/checksum.txt" "$previous/toolchain.txt" .build/distribution/
    rm -rf "$previous"
else
    gh release create "$artifact_tag" "$archive" .build/distribution/checksum.txt \
        .build/distribution/toolchain.txt --repo "$repo" --target "$source_commit" \
        --prerelease --title "AgentAtom $version binary artifact" --notes-file "$notes"
fi
# Only the generated tag commit changes; never push a commit to main.
swift Scripts/Release.swift manifest "$version" "$checksum" Package.swift
Scripts/verify-products.sh
# Verify the public download and checksum before creating the package tag.
if [ -n "$existing_tag" ]; then
    test "$(git rev-parse "$existing_tag^")" = "$source_commit"
    test "$(git show "$existing_tag:Package.swift")" = "$(cat Package.swift)"
else
    git add Package.swift
    git -c user.name='github-actions[bot]' -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
        -c commit.gpgsign=false commit -m "Release $version package manifest (source $source_commit)"
    git -c user.name='github-actions[bot]' -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
        -c tag.gpgsign=false tag -a "$version" -m "AgentAtom $version"
    git push origin "refs/tags/$version"
fi
if gh release view "$version" --repo "$repo" > /dev/null 2>&1; then
    printf 'Release %s already published; nothing to replace.\n' "$version"
    exit 0
fi
cat > "$notes" <<TEXT
AgentAtom $version offers two SwiftPM products from the same package URL:

- **AgentAtom**: recommended precompiled dynamic XCFramework, import AgentAtom.
- **AgentAtomSource**: same implementation built from source, import AgentAtomSource.

Binary artifacts: https://github.com/$repo/releases/tag/$artifact_tag
Corresponding merged main source: $source_commit
Binary SHA-256: $checksum

See the artifact's toolchain.txt for the validated Xcode/Swift toolchain.
The source product requires Swift 6.0+ (Xcode 26+ for Apple Intelligence).
The Apple provider runs only on supported macOS/iOS/visionOS 26+ systems.
Both variants remain AGPL-3.0-only. Choose one product per dependency graph.
0.0.1 remains source-only; source clients upgrading must import AgentAtomSource.
The tag includes a generated manifest commit whose parent is the merged source;
the protected main branch is not modified by the release workflow.
TEXT
gh release create "$version" --repo "$repo" --verify-tag --latest \
    --title "AgentAtom $version" --notes-file "$notes"
