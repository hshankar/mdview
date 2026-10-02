#!/bin/sh
set -eu

REPOSITORY=${MDVIEW_REPOSITORY:-hshankar/mdview}
VERSION=${MDVIEW_VERSION:-}
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mdview-install.XXXXXX")

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM

fail() {
    echo "mdview installer: $*" >&2
    exit 1
}

[ "$(uname -s)" = "Darwin" ] || fail "macOS is required"

ARCH=$(uname -m)
case "$ARCH" in
    arm64|x86_64) ;;
    *) fail "unsupported Mac architecture: $ARCH" ;;
esac

MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$MACOS_MAJOR" -ge 13 ] || fail "macOS 13 or newer is required"

if [ -n "${MDVIEW_ARCHIVE:-}" ]; then
    [ -f "$MDVIEW_ARCHIVE" ] || fail "archive not found: $MDVIEW_ARCHIVE"
    ARCHIVE="$TEMP_DIR/$(basename "$MDVIEW_ARCHIVE")"
    cp "$MDVIEW_ARCHIVE" "$ARCHIVE"

    CHECKSUM_SOURCE=${MDVIEW_CHECKSUM_FILE:-"$MDVIEW_ARCHIVE.sha256"}
    [ -f "$CHECKSUM_SOURCE" ] || fail "checksum not found: $CHECKSUM_SOURCE"
    CHECKSUM="$TEMP_DIR/$(basename "$CHECKSUM_SOURCE")"
    cp "$CHECKSUM_SOURCE" "$CHECKSUM"
else
    if [ -n "$VERSION" ]; then
        VERSION=${VERSION#v}
        TAG="v$VERSION"
        ASSET="mdview-$VERSION-macos-universal.tar.gz"
        RELEASE_URL="https://github.com/$REPOSITORY/releases/download/$TAG"
    else
        ASSET="mdview-macos-universal.tar.gz"
        RELEASE_URL="https://github.com/$REPOSITORY/releases/latest/download"
    fi

    ARCHIVE="$TEMP_DIR/$ASSET"
    CHECKSUM="$TEMP_DIR/$ASSET.sha256"
    curl --fail --location --silent --show-error \
        "$RELEASE_URL/$ASSET" --output "$ARCHIVE" || fail "archive download failed"
    curl --fail --location --silent --show-error \
        "$RELEASE_URL/$ASSET.sha256" --output "$CHECKSUM" || fail "checksum download failed"
fi

[ -s "$ARCHIVE" ] || fail "downloaded archive is empty"
[ -s "$CHECKSUM" ] || fail "downloaded checksum is empty"
(
    cd "$TEMP_DIR"
    shasum -a 256 -c "$(basename "$CHECKSUM")"
) || fail "checksum verification failed"

tar -xzf "$ARCHIVE" -C "$TEMP_DIR"
PACKAGE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name 'mdview-*-macos-universal' | head -1)
[ -n "$PACKAGE_DIR" ] || fail "release archive has an unexpected layout"
[ -x "$PACKAGE_DIR/mdview" ] || fail "release archive does not contain mdview"
[ -d "$PACKAGE_DIR/mdview_MDView.bundle" ] || fail "release archive is missing resources"
[ -x "$PACKAGE_DIR/create-app-bundle.sh" ] || fail "release archive is missing the app builder"

ARCHS=$(lipo -archs "$PACKAGE_DIR/mdview")
case " $ARCHS " in *" $ARCH "*) ;; *) fail "release does not support $ARCH" ;; esac
codesign --verify --strict "$PACKAGE_DIR/mdview" || fail "release signature verification failed"

if [ -n "${MDVIEW_INSTALL_DIR:-}" ]; then
    INSTALL_DIR=$MDVIEW_INSTALL_DIR
elif [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
    INSTALL_DIR=/usr/local/bin
elif [ -d /usr/local ] && [ -w /usr/local ]; then
    INSTALL_DIR=/usr/local/bin
else
    INSTALL_DIR="$HOME/.local/bin"
fi
APP_DIR=${MDVIEW_APP_DIR:-"$HOME/Applications"}

mkdir -p "$INSTALL_DIR" "$APP_DIR" || fail "cannot create installation directories"
[ -w "$INSTALL_DIR" ] || fail "$INSTALL_DIR is not writable; set MDVIEW_INSTALL_DIR"
[ -w "$APP_DIR" ] || fail "$APP_DIR is not writable; set MDVIEW_APP_DIR"

NEW_BINARY="$INSTALL_DIR/.mdview-new-$$"
NEW_BUNDLE="$INSTALL_DIR/.mdview_MDView.bundle-new-$$"
rm -rf "$NEW_BINARY" "$NEW_BUNDLE"
install -m 0755 "$PACKAGE_DIR/mdview" "$NEW_BINARY"
cp -R "$PACKAGE_DIR/mdview_MDView.bundle" "$NEW_BUNDLE"

# Stop the warm viewer so the next document uses the replacement binary.
pkill -f '[m]dview --server' 2>/dev/null || true
rm -rf "$INSTALL_DIR/mdview_MDView.bundle"
mv "$NEW_BUNDLE" "$INSTALL_DIR/mdview_MDView.bundle"
mv "$NEW_BINARY" "$INSTALL_DIR/mdview"

"$PACKAGE_DIR/create-app-bundle.sh" \
    "$INSTALL_DIR/mdview" \
    "$APP_DIR/MDView.app" \
    "$INSTALL_DIR/mdview"

if [ "${MDVIEW_REGISTER_APP:-1}" = "1" ]; then
    LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
    "$LSREGISTER" -f "$APP_DIR/MDView.app"
fi

"$INSTALL_DIR/mdview" --version
printf 'Installed mdview to %s/mdview\n' "$INSTALL_DIR"
printf 'Installed MDView.app to %s/MDView.app\n' "$APP_DIR"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        printf '\nAdd mdview to your PATH:\n  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
        ;;
esac
