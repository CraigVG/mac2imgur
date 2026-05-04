# mac2imgur Modernization Fork — Design

**Author:** Craig Vandergalien
**Date:** 2026-05-04
**Status:** Approved
**Upstream:** [mileswd/mac2imgur](https://github.com/mileswd/mac2imgur) (last release March 2018, last commit February 2019)

---

## Background

`mac2imgur` is a Mac menu bar app that watches for screenshots and uploads them to Imgur. It has 957 stars on GitHub and the README explicitly states the project is no longer maintained. The 2018 binary is x86_64-only.

Two pressures motivate this fork:

1. **Rosetta 2 sunset.** macOS 26 Tahoe is the last release with general Rosetta 2 support (warnings appear in 26.4). macOS 27 ships September 2026 as the final release with Rosetta. macOS 28 removes it entirely. The existing Intel-only binary will stop working on Apple Silicon Macs in late 2027.
2. **Rotting infrastructure.** The codebase depends on Crashlytics + Fabric (Google killed Fabric in November 2020 — the project literally won't build today), an abandoned Objective-C Imgur SDK (`ImgurSession`), an obsolete login-item helper, Sparkle 1.x with known CVEs, and CocoaPods (in maintenance mode).

The Imgur API itself is healthy. Anonymous Client-ID uploads still work in 2026. The hardcoded keys in upstream's source have been public since 2018 and remain functional.

## Goals

- Native Apple Silicon binary (`arm64`) that runs cleanly on macOS 13+
- Drop-in replacement for the original on the user's Mac (same Bundle Identifier, preserves preferences and OAuth state)
- Public GitHub repo at `craigvandergalien/mac2imgur` with auto-updates via Sparkle 2
- Signed and notarized for friction-free downloads
- Architectural separation between business logic and UI shell, so a future SwiftUI rewrite (Tier 3) becomes a UI-layer swap rather than a full rewrite

## Non-goals

- New user-facing features. Same UX as the original. (Markdown links, multiple destinations, annotation, gallery, hotkey clipboard upload, CLI companion — all explicitly out of scope.)
- Backwards compatibility with macOS < 13. The original binary continues to work for macOS 10.9–12 users.
- App Store distribution.
- Telemetry or crash reporting.
- Importing upstream's 23 stale GitHub issues.

## Architecture

Two layers with a hard boundary enforced by Swift package targets.

```
┌─────────────────────────────────────────────────┐
│  Shell (App target — AppKit + SwiftUI Settings) │
│  • StatusItemController                         │
│  • MenuController                               │
│  • Settings { } scene (SwiftUI from day one)    │
└────────────────┬────────────────────────────────┘
                 │  observes @Observable types
                 │  calls async functions
┌────────────────▼────────────────────────────────┐
│  Core (Swift package — pure Foundation)         │
│  • ImgurClient (URLSession + async/await)       │
│  • OAuthCoordinator (ASWebAuthenticationSession)│
│  • ScreenshotMonitor (NSMetadataQuery)          │
│  • UploadHistory (@Observable)                  │
│  • Preferences (UserDefaults, stable keys)      │
│  • UploadedImage (value type)                   │
│  • Notifications (UNUserNotificationCenter)     │
│  • Secrets (clientID/clientSecret isolated)     │
└─────────────────────────────────────────────────┘
```

### Boundary rules

1. **Core target imports `Foundation` only.** No `AppKit`, no `SwiftUI`. Compile-time enforced by the package manifest.
2. **State exposure via `@Observable`** (Swift 5.9+). SwiftUI binds natively in Tier 3; AppKit reads via observation today.
3. **All async work uses `async`/`await`.** No completion handlers.
4. **UserDefaults keys are frozen and documented.** Tier 3 SwiftUI views will use `@AppStorage` against the same keys with zero migration on the user's machine.
5. **Settings UI is SwiftUI from day one** via the `Settings { }` scene (macOS 13+). About 30% of the Tier-2 UI is already SwiftUI; Tier 3 ports the menu controllers only.

### Tier 3 on-ramp

When Tier 3 happens, the work is:

- Replace `StatusItemController` and `MenuController` with `MenuBarExtra` (SwiftUI's menu bar API)
- Convert remaining AppKit views to SwiftUI views observing the same `Core` types
- Core code, preferences, and persisted state untouched

The `Core` package is the same code in both tiers. That is the entire point of this architecture.

### Deployment target

**macOS 13.0** (Ventura). Unlocks `SMAppService`, `Settings { }` scene, and modern `@Observable` patterns. The 2018 binary continues to serve macOS 10.9–12 users.

## Component Inventory

### Existing files — disposition

| Original | Action | New location |
|---|---|---|
| `AppDelegate.swift` | Modernize | `App/AppDelegate.swift` |
| `StatusItemController.swift` | Modernize | `App/Status/` |
| `StatusItemMenuController.swift` | Modernize | `App/Menu/` |
| `MenuController.swift`, `*MenuController.swift` (4 files) | Modernize | `App/Menu/` |
| `NSMenuExtension.swift` | Keep | `App/Menu/` |
| `AboutMenuController.swift` | **Delete** — replaced by SwiftUI About in Settings | — |
| `PreferencesMenuController.swift` | **Delete** — replaced by SwiftUI `Settings { }` | — |
| `UserNotificationController.swift` | **Replace** — `NSUserNotification` deprecated → `UNUserNotificationCenter` | `Sources/Core/Notifications.swift` |
| `ImgurClient.swift` | **Rewrite** — drop ImgurSession + Crashlytics, native `URLSession` + `async/await` | `Sources/Core/ImgurClient.swift` |
| `ImgurImageStore.swift` | Rewrite as `@Observable` history | `Sources/Core/UploadHistory.swift` |
| `IMGImage.swift` | Rewrite as `struct UploadedImage` | `Sources/Core/UploadedImage.swift` |
| `Preferences.swift` | Simplify, freeze keys | `Sources/Core/Preferences.swift` |
| `ScreenshotMonitor.swift` | Modernize with `NSMetadataQuery` | `Sources/Core/ScreenshotMonitor.swift` |

### Dependency disposition

| Original | Action | Replacement |
|---|---|---|
| `ImgurSession` (Obj-C, dead) | **Delete** | ~200 LOC native Swift `URLSession` in `ImgurClient` |
| `Crashlytics` | **Delete** | Nothing |
| `Fabric` | **Delete** | Nothing (Google killed it Nov 2020) |
| `EMCLoginItem` | **Delete** | `SMAppService` (built in, macOS 13+) |
| Hand-rolled OAuth web view | **Replace** | `ASWebAuthenticationSession` (built in) |
| `Sparkle 1.x` | **Upgrade** | Sparkle 2.x via SPM (requires fresh EdDSA keys) |
| `LetsMove` | Keep | Migrate to SPM if available, else inline |

### New files

```
Sources/Core/Secrets.swift            ← Imgur clientID/secret isolated
App/Settings/SettingsView.swift       ← SwiftUI Settings scene root
App/Settings/GeneralSettingsView.swift
App/Settings/ScreenshotsSettingsView.swift
App/Settings/AccountSettingsView.swift
App/Settings/UpdatesSettingsView.swift
```

### Final folder layout

```
mac2imgur/
├── App/                       ← Shell (AppKit + SwiftUI Settings)
│   ├── AppDelegate.swift
│   ├── Status/
│   ├── Menu/
│   ├── Settings/              ← SwiftUI today
│   └── Resources/
├── Sources/Core/              ← pure-Swift package, Foundation only
├── Tests/CoreTests/
├── Package.swift              ← Core package manifest
├── mac2imgur.xcodeproj
├── README.md
├── LICENSE                    ← GPL-3.0, verbatim from upstream
├── NOTICE.md                  ← copyright holders
├── CREDITS.md                 ← attribution detail
├── appcast.xml                ← Sparkle feed
├── docs/
│   ├── plans/                 ← this file lives here
│   └── release-smoke-test.md
└── .github/workflows/
    ├── build.yml
    └── release.yml
```

### Explicit YAGNI exclusions

- ❌ `UploadDestination` protocol for future S3/R2 — Tier 3 can add it
- ❌ Separate `imgur-cli` companion target
- ❌ Localization beyond what already exists in `Base.lproj`
- ❌ Crash reporting replacement

## Distribution & Release

### Bundle Identifier

Keep `com.mileswd.mac2imgur` verbatim. The new build cleanly replaces the 2018 install on the user's Mac and inherits all preferences and OAuth state. README explicitly credits the original and explains the choice.

### Versioning

- `CFBundleShortVersionString` (display): semver, starting at **`2.0.0`**
- `CFBundleVersion` (Sparkle comparison): integer, starting at **`300`** (continues from upstream's b226 so the 2018 build → v2.0.0 is a clean upgrade comparison)
- Git tags: `v2.0.0`, `v2.0.1`

### Code signing — Path B (Developer ID + notarization)

User has an Apple Developer account. Every release is signed with Developer ID Application certificate, notarized via `xcrun notarytool`, stapled, and zipped. Downloads have no Gatekeeper friction.

### Sparkle 2 from day one

- EdDSA keypair generated at project setup (`generate_keys` from Sparkle's tools)
- Public key embedded in `Info.plist` as `SUPublicEDKey`
- Private key stored as GitHub Actions secret `SPARKLE_PRIVATE_KEY`
- `appcast.xml` lives at the repo root, served via `raw.githubusercontent.com`
- `SUFeedURL` in `Info.plist` points at the raw GitHub URL
- Release workflow updates `appcast.xml` with each new version + signature + GitHub Release URL

### CI/CD

**`.github/workflows/build.yml`** — every push and PR
- macos-14 runner
- `xcodebuild build`
- `xcodebuild test -scheme mac2imgur-CoreTests`
- ~3–5 minutes total

**`.github/workflows/release.yml`** — on `v*` tag push
1. `xcodebuild test` (gate — fail blocks release)
2. `xcodebuild archive` for universal binary
3. Sign with Developer ID Application certificate
4. Notarize via `notarytool`
5. Staple
6. Generate Sparkle EdDSA signature
7. Zip the `.app`
8. Create GitHub Release with the zip
9. Update `appcast.xml` with new version, length, signature, URL
10. Commit `appcast.xml` change back to main

### GitHub Actions secrets required

- `SPARKLE_PRIVATE_KEY` — EdDSA private key for Sparkle signatures
- `MACOS_CERT` — base64-encoded `.p12` of Developer ID Application certificate
- `MACOS_CERT_PASSWORD` — password for the `.p12`
- `APPLE_ID` — Apple ID email
- `APPLE_APP_PASSWORD` — app-specific password from appleid.apple.com
- `APPLE_TEAM_ID` — Apple Developer Team ID

### Release cadence

No promises. Hobby project. Patch releases as needed.

## Repo & Licensing

### Strategy: clone-and-push (not GitHub Fork)

`git clone` from upstream, change `origin` to `craigvandergalien/mac2imgur`, push. Full first-class repo on the profile, fresh issue tracker, GitHub Pages enabled.

### License — GPL-3.0-or-later

Required by upstream's GPL-3.0 license — derivative works must remain GPL.

- `LICENSE` — GPL-3.0 text, verbatim from upstream
- `NOTICE.md` — copyright holders:
  - © 2013–2018 Miles Wu (original work)
  - © 2026 Craig Vandergalien (modernization, additions)
- `CREDITS.md` — detailed attribution: ImgurSession (replaced), Sparkle, LetsMove, mileswd

### Source file headers

- **Modified existing files:** keep original GPL-3.0 header, add `// Modifications © 2026 Craig Vandergalien`
- **New files:** standard GPL-3.0 header with Craig's copyright

### Branding

- Same name (`mac2imgur`) — discoverability for users searching for the original
- Same icon for v2.0.0
- README first paragraph credits Miles Wu prominently

### Upstream issues

Don't import. README directs new issues to this repo, notes that pre-existing mac2imgur issues are not tracked here.

## Testing & Verification

### Unit tests — `Tests/CoreTests/`

Swift Testing framework (`import Testing`), runs in CI on every push.

| Module | Happy path | Error path |
|---|---|---|
| `ImgurClient` | Anonymous + authed upload, multipart encoding | 4xx/5xx mapping, rate-limit detection |
| `OAuthCoordinator` | Token refresh on 401 | Refresh-token expiry, malformed response |
| `UploadHistory` | Add/persist/restore | Eviction at max N |
| `Preferences` | Round-trip per key, **stability test asserts every key matches Tier-3 `@AppStorage` keys** | — |
| `ScreenshotMonitor` | Detects new screenshot in test directory | Ignores non-screenshots, handles bursts |
| `Notifications` | Authorization gate, formatting | — |

**Coverage philosophy:** every Core module gets at least one happy-path test and one error-path test. No coverage badge, no chasing numbers.

### Explicitly skipped

- AppKit menu controller tests (manual smoke instead)
- SwiftUI snapshot tests (brittle, low signal)
- Sparkle integration tests (manual with fake appcast)
- Real Imgur API calls in CI (burns shared rate limit)

### Manual smoke test checklist

Lives at `docs/release-smoke-test.md`. Run before every tag. Covers: install + migration, upload flows, OAuth account, preferences, Sparkle update flow.

### Definition of done for v2.0.0

A v2.0.0 release ships only when all green:

1. ✅ All Core unit tests pass in CI
2. ✅ Smoke-test checklist run by hand on Apple Silicon
3. ✅ Release workflow produces a notarized, stapled `.app`
4. ✅ Sparkle `appcast.xml` updated and committed
5. ✅ Downloaded zip from GitHub Releases opens cleanly with no Gatekeeper warning
6. ✅ README + NOTICE.md + CREDITS.md attributions correct

## Risks & Open Questions

### Risks

- **Imgur Client-ID revocation.** The hardcoded key has been public since 2018 and is shared with the original mac2imgur user base. If Imgur audits and revokes it, both the original and this fork die simultaneously. Mitigation: keys live in `Sources/Core/Secrets.swift`, swap is a 2-line change + release.
- **Sparkle EdDSA migration.** Users updating from the 2018 build (DSA keys) cannot auto-update — they must download v2.0.0 manually once. Auto-updates work from v2.0.0 → v2.0.1 onward. Acceptable per design discussion.
- **Bundle ID namespace.** Using `com.mileswd.mac2imgur` is mildly awkward but mileswd hasn't shipped in 7 years and isn't returning. Trade-off accepted for clean drop-in replacement on the user's Mac.

### Open questions deferred to implementation

- Exact `NSMetadataQuery` predicate for screenshot detection (validate against macOS 13/14/15 screenshot file naming)
- Whether to inline `LetsMove` (~50 LOC) or wait for an SPM-compatible release
- `Settings { }` scene visual layout — match original Preferences window or restyle slightly

## Approval

Design approved by Craig Vandergalien on 2026-05-04. Implementation plan to be created next via the `writing-plans` skill.
