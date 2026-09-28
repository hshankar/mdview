#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 <version> [output-directory]" >&2
    exit 2
}

[ "$(uname -s)" = "Darwin" ] || {
    echo "error: release packages must be built on macOS" >&2
    exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

VERSION=${1#v}
case "$VERSION" in
    ''|*[!0-9A-Za-z.-]*) usage ;;
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
ARCHIVE_NAME="$STAGE_NAME.tar.gz"

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

[ -x "$BINARY" ] || {
    echo "error: release binary was not produced" >&2
    exit 1
}
[ -d "$RESOURCE_BUNDLE" ] || {
    echo "error: resource bundle was not produced" >&2
    exit 1
}

ARCHS=$(lipo -archs "$BINARY")
case " $ARCHS " in *" arm64 "*) ;; *) echo "error: arm64 slice is missing" >&2; exit 1 ;; esac
case " $ARCHS " in *" x86_64 "*) ;; *) echo "error: x86_64 slice is missing" >&2; exit 1 ;; esac

cp "$BINARY" "$STAGE_DIR/mdview"
cp -R "$RESOURCE_BUNDLE" "$STAGE_DIR/mdview_MDView.bundle"
cp install.sh "$STAGE_DIR/mdview-update"
cp README.md LICENSE THIRD_PARTY_NOTICES.md "$STAGE_DIR/"
cp -R ThirdParty "$STAGE_DIR/ThirdParty"
chmod 0755 "$STAGE_DIR/mdview" "$STAGE_DIR/mdview-update"

if [ -n "${MDVIEW_SIGNING_IDENTITY:-}" ]; then
    codesign --force --options runtime --timestamp \
        --sign "$MDVIEW_SIGNING_IDENTITY" "$STAGE_DIR/mdview"
elif [ "${MDVIEW_ALLOW_AD_HOC_SIGNING:-}" = "1" ]; then
    # CI builds use an explicit ad-hoc signature only for structural checks.
    codesign --force --sign - --timestamp=none "$STAGE_DIR/mdview"
else
    echo "error: set MDVIEW_SIGNING_IDENTITY to a Developer ID Application identity" >&2
    echo "error: set MDVIEW_ALLOW_AD_HOC_SIGNING=1 only for non-release CI builds" >&2
    exit 1
fi
codesign --verify --strict --verbose "$STAGE_DIR/mdview"

rm -f "$OUTPUT_DIR/$ARCHIVE_NAME" "$OUTPUT_DIR/$ARCHIVE_NAME.sha256"
tar -czf "$OUTPUT_DIR/$ARCHIVE_NAME" -C "$SCRATCH_DIR" "$STAGE_NAME"
(
    cd "$OUTPUT_DIR"
    shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
)

printf 'Created %s\n' "$OUTPUT_DIR/$ARCHIVE_NAME"
printf 'Created %s\n' "$OUTPUT_DIR/$ARCHIVE_NAME.sha256"
