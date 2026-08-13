# Local DMG distribution

The release scripts archive, Developer ID-sign, package, notarize, staple, and validate `PDFReader` entirely
on this Mac. GitHub Actions is not used.

## One-time setup

1. In Xcode, open **Xcode > Settings > Accounts**.
2. Select the Apple Developer account for team `YR53SS8TJ6`.
3. Open **Manage Certificates** and create a **Developer ID Application** certificate.
4. Create an app-specific password at `appleid.apple.com`.
5. Store the notarization credentials in Keychain:

   ```bash
   ./Scripts/setup-notarization.sh your-apple-id@example.com
   ```

The password is stored by `notarytool` in Keychain. It is never written into the repository.

## Create a notarized DMG

Commit all changes, then double-click **Create DMG.command** in Finder. Enter a version such as `1.0.1`
when prompted. The launcher runs the complete release process and reveals the finished DMG in Finder.

The command-line equivalent is:

```bash
./Scripts/release.sh 1.0.0
```

The finished artifact is written to `dist/PDFReader-1.0.0.dmg`. Intermediate files live in `.release/`.
Both directories are ignored by Git.

The build number defaults to the Git commit count. Override it when needed:

```bash
BUILD_NUMBER=42 ./Scripts/release.sh 1.0.0
```

## Publish to GitHub Releases

Install and authenticate GitHub CLI once:

```bash
brew install gh
gh auth login
```

Then create the version tag, push it, create the GitHub Release, and upload the DMG in one command:

```bash
./Scripts/release.sh 1.0.0 --publish
```

Publishing is optional. Without `--publish`, the script only creates the local notarized DMG.

## Alternative notarization profile

The default Keychain profile is `PDFReaderNotarization`. Override it for both setup and release:

```bash
NOTARY_PROFILE=AnotherProfile ./Scripts/setup-notarization.sh your-apple-id@example.com
NOTARY_PROFILE=AnotherProfile ./Scripts/release.sh 1.0.0
```
