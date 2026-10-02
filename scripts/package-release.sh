#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 <version> [output-directory]" >&2
    exit 64
}

[ "$(uname -s)" = "Darwin" ] || {
    echo "package-release: macOS is required" >&2
    exit 1
}
[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

VERSION=${1#v}
case "$VERSION" in
    ''|*[!0-9.]*) usage ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
OUTPUT_DIR=${2:-"$ROOT/dist"}
case "$OUTPUT_DIR" in
    /*) ;;
    *) OUTPUT_DIR="$(pwd)/$OUTPUT_DIR" ;;
esac

SCRATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mdview-release.XXXXXX")
STAGE_NAME="mdview-$VERSION-macos-universal"
STAGE_DIR="$SCRATCH_DIR/$STAGE_NAME"
VERSIONED_ARCHIVE="mdview-$VERSION-macos-universal.tar.gz"
LATEST_ARCHIVE="mdview-macos-universal.tar.gz"

cleanup() {
    rm -rf "$SCRATCH_DIR"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$OUTPUT_DIR" "$STAGE_DIR"

cd "$ROOT"
swift build \
    -c release \
    --arch arm64 \
    --arch x86_64 \
    --scratch-path "$SCRATCH_DIR/build"

BIN_PATH=$(swift build \
    -c release \
    --arch arm64 \
    --arch x86_64 \
    --scratch-path "$SCRATCH_DIR/build" \
    --show-bin-path)

BINARY="$BIN_PATH/mdview"
RESOURCE_BUNDLE="$BIN_PATH/mdview_MDView.bundle"
[ -x "$BINARY" ] || { echo "package-release: mdview was not produced" >&2; exit 1; }
[ -d "$RESOURCE_BUNDLE" ] || { echo "package-release: resources were not produced" >&2; exit 1; }
[ "$("$BINARY" --version)" = "mdview $VERSION" ] || {
    echo "package-release: binary version does not match $VERSION" >&2
    exit 1
}

ARCHS=$(lipo -archs "$BINARY")
case " $ARCHS " in *" arm64 "*) ;; *) echo "package-release: arm64 slice is missing" >&2; exit 1 ;; esac
case " $ARCHS " in *" x86_64 "*) ;; *) echo "package-release: x86_64 slice is missing" >&2; exit 1 ;; esac

MINIMUM_VERSIONS=$(vtool -show-build "$BINARY" | awk '$1 == "minos" { print $2 }' | sort -u)
[ "$MINIMUM_VERSIONS" = "13.0" ] || {
    echo "package-release: expected macOS 13.0 deployment target, found $MINIMUM_VERSIONS" >&2
    exit 1
}

install -m 0755 "$BINARY" "$STAGE_DIR/mdview"
cp -R "$RESOURCE_BUNDLE" "$STAGE_DIR/mdview_MDView.bundle"
install -m 0755 scripts/create-app-bundle.sh "$STAGE_DIR/create-app-bundle.sh"
install -m 0755 install.sh "$STAGE_DIR/install.sh"
cp README.md LICENSE THIRD_PARTY_NOTICES.md "$STAGE_DIR/"
cp -R ThirdParty "$STAGE_DIR/ThirdParty"

if [ -n "${MDVIEW_SIGNING_IDENTITY:-}" ]; then
    codesign --force --options runtime --timestamp \
        --sign "$MDVIEW_SIGNING_IDENTITY" "$STAGE_DIR/mdview"
else
    codesign --force --sign - --timestamp=none "$STAGE_DIR/mdview"
fi
codesign --verify --strict "$STAGE_DIR/mdview"

rm -f \
    "$OUTPUT_DIR/$VERSIONED_ARCHIVE" \
    "$OUTPUT_DIR/$VERSIONED_ARCHIVE.sha256" \
    "$OUTPUT_DIR/$LATEST_ARCHIVE" \
    "$OUTPUT_DIR/$LATEST_ARCHIVE.sha256"

tar -czf "$OUTPUT_DIR/$VERSIONED_ARCHIVE" -C "$SCRATCH_DIR" "$STAGE_NAME"
cp "$OUTPUT_DIR/$VERSIONED_ARCHIVE" "$OUTPUT_DIR/$LATEST_ARCHIVE"
(
    cd "$OUTPUT_DIR"
    shasum -a 256 "$VERSIONED_ARCHIVE" > "$VERSIONED_ARCHIVE.sha256"
    shasum -a 256 "$LATEST_ARCHIVE" > "$LATEST_ARCHIVE.sha256"
)

printf 'Created %s\n' "$OUTPUT_DIR/$VERSIONED_ARCHIVE"
printf 'Created %s\n' "$OUTPUT_DIR/$VERSIONED_ARCHIVE.sha256"
printf 'Created %s\n' "$OUTPUT_DIR/$LATEST_ARCHIVE"
printf 'Created %s\n' "$OUTPUT_DIR/$LATEST_ARCHIVE.sha256"
