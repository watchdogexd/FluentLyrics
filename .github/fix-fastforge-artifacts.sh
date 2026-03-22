#!/bin/bash

VERSION_STRING=$(echo "$RELEASE_VERSION" | sed 's/^v//')
IFS='+'
read -r -a parts <<< "$VERSION_STRING"
unset IFS

VERSION_NAME="${parts[0]}"
VERSION_CODE="${parts[1]}"

DIST_DIR="dist/$VERSION_STRING"

if command -v rename.ul >/dev/null 2>&1; then
    RENAME_CMD="rename.ul"
elif command -v rename >/dev/null 2>&1 && rename --version 2>&1 | grep -q 'util-linux'; then
    RENAME_CMD="rename"
else
    echo "Error: util-linux 'rename' utility not found."
    exit 1
fi

rm "$DIST_DIR"/*.apk
cp build/app/outputs/flutter-apk/*.apk "$DIST_DIR"/
$RENAME_CMD -- "app" "fluent_lyrics-$VERSION_STRING" "$DIST_DIR"/*.apk
$RENAME_CMD -- ".apk" "-android.apk" "$DIST_DIR"/*.apk

$RENAME_CMD -- "$VERSION_STRING" "$VERSION_NAME" "$DIST_DIR"/*
$RENAME_CMD -- "-release" "" "$DIST_DIR"/*
