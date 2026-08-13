#!/bin/bash

set -u

readonly PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_ROOT"

printf '\nCreate a signed and notarized PDFReader DMG\n\n'
read -r -p 'Version (for example, 1.0.1): ' VERSION

if [[ -z "$VERSION" ]]; then
    printf '\nNo version was entered. Nothing was created.\n'
    read -r -p 'Press Return to close this window.'
    exit 64
fi

if "$PROJECT_ROOT/Scripts/release.sh" "$VERSION"; then
    readonly DISK_IMAGE_PATH="$PROJECT_ROOT/dist/PDFReader-$VERSION.dmg"
    printf '\nFinished. Finder will show the DMG.\n'
    open -R "$DISK_IMAGE_PATH"
    read -r -p 'Press Return to close this window.'
    exit 0
fi

printf '\nThe DMG could not be created. Review the error above.\n'
read -r -p 'Press Return to close this window.'
exit 1
