#!/bin/bash

set -euo pipefail

readonly APP_NAME="PDFReader"
readonly PROJECT_NAME="PDFReader.xcodeproj"
readonly SCHEME_NAME="PDFReader"
readonly TEAM_ID="YR53SS8TJ6"
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-PDFReaderNotarization}"
readonly SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
readonly EXPORT_OPTIONS_PATH="$SCRIPT_DIRECTORY/ExportOptions-DeveloperID.plist"

VERSION="${1:-}"
PUBLISH_TO_GITHUB=false

if [[ "${2:-}" == "--publish" ]]; then
    PUBLISH_TO_GITHUB=true
elif [[ -n "${2:-}" ]]; then
    printf 'Unknown option: %s\n' "$2" >&2
    exit 64
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf 'Usage: %s <version: x.y.z> [--publish]\n' "$0" >&2
    exit 64
fi

readonly BUILD_NUMBER="${BUILD_NUMBER:-$(git -C "$PROJECT_ROOT" rev-list --count HEAD)}"
readonly WORK_DIRECTORY="$PROJECT_ROOT/.release/$VERSION"
readonly ARCHIVE_PATH="$WORK_DIRECTORY/$APP_NAME.xcarchive"
readonly EXPORT_DIRECTORY="$WORK_DIRECTORY/export"
readonly DISK_IMAGE_STAGING_DIRECTORY="$WORK_DIRECTORY/disk-image"
readonly DERIVED_DATA_DIRECTORY="$WORK_DIRECTORY/DerivedData"
readonly DISTRIBUTION_DIRECTORY="$PROJECT_ROOT/dist"
readonly DISK_IMAGE_PATH="$DISTRIBUTION_DIRECTORY/$APP_NAME-$VERSION.dmg"

require_command() {
    local command_name="$1"
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Required command is missing: %s\n' "$command_name" >&2
        exit 1
    }
}

find_developer_id_identity() {
    security find-identity -v -p codesigning \
        | awk -v team="$TEAM_ID" '/Developer ID Application/ && index($0, team) { print $2; exit }'
}

verify_prerequisites() {
    require_command xcodebuild
    require_command xcrun
    require_command hdiutil
    require_command ditto
    require_command codesign
    require_command security
    require_command git

    if [[ -n "$(git -C "$PROJECT_ROOT" status --porcelain)" && "${RELEASE_ALLOW_DIRTY:-0}" != "1" ]]; then
        printf 'The working tree is not clean. Commit changes before releasing.\n' >&2
        printf 'Set RELEASE_ALLOW_DIRTY=1 only when intentionally testing an unreleased tree.\n' >&2
        exit 1
    fi

    if [[ ! -f "$EXPORT_OPTIONS_PATH" ]]; then
        printf 'Export options are missing: %s\n' "$EXPORT_OPTIONS_PATH" >&2
        exit 1
    fi

    DEVELOPER_IDENTITY="$(find_developer_id_identity)"
    if [[ -z "$DEVELOPER_IDENTITY" ]]; then
        printf 'No Developer ID Application certificate for team %s was found.\n' "$TEAM_ID" >&2
        printf 'Create one in Xcode > Settings > Accounts > Manage Certificates, then run:\n' >&2
        printf '  ./Scripts/setup-notarization.sh <apple-id-email>\n' >&2
        exit 1
    fi

    if [[ "$PUBLISH_TO_GITHUB" == true ]]; then
        require_command gh
        gh auth status >/dev/null
    fi
}

prepare_directories() {
    rm -rf "$WORK_DIRECTORY"
    mkdir -p "$EXPORT_DIRECTORY" "$DISK_IMAGE_STAGING_DIRECTORY" "$DISTRIBUTION_DIRECTORY"
    rm -f "$DISK_IMAGE_PATH"
}

archive_application() {
    printf 'Archiving %s %s (%s)...\n' "$APP_NAME" "$VERSION" "$BUILD_NUMBER"
    xcodebuild archive \
        -project "$PROJECT_ROOT/$PROJECT_NAME" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        -archivePath "$ARCHIVE_PATH" \
        -derivedDataPath "$DERIVED_DATA_DIRECTORY" \
        -allowProvisioningUpdates \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
        DEVELOPMENT_TEAM="$TEAM_ID"
}

export_application() {
    printf 'Exporting Developer ID application...\n'
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_DIRECTORY" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -allowProvisioningUpdates
}

verify_application_signature() {
    local application_path="$EXPORT_DIRECTORY/$APP_NAME.app"
    if [[ ! -d "$application_path" ]]; then
        printf 'Exported application was not found: %s\n' "$application_path" >&2
        exit 1
    fi
    codesign --verify --deep --strict --verbose=2 "$application_path"
}

create_disk_image() {
    printf 'Creating disk image...\n'
    ditto "$EXPORT_DIRECTORY/$APP_NAME.app" "$DISK_IMAGE_STAGING_DIRECTORY/$APP_NAME.app"
    ln -s /Applications "$DISK_IMAGE_STAGING_DIRECTORY/Applications"
    hdiutil create \
        -volname "$APP_NAME" \
        -srcfolder "$DISK_IMAGE_STAGING_DIRECTORY" \
        -format UDZO \
        -ov \
        "$DISK_IMAGE_PATH"
    codesign --force --timestamp --sign "$DEVELOPER_IDENTITY" "$DISK_IMAGE_PATH"
}

notarize_disk_image() {
    printf 'Submitting disk image for notarization...\n'
    xcrun notarytool submit "$DISK_IMAGE_PATH" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait
    xcrun stapler staple "$DISK_IMAGE_PATH"
    xcrun stapler validate "$DISK_IMAGE_PATH"
    codesign --verify --verbose=2 "$DISK_IMAGE_PATH"
}

publish_github_release() {
    local tag_name="v$VERSION"
    printf 'Publishing GitHub release %s...\n' "$tag_name"

    if ! git -C "$PROJECT_ROOT" rev-parse --verify --quiet "refs/tags/$tag_name" >/dev/null; then
        git -C "$PROJECT_ROOT" tag -a "$tag_name" -m "$APP_NAME $VERSION"
    fi

    git -C "$PROJECT_ROOT" push origin "$tag_name"
    gh release create "$tag_name" "$DISK_IMAGE_PATH" \
        --repo "$(gh repo view --json nameWithOwner --jq .nameWithOwner)" \
        --title "$APP_NAME $VERSION" \
        --generate-notes
}

main() {
    cd "$PROJECT_ROOT"
    verify_prerequisites
    prepare_directories
    archive_application
    export_application
    verify_application_signature
    create_disk_image
    notarize_disk_image
    if [[ "$PUBLISH_TO_GITHUB" == true ]]; then publish_github_release; fi
    printf 'Release ready: %s\n' "$DISK_IMAGE_PATH"
}

main
