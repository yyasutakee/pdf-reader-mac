#!/bin/bash

set -euo pipefail

readonly TEAM_ID="YR53SS8TJ6"
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-PDFReaderNotarization}"

APPLE_ID="${1:-}"

if [[ -z "$APPLE_ID" ]]; then
    printf 'Usage: %s <apple-id-email>\n' "$0" >&2
    exit 64
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application.*($TEAM_ID)"; then
    printf 'No Developer ID Application certificate for team %s was found.\n' "$TEAM_ID" >&2
    printf 'Create one in Xcode > Settings > Accounts > Manage Certificates first.\n' >&2
    exit 1
fi

printf 'Apple will prompt for an app-specific password. It is stored in Keychain, not this repository.\n'
xcrun notarytool store-credentials "$NOTARY_PROFILE" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID"

printf 'Notarization profile "%s" is ready.\n' "$NOTARY_PROFILE"
