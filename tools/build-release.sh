#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Codifide Inc. https://github.com/codifide/codifide-harness
# Build the release tarball and SHA256SUMS for a tag of this repository. No network.
#
#   bash tools/build-release.sh <tag> <out-dir>
#
# - The tag must exist, must equal v<VERSION> as recorded in that tag's VERSION file, and the
#   working tree must be clean.
# - The tarball is `git archive` of the tag (so untracked and ignored files, such as docs/, can never
#   enter it) plus a RELEASE file that install.sh reads to know it is an unpacked release.
# - Signing is a separate step (see .github/workflows/release.yml); this script never touches a key.
set -euo pipefail
export LC_ALL=C
for v in $(compgen -e | grep '^GIT_' || true); do unset "$v"; done
unset v
die(){ echo "build-release.sh: $*" >&2; exit 1; }
[[ $# -eq 2 ]] || { echo "usage: build-release.sh <tag> <out-dir>" >&2; exit 2; }
TAG="$1"; OUT="$2"
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "tag must look like v1.2.3"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
git -C "$ROOT" rev-parse -q --verify "refs/tags/$TAG^{commit}" >/dev/null || die "no such tag: $TAG"
[[ -z "$(git -C "$ROOT" status --porcelain)" ]] || die "the working tree is not clean"
COMMIT="$(git -C "$ROOT" rev-parse "$TAG^{commit}")"
TV="$(git -C "$ROOT" show "$TAG:VERSION" | head -n 1)"
[[ "v$TV" == "$TAG" ]] || die "the tag is $TAG but VERSION in that tag says $TV"
mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd -P)"
NAME="codifide-harness-$TV"
[[ ! -e "$OUT/$NAME.tar.gz" && ! -e "$OUT/SHA256SUMS" ]] || die "$OUT already holds a release; use an empty directory"
W="$(mktemp -d "${TMPDIR:-/tmp}/codifide-release.XXXXXX")"; trap 'rm -rf "$W"' EXIT
git -C "$ROOT" archive --format=tar --prefix="$NAME/" "$TAG" > "$W/$NAME.tar"
mkdir -p "$W/stage/$NAME"
printf 'tag=%s\ncommit=%s\n' "$TAG" "$COMMIT" > "$W/stage/$NAME/RELEASE"
tar -rf "$W/$NAME.tar" -C "$W/stage" "$NAME/RELEASE"
gzip -n -9 -c "$W/$NAME.tar" > "$OUT/$NAME.tar.gz"
if command -v shasum >/dev/null 2>&1; then (cd "$OUT" && shasum -a 256 "$NAME.tar.gz" > SHA256SUMS)
else (cd "$OUT" && sha256sum "$NAME.tar.gz" > SHA256SUMS); fi
echo "built $OUT/$NAME.tar.gz for $TAG ($COMMIT)"
cat "$OUT/SHA256SUMS"
