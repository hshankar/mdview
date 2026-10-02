#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <source-mdview> <output-app> [installed-mdview-path]" >&2
    exit 64
}

[[ $# -eq 2 || $# -eq 3 ]] || usage

source_binary=$1
output_app=$2
installed_binary=${3:-$source_binary}
resource_bundle="$(dirname "$source_binary")/mdview_MDView.bundle"
resource_directory=$resource_bundle
if [[ -d "$resource_bundle/Contents/Resources" ]]; then
    resource_directory="$resource_bundle/Contents/Resources"
fi

[[ -x "$source_binary" ]] || {
    echo "create-app-bundle: mdview executable not found: $source_binary" >&2
    exit 1
}
[[ -d "$resource_bundle" ]] || {
    echo "create-app-bundle: resource bundle not found: $resource_bundle" >&2
    exit 1
}
[[ -f "$resource_directory/AppIcon.icns" ]] || {
    echo "create-app-bundle: app icon not found in resource bundle: $resource_bundle" >&2
    exit 1
}

# Finder launches script applications through Apple events rather than passing
# document paths as process arguments. This small droplet translates each open
# event into the same CLI invocation used from a terminal.
escape_applescript_string() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

escaped_binary=$(escape_applescript_string "$installed_binary")
temporary_script=$(mktemp "${TMPDIR:-/tmp}/mdview-app.XXXXXX.applescript")
trap 'rm -f "$temporary_script"' EXIT

cat >"$temporary_script" <<APPLESCRIPT
property mdviewExecutable : "$escaped_binary"

on run
    return
end run

on open openedFiles
    repeat with openedFile in openedFiles
        do shell script quoted form of mdviewExecutable & " " & quoted form of POSIX path of openedFile
    end repeat
end open
APPLESCRIPT

rm -rf "$output_app"
mkdir -p "$(dirname "$output_app")"
osacompile -o "$output_app" "$temporary_script"

plist="$output_app/Contents/Info.plist"
plist_buddy=/usr/libexec/PlistBuddy

set_or_add_string() {
    local key=$1
    local value=$2
    "$plist_buddy" -c "Set :$key $value" "$plist" 2>/dev/null \
        || "$plist_buddy" -c "Add :$key string $value" "$plist"
}

version=$("$source_binary" --version | awk '{print $NF}')
set_or_add_string CFBundleIdentifier com.hshankar.mdview
set_or_add_string CFBundleDisplayName MDView
set_or_add_string CFBundleShortVersionString "$version"
set_or_add_string CFBundleVersion "$version"
set_or_add_string CFBundleIconFile MDView
set_or_add_string CFBundleIconName MDView

# osacompile creates a wildcard document declaration for droplets. Narrow it to
# Markdown so Launch Services offers MDView only for supported documents.
"$plist_buddy" -c 'Delete :CFBundleDocumentTypes' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes array' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0 dict' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeName string Markdown Document' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:LSHandlerRank string Default' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions array' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:0 string md' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:1 string markdown' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:2 string mdtext' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:LSItemContentTypes array' "$plist"
"$plist_buddy" -c 'Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string net.daringfireball.markdown' "$plist"

cp "$resource_directory/AppIcon.icns" "$output_app/Contents/Resources/MDView.icns"
plutil -lint "$plist" >/dev/null
codesign --force --deep --sign - "$output_app" >/dev/null

# osacompile registers every output bundle immediately. Build and DESTDIR
# locations may be temporary, so leave registration to the installer after the
# app reaches its final path. Otherwise Launch Services can retain a dead app
# path and report error -50 when opening a Markdown file.
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$lsregister" -u "$output_app" >/dev/null 2>&1 || true

echo "Created $output_app"
