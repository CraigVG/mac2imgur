# Setup Guide

This document covers everything needed to get the project building locally and to ship a signed/notarized public release.

## Local development

```bash
git clone https://github.com/CraigVG/mac2imgur.git
cd mac2imgur
brew install xcodegen
xcodegen generate
open mac2imgur.xcodeproj
```

That's it. Xcode 16+ is required. macOS 14 (Sonoma) is the minimum runtime target.

To run tests from the command line:

```bash
swift test
```

To regenerate the Xcode project after editing `project.yml`:

```bash
xcodegen generate
```

The `mac2imgur.xcodeproj` directory is committed to the repo (so contributors don't need XcodeGen just to open it), but `project.yml` is the source of truth.

## CI: build & test

`.github/workflows/build.yml` runs on every push and PR:

- Generates the Xcode project
- Runs `swift test` (Core unit tests)
- Builds the app target with `CODE_SIGNING_ALLOWED=NO`

No secrets needed.

## CI: release

`.github/workflows/release.yml` runs on every `v*` tag push. It needs the following GitHub Actions secrets (all set under repo Settings → Secrets and variables → Actions):

| Secret | What it is | How to get it |
|---|---|---|
| `SPARKLE_PRIVATE_KEY` | EdDSA private key for signing Sparkle updates | ✅ Already set. Generated locally via `generate_keys`, stored in macOS Keychain at "https://sparkle-project.org" / "ed25519". |
| `MACOS_CERT` | Base64-encoded `.p12` of Developer ID Application cert | Export your "Developer ID Application: Craig Vander Galien (XXXX)" from Keychain Access as a `.p12`, then `base64 -i cert.p12 \| pbcopy`. Paste as the secret. |
| `MACOS_CERT_PASSWORD` | Password used when exporting the `.p12` | Whatever you set during export. |
| `APPLE_ID` | Apple ID email | `craigvandergalien@gmail.com` |
| `APPLE_APP_PASSWORD` | App-specific password | Create at appleid.apple.com → Sign-In and Security → App-Specific Passwords. Label it "mac2imgur notarization". |
| `APPLE_TEAM_ID` | Developer Team ID | Find at developer.apple.com → Account → Membership. 10-character string like `XXXXXXXXXX`. |

To set them via CLI:

```bash
gh secret set MACOS_CERT --repo CraigVG/mac2imgur
gh secret set MACOS_CERT_PASSWORD --repo CraigVG/mac2imgur
gh secret set APPLE_ID --repo CraigVG/mac2imgur
gh secret set APPLE_APP_PASSWORD --repo CraigVG/mac2imgur
gh secret set APPLE_TEAM_ID --repo CraigVG/mac2imgur
```

## Cutting a release

```bash
# 1. Bump version in project.yml (MARKETING_VERSION + CURRENT_PROJECT_VERSION)
# 2. Regenerate
xcodegen generate
git add -A && git commit -m "[release] Bump version to vX.Y.Z" && git push

# 3. Run smoke test (docs/release-smoke-test.md)

# 4. Tag and push
git tag -a v2.0.0 -m "v2.0.0 - Modernized fork, Apple Silicon native"
git push origin v2.0.0

# 5. Watch the workflow
gh run watch
```

The workflow will build, sign, notarize, sign Sparkle update, create GitHub Release, and append to `appcast.xml`. About 7-10 minutes end-to-end (notarization is the slow step).

## EdDSA key recovery

The Sparkle private key is stored in the macOS Keychain on the machine where `generate_keys` was run. To extract:

```bash
security find-generic-password -s "https://sparkle-project.org" -a "ed25519" -w
```

Keep a backup somewhere safe (1Password, encrypted backup). Losing this key means existing installs can't auto-update.
