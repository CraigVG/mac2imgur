# mac2imgur Modernization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Resurrect `mileswd/mac2imgur` as a modern, native Apple Silicon menu bar app published at `CraigVG/mac2imgur` with auto-updates, signed and notarized, while preserving the same Bundle Identifier and UX so the new build is a drop-in replacement on existing users' Macs.

**Architecture:** Two-layer split enforced by Swift packages. `Sources/Core/` is pure-Foundation business logic (Imgur upload, OAuth, screenshot detection, history, preferences) exposed via `@Observable` and `async`/`await`. `App/` is the AppKit menu bar shell plus a SwiftUI `Settings { }` scene. Tier-3 future work replaces only the Shell with SwiftUI; Core is unchanged.

**Tech Stack:** Swift 5.9+, Xcode 16+, macOS 13+ (Ventura), Swift Package Manager, Swift Testing (`import Testing`), AppKit (status bar shell), SwiftUI (Settings scene), Sparkle 2 (auto-updates), `URLSession` (Imgur API), `ASWebAuthenticationSession` (OAuth), `SMAppService` (login at launch), `NSMetadataQuery` (screenshot detection), `UNUserNotificationCenter` (notifications), GitHub Actions (CI/CD), Apple Developer ID (signing + notarization).

**Source design doc:** [`2026-05-04-mac2imgur-fork-design.md`](./2026-05-04-mac2imgur-fork-design.md). All architectural decisions trace back there.

**Working tree:** `~/mac2imgur` (already cloned from `mileswd/mac2imgur`, upstream remote removed).

---

## Verification gospel

- **Every task ends with a commit.** No exceptions. Small commits are the unit of progress.
- **Verification before completion.** A task is not "done" until the verification command in its final step exits 0 (or shows the expected output). See the `superpowers:verification-before-completion` skill.
- **TDD for Core.** Write failing test, watch it fail, write minimal code, watch it pass. Then commit. See `superpowers:test-driven-development`.
- **No skipping.** If a task is blocked, stop and report. Do not push past a failing test or build.

## Commit message convention

`[area] short imperative summary`

Examples:
- `[setup] Add NOTICE.md and CREDITS.md`
- `[core] Add ImgurClient anonymous upload`
- `[shell] Replace EMCLoginItem with SMAppService`
- `[ci] Add release workflow`

---

# Phase 0 — Repo Setup & Attribution

Goal: Establish `CraigVG/mac2imgur` as a public repo, with proper attribution and the upstream remote permanently severed. No code changes.

### Task 0.1: Verify clean working tree

**Step 1: Check status**

```bash
cd ~/mac2imgur
git status
git log --oneline | head -3
git remote -v
```

**Expected:**
- Working tree clean
- HEAD commit is `7dda3cc Add modernization fork design doc`
- No remote (we removed `origin` earlier)

If origin still exists, run `git remote remove origin`.

### Task 0.2: Create `CraigVG/mac2imgur` on GitHub

**Step 1: Create the empty repo via gh CLI**

```bash
gh repo create CraigVG/mac2imgur \
  --public \
  --description "A modern fork of mac2imgur — native Apple Silicon Mac app for uploading screenshots to Imgur. Originally by Miles Wu." \
  --homepage "https://github.com/CraigVG/mac2imgur" \
  --license GPL-3.0
```

**Note:** the `--license` flag will create a `LICENSE` in the new repo. We don't push to it yet; this is just the empty remote being initialized. We'll overwrite that LICENSE with the upstream verbatim file in Task 0.5.

**Step 2: Verify**

```bash
gh repo view CraigVG/mac2imgur --json name,visibility,licenseInfo
```

Expected: name, visibility public, licenseInfo with GPL-3.0.

### Task 0.3: Wire local repo to new origin

**Step 1: Add origin (SSH per global rules)**

```bash
cd ~/mac2imgur
git remote add origin git@github.com:CraigVG/mac2imgur.git
git remote -v
```

**Expected:** origin points at `git@github.com:CraigVG/mac2imgur.git`.

### Task 0.4: Force-push our local history (overwrites the empty new repo's auto-generated commits)

**Step 1: Push master**

```bash
cd ~/mac2imgur
git push --force --set-upstream origin master
```

**Expected:** push succeeds, upstream tracking set. Visit https://github.com/CraigVG/mac2imgur in a browser and verify history (the original mileswd commits + our design doc commit).

### Task 0.5: Verify LICENSE is upstream's verbatim GPL-3.0

**Step 1: Inspect**

```bash
cd ~/mac2imgur
head -20 LICENSE
```

**Expected:** Starts with `GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007`. If GitHub's auto-generated LICENSE replaced it, restore from history:

```bash
git checkout HEAD -- LICENSE
```

(No commit needed if file is already correct.)

### Task 0.6: Add NOTICE.md

**Step 1: Create file**

```bash
cd ~/mac2imgur
cat > NOTICE.md << 'EOF'
# Copyright Notice

This software is a derivative work of mac2imgur, originally created by Miles Wu.

## Copyright Holders

- Copyright © 2013–2018 Miles Wu — Original work ([github.com/mileswd/mac2imgur](https://github.com/mileswd/mac2imgur))
- Copyright © 2026 Craig Vandergalien — Modernization, additions, and ongoing maintenance ([github.com/CraigVG/mac2imgur](https://github.com/CraigVG/mac2imgur))

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

See [LICENSE](./LICENSE) for the full GPL-3.0 text.
EOF
```

**Step 2: Commit**

```bash
git add NOTICE.md
git commit -m "[setup] Add NOTICE.md crediting Miles Wu and Craig Vandergalien"
git push
```

### Task 0.7: Add CREDITS.md

**Step 1: Create file**

```bash
cd ~/mac2imgur
cat > CREDITS.md << 'EOF'
# Credits

## Original work

mac2imgur was created by **Miles Wu** ([github.com/mileswd](https://github.com/mileswd))
in 2013 and actively maintained through 2018. This fork picks up where that work
stopped and modernizes it for Apple Silicon and modern macOS.

The original repository remains at [github.com/mileswd/mac2imgur](https://github.com/mileswd/mac2imgur).

## Replaced dependencies

The original mac2imgur depended on several libraries that this fork has removed
or replaced:

- **ImgurSession** by Geoff MacDonald — the Objective-C Imgur SDK has been
  replaced with a native Swift `URLSession` implementation. Original work at
  [github.com/geoffmacd/ImgurSession](https://github.com/geoffmacd/ImgurSession).
- **EMCLoginItem** — replaced with Apple's modern `SMAppService` API.
- **Crashlytics + Fabric** — removed (Google sunset Fabric in November 2020).

## Current dependencies

- **Sparkle 2** ([sparkle-project.org](https://sparkle-project.org)) — auto-updates
- **LetsMove** by Andy Kim ([github.com/potionfactory/LetsMove](https://github.com/potionfactory/LetsMove)) — prompts to move app to /Applications

## Imgur API

mac2imgur uses the [Imgur API](https://apidocs.imgur.com/). All uploaded images
are subject to Imgur's terms of service.
EOF
```

**Step 2: Commit**

```bash
git add CREDITS.md
git commit -m "[setup] Add CREDITS.md attributing dependencies and original work"
git push
```

### Task 0.8: Rewrite README.md to reflect the fork

**Step 1: Replace README**

Open `README.md` and replace its entire contents with:

```markdown
# mac2imgur

A simple Mac menu bar app that uploads screenshots and images to [Imgur](https://imgur.com), with the link automatically copied to your clipboard.

> A drop-in modernized fork of [mac2imgur](https://github.com/mileswd/mac2imgur) by [Miles Wu](https://github.com/mileswd) (2013–2018). Native Apple Silicon, signed and notarized, auto-updating via Sparkle 2. Same Bundle Identifier as the original, so installing this version cleanly replaces an existing 2018 install and preserves your preferences and Imgur login.

## Installation

[Download the latest release](https://github.com/CraigVG/mac2imgur/releases/latest), unzip, and drag `mac2imgur.app` to `/Applications`.

**Requirements:** macOS 13 (Ventura) or later, Apple Silicon or Intel.

## Usage

The app lives in your menu bar. It listens for new screenshots taken by macOS's built-in screenshot tools:

- <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>3</kbd> — full-screen screenshot
- <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>4</kbd> — rectangular selection
- <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>4</kbd> + <kbd>Space</kbd> — capture a specific window

Images can also be uploaded manually:
- Drag and drop images onto the menu bar icon
- Click the menu bar icon and choose "Upload Images…"

When an upload completes, the link is copied to your clipboard and a notification appears.

## Preferences

Open Preferences from the menu bar icon (or <kbd>⌘</kbd> + <kbd>,</kbd>):

- **Launch at Login** — start mac2imgur when you log in
- **Delete After Upload** — move screenshots to Trash after they upload
- **Confirmation Before Upload** — preview each screenshot and choose whether to upload
- **Imgur Account** — sign in to upload to your account, optionally to a specific album

## Updates

The app updates itself silently in the background using [Sparkle 2](https://sparkle-project.org). The first install is manual; subsequent updates are automatic.

## Origin and License

This is a modernized fork of the original [mac2imgur](https://github.com/mileswd/mac2imgur) by Miles Wu. See [NOTICE.md](./NOTICE.md) for copyright holders and [CREDITS.md](./CREDITS.md) for dependency attribution.

Licensed under [GPL-3.0-or-later](./LICENSE).

## Issues

Open an issue at [github.com/CraigVG/mac2imgur/issues](https://github.com/CraigVG/mac2imgur/issues). Pre-existing issues on the original repo are not tracked here.
```

**Step 2: Commit**

```bash
cd ~/mac2imgur
git add README.md
git commit -m "[setup] Rewrite README for modernized fork"
git push
```

---

# Phase 1 — Strip Dead Dependencies

Goal: Remove all dependencies that no longer compile or aren't needed. The project will not build at the end of this phase — that's expected. Phase 2 rebuilds the foundation.

### Task 1.1: Delete CocoaPods artifacts

**Step 1: Remove files**

```bash
cd ~/mac2imgur
rm -rf Podfile Podfile.lock Pods/ mac2imgur.xcworkspace
ls Podfile* mac2imgur.xcworkspace 2>&1 || echo "All removed"
```

**Step 2: Commit**

```bash
git add -A
git commit -m "[deps] Remove CocoaPods artifacts (Podfile, Pods/, .xcworkspace)"
git push
```

### Task 1.2: Strip Crashlytics and Fabric imports from `ImgurClient.swift`

**Step 1: Remove imports and call sites**

Open `mac2imgur/ImgurClient.swift`. Remove the line `import Crashlytics`. Find every `Crashlytics.sharedInstance().recordError(...)` call and delete the entire line (including indentation). Find every `Crashlytics.sharedInstance().setObjectValue(...)` and delete.

After editing, verify no Crashlytics references remain in the file:

```bash
grep -n -i crashlytics mac2imgur/ImgurClient.swift
```

**Expected:** no output.

**Step 2: Commit**

```bash
git add mac2imgur/ImgurClient.swift
git commit -m "[deps] Strip Crashlytics calls from ImgurClient"
```

### Task 1.3: Strip Crashlytics/Fabric from AppDelegate

**Step 1: Edit `mac2imgur/AppDelegate.swift`**

Remove `import Fabric`, `import Crashlytics`, and any `Fabric.with([...])` initialization line.

**Step 2: Verify**

```bash
grep -nE "(crashlytics|fabric)" -i mac2imgur/AppDelegate.swift
```

**Expected:** no output.

**Step 3: Commit**

```bash
git add mac2imgur/AppDelegate.swift
git commit -m "[deps] Strip Crashlytics/Fabric from AppDelegate"
```

### Task 1.4: Strip Crashlytics from any remaining files

**Step 1: Search**

```bash
cd ~/mac2imgur
grep -rln -iE "(crashlytics|fabric)" mac2imgur/ || echo "No remaining references"
```

**Step 2: For each file returned, remove imports and calls. Then verify and commit.**

```bash
git status
git diff --stat
git add -A
git commit -m "[deps] Strip Crashlytics/Fabric from remaining files"
```

If no files are returned, skip the commit.

### Task 1.5: Remove `ImgurSession` import (will rewrite ImgurClient in Phase 3)

**Step 1: Edit ImgurClient.swift**

Remove the `import ImgurSession` line. The class will not compile anymore — that's expected.

**Step 2: Find other ImgurSession usages**

```bash
grep -rn ImgurSession mac2imgur/
grep -rn IMGSession mac2imgur/
grep -rn IMGImage mac2imgur/
```

Note all the files. Don't remove the symbols yet — Phase 3 rewrites `ImgurClient` and the dependent classes will then be fixed.

**Step 3: Commit just the ImgurSession import removal**

```bash
git add mac2imgur/ImgurClient.swift
git commit -m "[deps] Remove ImgurSession import (rewrite incoming in Phase 3)"
```

### Task 1.6: Remove EMCLoginItem usage from Preferences

**Step 1: Edit `mac2imgur/Preferences.swift`**

Find the `EMCLoginItem` reference. Comment it out for now with `// TODO(Phase 4): replace with SMAppService` — keeping the variable hole compilable later. Or, if it's only used in one place, delete it and the surrounding "Launch at Login" wiring entirely (we'll re-implement in Phase 4).

**Step 2: Verify no EMC* references**

```bash
grep -rn EMC mac2imgur/ || echo "Clean"
```

**Step 3: Commit**

```bash
git add mac2imgur/Preferences.swift
git commit -m "[deps] Remove EMCLoginItem references (SMAppService replacement in Phase 4)"
```

### Task 1.7: Delete the old DSA Sparkle public key

**Step 1: Remove file**

```bash
cd ~/mac2imgur
rm mac2imgur/dsa_pub.pem
```

**Step 2: Commit**

```bash
git add -A
git commit -m "[deps] Remove DSA Sparkle public key (EdDSA in Phase 6)"
git push
```

---

# Phase 2 — Project Structure & SPM

Goal: Reorganize source into the `App/` + `Sources/Core/` layout, create a `Package.swift` for Core, modernize the Xcode project, set deployment target to macOS 13, and wire up Sparkle 2 + LetsMove via SPM.

### Task 2.1: Reorganize source folders

**Step 1: Create new directory structure**

```bash
cd ~/mac2imgur
mkdir -p App/Status App/Menu App/Settings App/Resources
mkdir -p Sources/Core
mkdir -p Tests/CoreTests
```

**Step 2: Move Shell files to `App/`**

```bash
git mv mac2imgur/AppDelegate.swift App/AppDelegate.swift
git mv mac2imgur/StatusItemController.swift App/Status/StatusItemController.swift
git mv mac2imgur/StatusItemMenuController.swift App/Menu/StatusItemMenuController.swift
git mv mac2imgur/MenuController.swift App/Menu/MenuController.swift
git mv mac2imgur/ImgurMenuController.swift App/Menu/ImgurMenuController.swift
git mv mac2imgur/ImgurAlbumMenuController.swift App/Menu/ImgurAlbumMenuController.swift
git mv mac2imgur/UploadsMenuController.swift App/Menu/UploadsMenuController.swift
git mv mac2imgur/NSMenuExtension.swift App/Menu/NSMenuExtension.swift
git mv mac2imgur/Info.plist App/Resources/Info.plist
git mv mac2imgur/Assets.xcassets App/Resources/Assets.xcassets
git mv mac2imgur/Base.lproj App/Resources/Base.lproj
```

**Step 3: Delete files we're replacing entirely**

```bash
git rm mac2imgur/AboutMenuController.swift
git rm mac2imgur/PreferencesMenuController.swift
git rm mac2imgur/UserNotificationController.swift  # rewriting in Core
```

**Step 4: Stage Core source files (will be rewritten in Phase 3, but move now)**

```bash
git mv mac2imgur/ImgurClient.swift Sources/Core/ImgurClient.swift
git mv mac2imgur/ImgurImageStore.swift Sources/Core/UploadHistory.swift
git mv mac2imgur/IMGImage.swift Sources/Core/UploadedImage.swift
git mv mac2imgur/Preferences.swift Sources/Core/Preferences.swift
git mv mac2imgur/ScreenshotMonitor.swift Sources/Core/ScreenshotMonitor.swift
```

**Step 5: Verify the old `mac2imgur/` directory is empty and remove it**

```bash
ls mac2imgur/ 2>&1
rmdir mac2imgur/
```

**Step 6: Commit**

```bash
git add -A
git commit -m "[structure] Reorganize source into App/ and Sources/Core/"
git push
```

### Task 2.2: Create Package.swift for the Core target

**Step 1: Create file at repo root**

```bash
cd ~/mac2imgur
cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "mac2imgurCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        )
    ]
)
EOF
```

**Step 2: Verify it parses**

```bash
swift package describe 2>&1 | head -20
```

**Expected:** package metadata printed; no errors. (Build will fail because Core sources still reference removed deps — that's fine, this just verifies the manifest is valid.)

**Step 3: Commit**

```bash
git add Package.swift
git commit -m "[structure] Add Package.swift declaring Core target"
git push
```

### Task 2.3: Update Xcode project — bump deployment target and remove pod references

**Step 1: Open the project**

```bash
open mac2imgur.xcodeproj
```

**Step 2: In Xcode**

- Select the project root in the navigator
- Under "Project" → "mac2imgur" → Build Settings → Deployment → set **macOS Deployment Target** to `13.0`
- Under "Targets" → "mac2imgur" → General → Deployment Info → confirm `macOS 13.0`
- Build Settings → search "Pods" — remove any `Pods.xcconfig` references in the Configurations section (set Debug and Release to "None")
- Frameworks, Libraries, and Embedded Content — remove any pod-derived items (Crashlytics.framework, Fabric.framework, ImgurSession, EMCLoginItem, etc.)
- Build Phases → remove the "Copy Pods Resources", "Check Pods Manifest.lock", "Embed Pods Frameworks" script phases

**Step 3: Try a build (expected: many compile errors)**

```bash
xcodebuild -project mac2imgur.xcodeproj -scheme mac2imgur -configuration Debug clean build 2>&1 | tail -30
```

**Expected:** errors about `EMCLoginItem`, `IMGSession`, `Sparkle`, `LetsMove` not found. That's fine — we're tearing the foundation out.

**Step 4: Commit project changes**

```bash
git add mac2imgur.xcodeproj
git commit -m "[structure] Bump deployment target to macOS 13, remove pod references"
git push
```

### Task 2.4: Add Sparkle 2 via SPM

**Step 1: In Xcode**

- File → Add Package Dependencies
- URL: `https://github.com/sparkle-project/Sparkle`
- Dependency Rule: **Up to Next Major** from `2.6.0` (or whatever current is)
- Add Package
- Select the `mac2imgur` target to add Sparkle to

**Step 2: Verify**

The `Package.resolved` should now exist at `mac2imgur.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Confirm:

```bash
cat mac2imgur.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | head -20
```

**Expected:** Sparkle entry with a pinned revision.

**Step 3: Commit**

```bash
git add mac2imgur.xcodeproj
git commit -m "[deps] Add Sparkle 2 via SPM"
git push
```

### Task 2.5: Add LetsMove via SPM (or inline if no SPM build available)

**Step 1: Check if LetsMove has SPM support**

Visit `https://github.com/potionfactory/LetsMove` in a browser. Look for `Package.swift` in the repo root.

**Step 2a: If SPM available**

In Xcode: File → Add Package Dependencies → URL `https://github.com/potionfactory/LetsMove`. Add to `mac2imgur` target.

**Step 2b: If no SPM available — inline**

Copy `PFMoveApplication.h` and `PFMoveApplication.m` directly from upstream into `App/Resources/LetsMove/`. Add a bridging header reference in the target's Build Settings → "Objective-C Bridging Header".

**Step 3: Commit**

```bash
git add -A
git commit -m "[deps] Add LetsMove (SPM or inline)"
git push
```

### Task 2.6: Verify Core package alone compiles in isolation

The Core sources will still fail (they reference `ImgurSession`), but verify the package structure is valid.

**Step 1: Try to compile Core**

```bash
cd ~/mac2imgur
swift build --target Core 2>&1 | tail -20
```

**Expected:** errors about `ImgurSession` not found in `Sources/Core/ImgurClient.swift`. The package itself is valid; the source code is the broken thing. Phase 3 fixes that.

**No commit needed** — this is just a verification step.

---

# Phase 3 — Build the Core (TDD)

Goal: Rewrite each Core module test-first. Each module gets at least one happy-path test and one error-path test. Unit tests run via `swift test`.

### Task 3.1: Add Swift Testing import support and a smoke test

**Step 1: Create the smoke test**

```bash
cat > Tests/CoreTests/SmokeTests.swift << 'EOF'
import Testing
@testable import Core

@Suite("Smoke")
struct SmokeTests {
    @Test("Core module compiles and imports cleanly")
    func coreImports() {
        // If this test file builds, the Core module exports correctly.
        #expect(true)
    }
}
EOF
```

**Step 2: Run it (expected: fails to build because Core won't compile)**

```bash
swift test --filter Smoke 2>&1 | tail -20
```

**Expected:** build errors from existing `ImgurClient.swift`. We'll fix in subsequent tasks.

**Step 3: Temporarily neutralize broken Core files so other tests can run**

For each file in `Sources/Core/` that won't compile, replace its contents with a placeholder:

```bash
cd ~/mac2imgur
for f in Sources/Core/ImgurClient.swift Sources/Core/UploadHistory.swift Sources/Core/UploadedImage.swift Sources/Core/Preferences.swift Sources/Core/ScreenshotMonitor.swift; do
  echo "// Placeholder — rewritten in Phase 3" > "$f"
done
```

**Step 4: Run smoke test**

```bash
swift test --filter Smoke 2>&1 | tail -10
```

**Expected:** PASS.

**Step 5: Commit**

```bash
git add Tests/CoreTests/SmokeTests.swift Sources/Core/
git commit -m "[core] Add Core smoke test, neutralize legacy sources for rewrite"
git push
```

### Task 3.2: `Secrets.swift` — isolate Imgur Client-ID/Secret

**Files:**
- Create: `Sources/Core/Secrets.swift`
- Test: `Tests/CoreTests/SecretsTests.swift`

**Step 1: Write failing test**

```swift
// Tests/CoreTests/SecretsTests.swift
import Testing
@testable import Core

@Suite("Secrets")
struct SecretsTests {
    @Test("Imgur client ID is the upstream-compatible value")
    func clientID() {
        #expect(Secrets.imgurClientID == "5867856c9027819")
    }

    @Test("Imgur client secret is set")
    func clientSecret() {
        #expect(!Secrets.imgurClientSecret.isEmpty)
    }
}
```

**Step 2: Run — verify it fails**

```bash
swift test --filter Secrets 2>&1 | tail -5
```

**Expected:** error about `Secrets` undefined.

**Step 3: Implement**

```swift
// Sources/Core/Secrets.swift
import Foundation

/// Imgur API credentials.
///
/// These are the upstream `mileswd/mac2imgur` keys, public on GitHub since 2018,
/// kept here for drop-in compatibility with the original install. If Imgur ever
/// revokes them, swap these two constants and ship a new release.
public enum Secrets {
    public static let imgurClientID = "5867856c9027819"
    public static let imgurClientSecret = "7c2a63097cbb0f10f260291aab497be458388a64"
}
```

**Step 4: Run — verify it passes**

```bash
swift test --filter Secrets 2>&1 | tail -5
```

**Expected:** 2 tests passed.

**Step 5: Commit**

```bash
git add Sources/Core/Secrets.swift Tests/CoreTests/SecretsTests.swift
git commit -m "[core] Add Secrets module isolating Imgur API credentials"
git push
```

### Task 3.3: `UploadedImage.swift` — value type for upload results

**Files:**
- Create: `Sources/Core/UploadedImage.swift`
- Test: `Tests/CoreTests/UploadedImageTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/UploadedImageTests.swift
import Testing
import Foundation
@testable import Core

@Suite("UploadedImage")
struct UploadedImageTests {
    @Test("Initializes with all fields")
    func initialization() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let image = UploadedImage(
            id: "abc123",
            link: URL(string: "https://i.imgur.com/abc123.png")!,
            deleteHash: "def456",
            uploadedAt: date,
            originalFilename: "screenshot.png"
        )
        #expect(image.id == "abc123")
        #expect(image.link.absoluteString == "https://i.imgur.com/abc123.png")
        #expect(image.deleteHash == "def456")
        #expect(image.uploadedAt == date)
        #expect(image.originalFilename == "screenshot.png")
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = UploadedImage(
            id: "xyz",
            link: URL(string: "https://i.imgur.com/xyz.png")!,
            deleteHash: "hash",
            uploadedAt: Date(timeIntervalSince1970: 1_700_000_000),
            originalFilename: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UploadedImage.self, from: data)
        #expect(decoded == original)
    }
}
```

**Step 2: Run — fails**

```bash
swift test --filter UploadedImage 2>&1 | tail -5
```

**Step 3: Implement**

```swift
// Sources/Core/UploadedImage.swift
import Foundation

public struct UploadedImage: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let link: URL
    public let deleteHash: String?
    public let uploadedAt: Date
    public let originalFilename: String?

    public init(
        id: String,
        link: URL,
        deleteHash: String?,
        uploadedAt: Date,
        originalFilename: String?
    ) {
        self.id = id
        self.link = link
        self.deleteHash = deleteHash
        self.uploadedAt = uploadedAt
        self.originalFilename = originalFilename
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/UploadedImage.swift Tests/CoreTests/UploadedImageTests.swift
git commit -m "[core] Add UploadedImage value type with Codable conformance"
git push
```

### Task 3.4: `Preferences.swift` — UserDefaults wrapper with frozen keys

**Files:**
- Create: `Sources/Core/Preferences.swift`
- Test: `Tests/CoreTests/PreferencesTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/PreferencesTests.swift
import Testing
import Foundation
@testable import Core

@Suite("Preferences")
struct PreferencesTests {
    /// CRITICAL: these key names are part of the public contract with the
    /// 2018 mac2imgur install on the user's Mac. Tier 3 SwiftUI views will
    /// use @AppStorage with these exact strings. Do not change without a
    /// migration plan.
    @Test("UserDefaults keys are the documented stable values")
    func keyStability() {
        #expect(PreferencesKey.refreshToken.rawValue == "RefreshToken")
        #expect(PreferencesKey.imgurAlbum.rawValue == "ImgurAlbum")
        #expect(PreferencesKey.deleteAfterUpload.rawValue == "DeleteAfterUpload")
        #expect(PreferencesKey.disableScreenshotDetection.rawValue == "DisableScreenshotDetection")
        #expect(PreferencesKey.requireConfirmation.rawValue == "RequireConfirmation")
        #expect(PreferencesKey.copyLinkToClipboard.rawValue == "CopyLinkToClipboard")
        #expect(PreferencesKey.clearClipboard.rawValue == "ClearClipboard")
    }

    @Test("Round-trips a string value through UserDefaults")
    func stringRoundTrip() {
        let suite = UserDefaults(suiteName: #function)!
        defer { suite.removePersistentDomain(forName: #function) }
        let prefs = Preferences(defaults: suite)
        prefs.imgurAlbumID = "myalbum"
        #expect(prefs.imgurAlbumID == "myalbum")
    }

    @Test("Round-trips a bool value")
    func boolRoundTrip() {
        let suite = UserDefaults(suiteName: #function)!
        defer { suite.removePersistentDomain(forName: #function) }
        let prefs = Preferences(defaults: suite)
        prefs.deleteAfterUpload = true
        #expect(prefs.deleteAfterUpload == true)
        prefs.deleteAfterUpload = false
        #expect(prefs.deleteAfterUpload == false)
    }
}
```

**Step 2: Run — fails**

**Step 3: Implement**

```swift
// Sources/Core/Preferences.swift
import Foundation
import Observation

public enum PreferencesKey: String {
    case refreshToken = "RefreshToken"
    case imgurAlbum = "ImgurAlbum"
    case deleteAfterUpload = "DeleteAfterUpload"
    case disableScreenshotDetection = "DisableScreenshotDetection"
    case requireConfirmation = "RequireConfirmation"
    case copyLinkToClipboard = "CopyLinkToClipboard"
    case clearClipboard = "ClearClipboard"
}

@Observable
public final class Preferences {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var refreshToken: String? {
        get { defaults.string(forKey: PreferencesKey.refreshToken.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.refreshToken.rawValue) }
    }

    public var imgurAlbumID: String? {
        get { defaults.string(forKey: PreferencesKey.imgurAlbum.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.imgurAlbum.rawValue) }
    }

    public var deleteAfterUpload: Bool {
        get { defaults.bool(forKey: PreferencesKey.deleteAfterUpload.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.deleteAfterUpload.rawValue) }
    }

    public var disableScreenshotDetection: Bool {
        get { defaults.bool(forKey: PreferencesKey.disableScreenshotDetection.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.disableScreenshotDetection.rawValue) }
    }

    public var requireConfirmation: Bool {
        get { defaults.bool(forKey: PreferencesKey.requireConfirmation.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.requireConfirmation.rawValue) }
    }

    public var copyLinkToClipboard: Bool {
        get { defaults.bool(forKey: PreferencesKey.copyLinkToClipboard.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.copyLinkToClipboard.rawValue) }
    }

    public var clearClipboard: Bool {
        get { defaults.bool(forKey: PreferencesKey.clearClipboard.rawValue) }
        set { defaults.set(newValue, forKey: PreferencesKey.clearClipboard.rawValue) }
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/Preferences.swift Tests/CoreTests/PreferencesTests.swift
git commit -m "[core] Add Preferences with frozen UserDefaults keys"
git push
```

### Task 3.5: `ImgurClient.swift` — anonymous upload happy path

**Files:**
- Modify: `Sources/Core/ImgurClient.swift`
- Test: `Tests/CoreTests/ImgurClientTests.swift`

**Step 1: Write failing test using mocked URLProtocol**

```swift
// Tests/CoreTests/ImgurClientTests.swift
import Testing
import Foundation
@testable import Core

@Suite("ImgurClient")
struct ImgurClientTests {
    @Test("Anonymous upload returns parsed UploadedImage on 200")
    func anonymousUploadHappyPath() async throws {
        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header bytes
        let responseJSON = """
        {
          "data": {
            "id": "abc123",
            "deletehash": "del456",
            "link": "https://i.imgur.com/abc123.png"
          },
          "success": true,
          "status": 200
        }
        """.data(using: .utf8)!

        let session = MockURLSession(
            responseData: responseJSON,
            statusCode: 200
        )
        let client = ImgurClient(urlSession: session)
        let result = try await client.uploadAnonymous(
            data: imageData,
            filename: "test.png"
        )
        #expect(result.id == "abc123")
        #expect(result.link.absoluteString == "https://i.imgur.com/abc123.png")
        #expect(result.deleteHash == "del456")
    }
}

// Test helper — minimal URLSession-like protocol
final class MockURLSession: ImgurURLSession {
    let responseData: Data
    let statusCode: Int
    init(responseData: Data, statusCode: Int) {
        self.responseData = responseData
        self.statusCode = statusCode
    }
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (responseData, response)
    }
}
```

**Step 2: Run — fails**

```bash
swift test --filter ImgurClient 2>&1 | tail -10
```

**Step 3: Implement**

```swift
// Sources/Core/ImgurClient.swift
import Foundation

public protocol ImgurURLSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: ImgurURLSession {}

public enum ImgurError: Error, Equatable {
    case invalidResponse
    case http(statusCode: Int, message: String?)
    case rateLimited
    case decoding(String)
}

public struct ImgurClient: Sendable {
    private let urlSession: ImgurURLSession
    private let baseURL: URL

    public init(
        urlSession: ImgurURLSession = URLSession.shared,
        baseURL: URL = URL(string: "https://api.imgur.com/3/")!
    ) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    public func uploadAnonymous(data imageData: Data, filename: String) async throws -> UploadedImage {
        var request = URLRequest(url: baseURL.appendingPathComponent("image"))
        request.httpMethod = "POST"
        request.setValue("Client-ID \(Secrets.imgurClientID)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(boundary: boundary, imageData: imageData, filename: filename)

        let (data, response) = try await urlSession.data(for: request)
        return try parseUploadResponse(data: data, response: response)
    }

    private func makeMultipartBody(boundary: String, imageData: Data, filename: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func parseUploadResponse(data: Data, response: URLResponse) throws -> UploadedImage {
        guard let http = response as? HTTPURLResponse else {
            throw ImgurError.invalidResponse
        }
        if http.statusCode == 429 {
            throw ImgurError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw ImgurError.http(statusCode: http.statusCode, message: message)
        }
        struct Envelope: Decodable {
            let data: Payload
            struct Payload: Decodable {
                let id: String
                let link: String
                let deletehash: String?
            }
        }
        do {
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            guard let url = URL(string: envelope.data.link) else {
                throw ImgurError.decoding("Invalid link URL: \(envelope.data.link)")
            }
            return UploadedImage(
                id: envelope.data.id,
                link: url,
                deleteHash: envelope.data.deletehash,
                uploadedAt: Date(),
                originalFilename: nil
            )
        } catch let error as ImgurError {
            throw error
        } catch {
            throw ImgurError.decoding(error.localizedDescription)
        }
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/ImgurClient.swift Tests/CoreTests/ImgurClientTests.swift
git commit -m "[core] Implement ImgurClient anonymous upload happy path"
git push
```

### Task 3.6: `ImgurClient` — error path tests (4xx, 5xx, rate-limit)

**Step 1: Add tests**

Append to `Tests/CoreTests/ImgurClientTests.swift`:

```swift
extension ImgurClientTests {
    @Test("4xx response throws .http with status code and body")
    func http4xxError() async {
        let body = #"{"data":{"error":"Bad request"},"success":false,"status":400}"#.data(using: .utf8)!
        let session = MockURLSession(responseData: body, statusCode: 400)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch let ImgurError.http(statusCode, _) {
            #expect(statusCode == 400)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("429 maps to .rateLimited")
    func rateLimited() async {
        let session = MockURLSession(responseData: Data(), statusCode: 429)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch ImgurError.rateLimited {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("5xx response throws .http")
    func http5xx() async {
        let session = MockURLSession(responseData: Data(), statusCode: 503)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch let ImgurError.http(statusCode, _) {
            #expect(statusCode == 503)
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("Malformed JSON throws .decoding")
    func malformedJSON() async {
        let session = MockURLSession(responseData: Data("garbage".utf8), statusCode: 200)
        let client = ImgurClient(urlSession: session)
        do {
            _ = try await client.uploadAnonymous(data: Data(), filename: "x.png")
            Issue.record("Expected throw")
        } catch ImgurError.decoding {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }
}
```

**Step 2: Run — verify all 4 new tests pass (implementation already supports them)**

```bash
swift test --filter ImgurClient 2>&1 | tail -10
```

**Step 3: Commit**

```bash
git add Tests/CoreTests/ImgurClientTests.swift
git commit -m "[core] Add ImgurClient error path tests (4xx, 5xx, 429, decoding)"
git push
```

### Task 3.7: `ImgurClient` — multipart body encoding test

**Step 1: Add test verifying the multipart body byte-for-byte**

```swift
// Append to ImgurClientTests
extension ImgurClientTests {
    @Test("Multipart body contains image bytes and correct headers")
    func multipartBodyEncoding() async throws {
        // Capture the request that the client would send
        let captureSession = CapturingURLSession(
            responseData: """
                {"data":{"id":"x","link":"https://i.imgur.com/x.png","deletehash":"d"},"success":true,"status":200}
            """.data(using: .utf8)!
        )
        let client = ImgurClient(urlSession: captureSession)
        let imageBytes = Data([0xAB, 0xCD, 0xEF])
        _ = try await client.uploadAnonymous(data: imageBytes, filename: "thing.png")

        let body = captureSession.captured!.httpBody!
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        #expect(bodyString.contains("Content-Disposition: form-data; name=\"image\"; filename=\"thing.png\""))
        #expect(body.range(of: imageBytes) != nil)
    }
}

final class CapturingURLSession: ImgurURLSession {
    let responseData: Data
    var captured: URLRequest?
    init(responseData: Data) { self.responseData = responseData }
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        captured = request
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}
```

**Step 2: Run — passes**

**Step 3: Commit**

```bash
git add Tests/CoreTests/ImgurClientTests.swift
git commit -m "[core] Add ImgurClient multipart encoding test"
git push
```

### Task 3.8: `OAuthCoordinator.swift` — token storage and refresh logic (no UI yet)

**Files:**
- Create: `Sources/Core/OAuthCoordinator.swift`
- Test: `Tests/CoreTests/OAuthCoordinatorTests.swift`

This task focuses on the *logic* of token refresh — the `ASWebAuthenticationSession` UI hand-off is wired in Phase 4. We test the pure pieces here.

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/OAuthCoordinatorTests.swift
import Testing
import Foundation
@testable import Core

@Suite("OAuthCoordinator")
struct OAuthCoordinatorTests {
    @Test("Refresh succeeds with new token on 200")
    func refreshHappyPath() async throws {
        let response = """
            {"access_token":"new_access","refresh_token":"new_refresh","token_type":"bearer","expires_in":3600,"account_id":42,"account_username":"craig"}
        """.data(using: .utf8)!
        let session = MockURLSession(responseData: response, statusCode: 200)
        let coord = OAuthCoordinator(urlSession: session)
        let tokens = try await coord.refresh(refreshToken: "old_refresh")
        #expect(tokens.accessToken == "new_access")
        #expect(tokens.refreshToken == "new_refresh")
        #expect(tokens.accountUsername == "craig")
    }

    @Test("Refresh on 401 throws .refreshExpired")
    func refreshExpired() async {
        let session = MockURLSession(responseData: Data(), statusCode: 401)
        let coord = OAuthCoordinator(urlSession: session)
        do {
            _ = try await coord.refresh(refreshToken: "stale")
            Issue.record("Expected throw")
        } catch OAuthError.refreshExpired {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }

    @Test("Refresh with malformed JSON throws .decoding")
    func malformedRefresh() async {
        let session = MockURLSession(responseData: Data("garbage".utf8), statusCode: 200)
        let coord = OAuthCoordinator(urlSession: session)
        do {
            _ = try await coord.refresh(refreshToken: "x")
            Issue.record("Expected throw")
        } catch OAuthError.decoding {
            // pass
        } catch {
            Issue.record("Wrong error: \(error)")
        }
    }
}
```

**Step 2: Run — fails**

**Step 3: Implement**

```swift
// Sources/Core/OAuthCoordinator.swift
import Foundation

public struct OAuthTokens: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let accountUsername: String?

    public init(accessToken: String, refreshToken: String, accountUsername: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountUsername = accountUsername
    }
}

public enum OAuthError: Error, Equatable {
    case refreshExpired
    case http(Int)
    case decoding(String)
    case invalidResponse
}

public struct OAuthCoordinator: Sendable {
    private let urlSession: ImgurURLSession
    private let tokenURL: URL

    public init(
        urlSession: ImgurURLSession = URLSession.shared,
        tokenURL: URL = URL(string: "https://api.imgur.com/oauth2/token")!
    ) {
        self.urlSession = urlSession
        self.tokenURL = tokenURL
    }

    public func refresh(refreshToken: String) async throws -> OAuthTokens {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = [
            "refresh_token=\(refreshToken)",
            "client_id=\(Secrets.imgurClientID)",
            "client_secret=\(Secrets.imgurClientSecret)",
            "grant_type=refresh_token"
        ].joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw OAuthError.refreshExpired
        }
        guard (200..<300).contains(http.statusCode) else {
            throw OAuthError.http(http.statusCode)
        }
        struct ResponsePayload: Decodable {
            let access_token: String
            let refresh_token: String
            let account_username: String?
        }
        do {
            let payload = try JSONDecoder().decode(ResponsePayload.self, from: data)
            return OAuthTokens(
                accessToken: payload.access_token,
                refreshToken: payload.refresh_token,
                accountUsername: payload.account_username
            )
        } catch {
            throw OAuthError.decoding(error.localizedDescription)
        }
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/OAuthCoordinator.swift Tests/CoreTests/OAuthCoordinatorTests.swift
git commit -m "[core] Add OAuthCoordinator with refresh flow and error mapping"
git push
```

### Task 3.9: `UploadHistory.swift` — `@Observable` history with persistence

**Files:**
- Create: `Sources/Core/UploadHistory.swift`
- Test: `Tests/CoreTests/UploadHistoryTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/UploadHistoryTests.swift
import Testing
import Foundation
@testable import Core

@Suite("UploadHistory")
struct UploadHistoryTests {
    private func suite() -> UserDefaults {
        let s = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return s
    }

    @Test("Newly created history is empty")
    func startsEmpty() {
        let history = UploadHistory(defaults: suite(), maxCount: 5)
        #expect(history.uploads.isEmpty)
    }

    @Test("Add appends to the front")
    func addAppendsToFront() {
        let history = UploadHistory(defaults: suite(), maxCount: 5)
        let img = UploadedImage(id: "a", link: URL(string: "https://i.imgur.com/a.png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil)
        history.add(img)
        #expect(history.uploads.first?.id == "a")
    }

    @Test("Eviction caps the list at maxCount")
    func eviction() {
        let history = UploadHistory(defaults: suite(), maxCount: 3)
        for i in 0..<5 {
            history.add(UploadedImage(id: "\(i)", link: URL(string: "https://i.imgur.com/\(i).png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil))
        }
        #expect(history.uploads.count == 3)
        #expect(history.uploads.map(\.id) == ["4", "3", "2"])
    }

    @Test("Persistence round-trips across instances")
    func persistence() {
        let s = suite()
        let h1 = UploadHistory(defaults: s, maxCount: 5)
        h1.add(UploadedImage(id: "z", link: URL(string: "https://i.imgur.com/z.png")!, deleteHash: nil, uploadedAt: Date(), originalFilename: nil))
        let h2 = UploadHistory(defaults: s, maxCount: 5)
        #expect(h2.uploads.first?.id == "z")
    }
}
```

**Step 2: Run — fails**

**Step 3: Implement**

```swift
// Sources/Core/UploadHistory.swift
import Foundation
import Observation

@Observable
public final class UploadHistory {
    private let defaults: UserDefaults
    private let key = "UploadHistoryV2"
    private let maxCount: Int

    public private(set) var uploads: [UploadedImage] = []

    public init(defaults: UserDefaults = .standard, maxCount: Int = 50) {
        self.defaults = defaults
        self.maxCount = maxCount
        self.uploads = load()
    }

    public func add(_ image: UploadedImage) {
        var next = uploads
        next.insert(image, at: 0)
        if next.count > maxCount {
            next = Array(next.prefix(maxCount))
        }
        uploads = next
        persist()
    }

    public func clear() {
        uploads = []
        persist()
    }

    private func load() -> [UploadedImage] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([UploadedImage].self, from: data)) ?? []
    }

    private func persist() {
        let data = try? JSONEncoder().encode(uploads)
        defaults.set(data, forKey: key)
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/UploadHistory.swift Tests/CoreTests/UploadHistoryTests.swift
git commit -m "[core] Add UploadHistory with @Observable, eviction, persistence"
git push
```

### Task 3.10: `ScreenshotMonitor.swift` — `NSMetadataQuery`-based detection

**Files:**
- Create: `Sources/Core/ScreenshotMonitor.swift`
- Test: `Tests/CoreTests/ScreenshotMonitorTests.swift`

`NSMetadataQuery` results aren't trivial to mock without integration tests, so we test the *predicate* and the *file filter* logic in isolation.

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/ScreenshotMonitorTests.swift
import Testing
import Foundation
@testable import Core

@Suite("ScreenshotMonitor")
struct ScreenshotMonitorTests {
    @Test("Spotlight predicate matches kMDItemIsScreenCapture true")
    func predicateString() {
        let predicate = ScreenshotMonitor.spotlightPredicate
        #expect(predicate.predicateFormat.contains("kMDItemIsScreenCapture"))
    }

    @Test("isAcceptableScreenshot returns true for png/jpg")
    func acceptsImageExtensions() {
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "Screenshot.png"))
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "shot.jpg"))
        #expect(ScreenshotMonitor.isAcceptableScreenshot(filename: "shot.JPEG"))
    }

    @Test("isAcceptableScreenshot rejects non-images")
    func rejectsNonImages() {
        #expect(!ScreenshotMonitor.isAcceptableScreenshot(filename: "doc.pdf"))
        #expect(!ScreenshotMonitor.isAcceptableScreenshot(filename: "movie.mov"))
    }
}
```

**Step 2: Run — fails**

**Step 3: Implement**

```swift
// Sources/Core/ScreenshotMonitor.swift
import Foundation

public final class ScreenshotMonitor {
    public typealias Handler = (URL) -> Void

    public static let spotlightPredicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")

    public static let acceptableExtensions: Set<String> = ["png", "jpg", "jpeg"]

    public static func isAcceptableScreenshot(filename: String) -> Bool {
        let ext = (filename as NSString).pathExtension.lowercased()
        return acceptableExtensions.contains(ext)
    }

    private let query: NSMetadataQuery
    private let handler: Handler
    private var notifiedURLs = Set<URL>()

    public init(handler: @escaping Handler) {
        self.handler = handler
        self.query = NSMetadataQuery()
        self.query.predicate = Self.spotlightPredicate
        self.query.searchScopes = [NSMetadataQueryUserHomeScope]
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
    }

    public func start() {
        query.start()
    }

    public func stop() {
        query.stop()
    }

    @objc private func handleUpdate(_ note: Notification) {
        let added = (note.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]) ?? []
        for item in added {
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { continue }
            let url = URL(fileURLWithPath: path)
            guard !notifiedURLs.contains(url) else { continue }
            guard Self.isAcceptableScreenshot(filename: url.lastPathComponent) else { continue }
            notifiedURLs.insert(url)
            handler(url)
        }
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/ScreenshotMonitor.swift Tests/CoreTests/ScreenshotMonitorTests.swift
git commit -m "[core] Add ScreenshotMonitor using NSMetadataQuery"
git push
```

### Task 3.11: `Notifications.swift` — UNUserNotificationCenter wrapper

**Files:**
- Create: `Sources/Core/Notifications.swift`
- Test: `Tests/CoreTests/NotificationsTests.swift`

**Step 1: Write failing tests**

```swift
// Tests/CoreTests/NotificationsTests.swift
import Testing
import Foundation
@testable import Core

@Suite("Notifications")
struct NotificationsTests {
    @Test("Builds upload-success notification content")
    func uploadSuccessContent() {
        let content = Notifications.uploadSuccessContent(link: URL(string: "https://i.imgur.com/abc.png")!)
        #expect(content.title == "Image Uploaded")
        #expect(content.body.contains("https://i.imgur.com/abc.png"))
    }

    @Test("Builds upload-failure notification content")
    func uploadFailureContent() {
        let content = Notifications.uploadFailureContent(reason: "Rate limited")
        #expect(content.title == "Upload Failed")
        #expect(content.body.contains("Rate limited"))
    }
}
```

**Step 2: Run — fails**

**Step 3: Implement**

```swift
// Sources/Core/Notifications.swift
import Foundation
import UserNotifications

public enum Notifications {
    public struct Content: Equatable, Sendable {
        public let title: String
        public let body: String
    }

    public static func uploadSuccessContent(link: URL) -> Content {
        Content(title: "Image Uploaded", body: link.absoluteString)
    }

    public static func uploadFailureContent(reason: String) -> Content {
        Content(title: "Upload Failed", body: reason)
    }

    public static func deliver(_ content: Content) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: makeUNContent(from: content),
            trigger: nil
        )
        try? await center.add(request)
    }

    private static func makeUNContent(from content: Content) -> UNNotificationContent {
        let un = UNMutableNotificationContent()
        un.title = content.title
        un.body = content.body
        un.sound = .default
        return un
    }
}
```

**Step 4: Run — passes**

**Step 5: Commit**

```bash
git add Sources/Core/Notifications.swift Tests/CoreTests/NotificationsTests.swift
git commit -m "[core] Add Notifications wrapper for UNUserNotificationCenter"
git push
```

### Task 3.12: Run full Core test suite — gate

**Step 1: Run all Core tests**

```bash
cd ~/mac2imgur
swift test 2>&1 | tail -20
```

**Expected:** all tests pass. If any fail, stop and fix before moving on.

**No commit** — verification gate only.

---

# Phase 4 — Modernize the Shell (AppKit + Core wiring)

Goal: Wire the AppKit shell to Core. Replace `EMCLoginItem` with `SMAppService`. Replace OAuth web view with `ASWebAuthenticationSession`. Connect status bar menus to `UploadHistory` and `ImgurClient`.

### Task 4.1: Update `App/AppDelegate.swift` — initialize Core, wire menus

Modify the existing AppDelegate to:
- Hold an `ImgurClient`, `OAuthCoordinator`, `UploadHistory`, `Preferences`, `ScreenshotMonitor` as properties
- Start the screenshot monitor on launch
- Pass them down to menu controllers via the controller initializers

Detailed code is too long for inline — refer to the design doc's architecture section. The AppDelegate becomes a thin DI container.

**Verification:** project builds in Xcode (`⌘B`).

**Commit:** `[shell] Wire AppDelegate to Core types via dependency injection`

### Task 4.2: Replace `EMCLoginItem` with `SMAppService`

**Files:**
- Create: `App/Services/LoginItemService.swift`

```swift
// App/Services/LoginItemService.swift
import ServiceManagement

enum LoginItemService {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
```

**Step 1: Add the file to the App target in Xcode**

**Step 2: Update any old EMCLoginItem call sites to use `LoginItemService`**

**Step 3: Build & smoke**

```bash
xcodebuild -project mac2imgur.xcodeproj -scheme mac2imgur build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

**Step 4: Commit**

```bash
git add App/Services/LoginItemService.swift App/
git commit -m "[shell] Replace EMCLoginItem with SMAppService"
git push
```

### Task 4.3: Replace OAuth flow with `ASWebAuthenticationSession`

**Files:**
- Create: `App/Auth/ImgurOAuthFlow.swift`

```swift
// App/Auth/ImgurOAuthFlow.swift
import AppKit
import AuthenticationServices
import Core

@MainActor
final class ImgurOAuthFlow: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let coordinator: OAuthCoordinator

    init(coordinator: OAuthCoordinator) {
        self.coordinator = coordinator
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.windows.first ?? NSWindow()
    }

    /// Launches the Imgur authorization page and returns tokens on success.
    func login() async throws -> OAuthTokens {
        let authURL = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=\(Secrets.imgurClientID)&response_type=token")!
        let callbackScheme = "mac2imgur"
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: error ?? OAuthError.invalidResponse) }
            }
            session.presentationContextProvider = self
            session.start()
        }
        // Imgur returns tokens in URL fragment — parse them
        return try parseTokens(from: callbackURL)
    }

    private func parseTokens(from url: URL) throws -> OAuthTokens {
        guard let fragment = url.fragment else { throw OAuthError.invalidResponse }
        let pairs = fragment.split(separator: "&")
            .map { $0.split(separator: "=", maxSplits: 1).map(String.init) }
        var dict: [String: String] = [:]
        for p in pairs where p.count == 2 { dict[p[0]] = p[1] }
        guard let access = dict["access_token"], let refresh = dict["refresh_token"] else {
            throw OAuthError.invalidResponse
        }
        return OAuthTokens(accessToken: access, refreshToken: refresh, accountUsername: dict["account_username"])
    }
}
```

**Note:** `Info.plist` must declare `mac2imgur` as a `CFBundleURLSchemes` entry. Add that in Xcode → target → Info → URL Types if not already present.

**Commit:** `[shell] Add ImgurOAuthFlow using ASWebAuthenticationSession`

### Task 4.4: Wire screenshot detection → upload → notification

In `App/AppDelegate.swift`:

```swift
@MainActor
private func handleNewScreenshot(at url: URL) {
    guard !preferences.disableScreenshotDetection else { return }
    Task {
        do {
            let data = try Data(contentsOf: url)
            let result = try await imgurClient.uploadAnonymous(
                data: data,
                filename: url.lastPathComponent
            )
            uploadHistory.add(result)
            await Notifications.deliver(Notifications.uploadSuccessContent(link: result.link))
            if preferences.copyLinkToClipboard {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.link.absoluteString, forType: .string)
            }
            if preferences.deleteAfterUpload {
                try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
        } catch {
            await Notifications.deliver(Notifications.uploadFailureContent(reason: "\(error)"))
        }
    }
}
```

**Verify:** smoke test by hand — take a screenshot, observe upload happens.

**Commit:** `[shell] Wire screenshot detection to upload + notification + clipboard`

### Task 4.5: Modernize menu controllers

For each of `StatusItemController`, `MenuController`, `ImgurMenuController`, `ImgurAlbumMenuController`, `UploadsMenuController`:

- Replace any `IMGSession` references with the new `ImgurClient` / `OAuthCoordinator`
- Replace completion-handler callbacks with `Task { await ... }` blocks
- Read state from injected Core types

After each file: build + commit. One file = one commit.

**Commits:**
- `[shell] Modernize StatusItemController for new Core API`
- `[shell] Modernize ImgurMenuController for new Core API`
- … etc

### Task 4.6: Remove old PreferencesMenuController + AboutMenuController references

The Settings scene (Phase 5) replaces these. Update `MenuController.swift` to open Settings via `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)`.

**Commit:** `[shell] Replace Preferences/About menu items with SwiftUI Settings`

---

# Phase 5 — SwiftUI Settings Scene

Goal: Build the Settings UI in SwiftUI from day one. This is the Tier-3 entry point.

### Task 5.1: Create `App/Settings/SettingsView.swift` — root scene

```swift
// App/Settings/SettingsView.swift
import SwiftUI
import Core

struct SettingsView: View {
    @Environment(Preferences.self) private var preferences

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            ScreenshotsSettingsView()
                .tabItem { Label("Screenshots", systemImage: "camera") }
            AccountSettingsView()
                .tabItem { Label("Account", systemImage: "person.circle") }
            UpdatesSettingsView()
                .tabItem { Label("Updates", systemImage: "arrow.down.circle") }
        }
        .frame(width: 460, height: 320)
    }
}
```

**Commit:** `[settings] Add SwiftUI SettingsView root with tabs`

### Task 5.2: `GeneralSettingsView.swift` — launch at login, copy link, clear clipboard

```swift
// App/Settings/GeneralSettingsView.swift
import SwiftUI
import Core

struct GeneralSettingsView: View {
    @Environment(Preferences.self) private var preferences
    @State private var launchAtLogin = LoginItemService.isEnabled

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    try? LoginItemService.setEnabled(newValue)
                }
            Toggle("Copy Link to Clipboard", isOn: $preferences.copyLinkToClipboard)
            Toggle("Clear Clipboard Before Upload", isOn: $preferences.clearClipboard)
        }
        .padding()
    }
}
```

**Commit:** `[settings] Add GeneralSettingsView`

### Task 5.3: `ScreenshotsSettingsView.swift`

Toggles for `deleteAfterUpload`, `disableScreenshotDetection`, `requireConfirmation`. Pattern matches Task 5.2.

**Commit:** `[settings] Add ScreenshotsSettingsView`

### Task 5.4: `AccountSettingsView.swift` — login, logout, album picker

```swift
// App/Settings/AccountSettingsView.swift
import SwiftUI
import Core

struct AccountSettingsView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(OAuthFlowProvider.self) private var oauthFlow
    @State private var status: String = ""

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            if preferences.refreshToken == nil {
                Button("Sign in to Imgur") {
                    Task { await login() }
                }
            } else {
                Text("Signed in").foregroundStyle(.secondary)
                Button("Sign Out") {
                    preferences.refreshToken = nil
                    preferences.imgurAlbumID = nil
                }
                TextField("Album ID (optional)", text: Binding(
                    get: { preferences.imgurAlbumID ?? "" },
                    set: { preferences.imgurAlbumID = $0.isEmpty ? nil : $0 }
                ))
            }
            if !status.isEmpty {
                Text(status).foregroundStyle(.red)
            }
        }
        .padding()
    }

    private func login() async {
        do {
            let tokens = try await oauthFlow.login()
            preferences.refreshToken = tokens.refreshToken
        } catch {
            status = "\(error)"
        }
    }
}
```

`OAuthFlowProvider` is a small `@Observable` wrapper holding the `ImgurOAuthFlow` instance for environment injection. Define it in `App/Auth/`.

**Commit:** `[settings] Add AccountSettingsView with OAuth login`

### Task 5.5: `UpdatesSettingsView.swift` — Sparkle prefs

```swift
// App/Settings/UpdatesSettingsView.swift
import SwiftUI
import Sparkle

struct UpdatesSettingsView: View {
    @AppStorage("SUEnableAutomaticChecks") private var autoCheck = true
    let updater: SPUUpdater

    var body: some View {
        Form {
            Toggle("Automatically Check for Updates", isOn: $autoCheck)
            Button("Check Now") { updater.checkForUpdates() }
        }
        .padding()
    }
}
```

**Commit:** `[settings] Add UpdatesSettingsView wired to Sparkle`

### Task 5.6: Wire `Settings { }` scene in `mac2imgurApp` or AppDelegate

Since this is an AppKit-shell app with a SwiftUI Settings scene, the simplest path is to use `NSApp.setActivationPolicy(.accessory)` plus a small `App` declaration:

```swift
// App/mac2imgurApp.swift
import SwiftUI
import Core

@main
struct mac2imgurApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.preferences)
                .environment(appDelegate.oauthFlow)
        }
    }
}
```

Remove `@NSApplicationMain` from `AppDelegate.swift`.

**Commit:** `[settings] Migrate to @main App with Settings scene`

---

# Phase 6 — Sparkle 2 Integration

Goal: Generate EdDSA keypair, embed public key, configure Sparkle, create initial appcast.

### Task 6.1: Generate EdDSA keypair

**Step 1: Use Sparkle's `generate_keys` tool**

After adding Sparkle via SPM (Task 2.4), the `generate_keys` binary should be in the Sparkle package's bin. Find it:

```bash
find ~/Library/Developer/Xcode/DerivedData -name generate_keys -type f 2>/dev/null | head -1
```

Or build from source if needed:

```bash
git clone https://github.com/sparkle-project/Sparkle.git /tmp/sparkle && cd /tmp/sparkle && make
ls bin/
```

**Step 2: Generate keys**

```bash
~/path/to/generate_keys
```

It outputs the public key to stdout and stores the private key in macOS Keychain.

**Step 3: Save the public key**

```bash
echo "PASTE_PUBLIC_KEY_HERE" > /tmp/sparkle_public_key.txt
```

**No commit yet** — keys are not committed.

### Task 6.2: Embed public key in `Info.plist`

In Xcode: open `App/Resources/Info.plist`, add a key `SUPublicEDKey` (String) with the public key value.

Also add:
- `SUFeedURL` (String) = `https://raw.githubusercontent.com/CraigVG/mac2imgur/main/appcast.xml`
- `SUEnableInstallerLauncherService` (Boolean) = YES (Sparkle 2 requirement for sandboxed updates)

**Commit:** `[sparkle] Add SUPublicEDKey, SUFeedURL, installer launcher`

### Task 6.3: Initialize Sparkle in AppDelegate

```swift
// In AppDelegate
import Sparkle

private lazy var updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
)
```

Expose `updaterController.updater` to `UpdatesSettingsView` via the environment.

**Commit:** `[sparkle] Initialize SPUStandardUpdaterController`

### Task 6.4: Create initial empty `appcast.xml`

```bash
cd ~/mac2imgur
cat > appcast.xml << 'EOF'
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
  <channel>
    <title>mac2imgur</title>
    <link>https://raw.githubusercontent.com/CraigVG/mac2imgur/main/appcast.xml</link>
    <description>Most recent updates to mac2imgur</description>
    <language>en</language>
    <!-- Items are added by the release workflow -->
  </channel>
</rss>
EOF

git add appcast.xml
git commit -m "[sparkle] Add initial empty appcast.xml"
git push
```

### Task 6.5: Add private key to GitHub Actions secret

**Step 1: In Keychain Access, find the Sparkle private key entry**

```bash
security find-generic-password -s "https://sparkle-project.org" -w
```

Copy the output.

**Step 2: Set it as a GitHub Actions secret**

```bash
echo "PASTE_PRIVATE_KEY" | gh secret set SPARKLE_PRIVATE_KEY --repo CraigVG/mac2imgur
```

**No commit** (secrets are out-of-band).

---

# Phase 7 — Release Infrastructure

Goal: Wire CI/CD with two workflows — build-on-push and release-on-tag.

### Task 7.1: Create `.github/workflows/build.yml`

```bash
mkdir -p .github/workflows
cat > .github/workflows/build.yml << 'EOF'
name: Build & Test

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app
      - name: Build
        run: xcodebuild -project mac2imgur.xcodeproj -scheme mac2imgur -configuration Debug build
      - name: Test Core
        run: swift test
EOF
```

**Commit:** `[ci] Add build & test workflow`

### Task 7.2: Configure remaining GitHub Actions secrets for release

Required secrets (all `gh secret set`):
- `MACOS_CERT` — base64-encoded `.p12` Developer ID Application cert
- `MACOS_CERT_PASSWORD` — `.p12` password
- `APPLE_ID` — Apple ID email
- `APPLE_APP_PASSWORD` — app-specific password from appleid.apple.com
- `APPLE_TEAM_ID` — Developer Team ID

For each:

```bash
gh secret set <NAME> --repo CraigVG/mac2imgur
# Paste value when prompted
```

For `MACOS_CERT`, first export from Keychain Access as `.p12`, then:

```bash
base64 -i cert.p12 | gh secret set MACOS_CERT --repo CraigVG/mac2imgur
```

**No commit** — secrets are out-of-band.

### Task 7.3: Create `.github/workflows/release.yml`

This is the longest workflow file in the project. Structure:

```yaml
name: Release

on:
  push:
    tags: ["v*"]

jobs:
  release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Test gate
        run: swift test

      - name: Import signing certificate
        env:
          CERT_BASE64: ${{ secrets.MACOS_CERT }}
          CERT_PASSWORD: ${{ secrets.MACOS_CERT_PASSWORD }}
        run: |
          echo "$CERT_BASE64" | base64 --decode > /tmp/cert.p12
          security create-keychain -p actions build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p actions build.keychain
          security import /tmp/cert.p12 -k build.keychain -P "$CERT_PASSWORD" -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions build.keychain

      - name: Archive
        run: |
          xcodebuild -project mac2imgur.xcodeproj \
            -scheme mac2imgur \
            -configuration Release \
            -archivePath build/mac2imgur.xcarchive \
            archive \
            DEVELOPMENT_TEAM=${{ secrets.APPLE_TEAM_ID }} \
            CODE_SIGN_IDENTITY="Developer ID Application"

      - name: Export
        run: |
          mkdir -p build/export
          cat > build/exportOptions.plist << 'PLIST'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>method</key>
            <string>developer-id</string>
            <key>teamID</key>
            <string>${{ secrets.APPLE_TEAM_ID }}</string>
          </dict>
          </plist>
          PLIST
          xcodebuild -exportArchive \
            -archivePath build/mac2imgur.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist build/exportOptions.plist

      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          cd build/export
          ditto -c -k --keepParent mac2imgur.app mac2imgur.zip
          xcrun notarytool submit mac2imgur.zip \
            --apple-id "$APPLE_ID" \
            --password "$APPLE_APP_PASSWORD" \
            --team-id "$APPLE_TEAM_ID" \
            --wait
          xcrun stapler staple mac2imgur.app
          rm mac2imgur.zip
          ditto -c -k --keepParent mac2imgur.app mac2imgur.zip

      - name: Sign appcast entry
        env:
          SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
        run: |
          # Use Sparkle's sign_update tool
          # (build the binary or download from Sparkle release artifacts)
          echo "$SPARKLE_PRIVATE_KEY" > /tmp/sparkle_priv
          # ... invoke sign_update on build/export/mac2imgur.zip
          # Capture signature into env var SPARKLE_SIGNATURE

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "${{ github.ref_name }}" \
            build/export/mac2imgur.zip \
            --title "${{ github.ref_name }}" \
            --notes "See CHANGELOG.md"

      - name: Update appcast.xml
        run: |
          # Insert <item> for this version with signature, length, URL
          # ... script that edits appcast.xml in place
          git config user.email "actions@github.com"
          git config user.name "GitHub Actions"
          git add appcast.xml
          git commit -m "[ci] Update appcast for ${{ github.ref_name }}"
          git push origin HEAD:main
```

(The `Sign appcast entry` and `Update appcast.xml` steps need a small companion script; create `scripts/update_appcast.sh` in a follow-up commit.)

**Commit:** `[ci] Add release workflow with sign + notarize + Sparkle`

### Task 7.4: Add `scripts/update_appcast.sh`

A shell script that takes (version, build, zip path, signature) and inserts an `<item>` into `appcast.xml`. Detail TBD during implementation; needs to handle XML insertion safely.

**Commit:** `[ci] Add appcast.xml update script`

### Task 7.5: Create `docs/release-smoke-test.md`

Copy the smoke test checklist from the design doc into a standalone file.

**Commit:** `[docs] Add release smoke test checklist`

---

# Phase 8 — License Headers & Final Attribution

Goal: Add modification copyright lines to every file we modified, ensure GPL-3.0 headers on new files.

### Task 8.1: Add modification line to all modified original files

For each Swift file in `Sources/Core/` and `App/` that was originally from upstream, add a single line below the existing GPL header:

```swift
// Modifications © 2026 Craig Vandergalien
```

A find/edit script:

```bash
cd ~/mac2imgur
for f in $(git log --diff-filter=M --name-only --pretty=format: master | sort -u | grep -E "\.swift$"); do
  if [[ -f "$f" ]] && ! grep -q "Modifications © 2026 Craig Vandergalien" "$f"; then
    # Insert after the existing GPL header (assume header ends with " */")
    awk '/\*\// && !done {print; print "// Modifications © 2026 Craig Vandergalien"; done=1; next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done
```

Verify a sample file shows the new line. Commit.

**Commit:** `[license] Add modification copyright line to modified files`

### Task 8.2: Verify new files have GPL-3.0 headers

```bash
cd ~/mac2imgur
for f in Sources/Core/Secrets.swift Sources/Core/Notifications.swift App/Settings/*.swift App/Auth/*.swift App/Services/*.swift; do
  if ! grep -q "GNU General Public License" "$f"; then
    echo "Missing GPL header: $f"
  fi
done
```

For each file printed, prepend the GPL header block. Commit when done.

**Commit:** `[license] Add GPL-3.0 headers to new files`

---

# Phase 9 — First Release: v2.0.0

Goal: Run the smoke test, tag v2.0.0, watch the release workflow ship a notarized build, verify install on a fresh Mac.

### Task 9.1: Local build + smoke test

**Step 1: Clean build**

```bash
cd ~/mac2imgur
xcodebuild -project mac2imgur.xcodeproj -scheme mac2imgur -configuration Release clean build
```

**Step 2: Run the resulting `.app` from DerivedData**

Find the `.app` and double-click. Walk through `docs/release-smoke-test.md` end-to-end.

**Step 3: Fix anything broken** — file issues, fix, re-run.

**No commit unless fixes are made.**

### Task 9.2: Bump version numbers

In `App/Resources/Info.plist`:
- `CFBundleShortVersionString` → `2.0.0`
- `CFBundleVersion` → `300`

```bash
git add App/Resources/Info.plist
git commit -m "[release] Bump version to 2.0.0 (build 300)"
git push
```

### Task 9.3: Tag v2.0.0 and push

```bash
git tag -a v2.0.0 -m "v2.0.0 — Modernized fork, Apple Silicon native"
git push origin v2.0.0
```

This triggers `release.yml`. Watch in:

```bash
gh run watch
```

### Task 9.4: Verify the release

After the workflow finishes:

```bash
gh release view v2.0.0
```

- Confirm `mac2imgur.zip` is attached
- Download via `gh release download v2.0.0`
- Unzip, drag to /Applications, launch
- Confirm Gatekeeper shows no warning
- Confirm `xattr -p com.apple.quarantine` is empty (notarization successful)

### Task 9.5: Verify Sparkle picks up the new release

- Install the older 2018 build from `mileswd/mac2imgur` releases
- Replace the `SUFeedURL` in its Info.plist with our raw appcast URL (or directly run our v2.0.0 with a bumped `CFBundleVersion` to test 2.0.0 → 2.0.1 later)
- Confirm an update prompt appears

(This is a manual verification, not automated.)

### Task 9.6: Announce

Update README's "Installation" section with confirmed working v2.0.0 download URL. Commit.

**Commit:** `[release] Confirm v2.0.0 install path in README`

---

# Done

The app is shipped. Subsequent releases follow the same flow: bump `CFBundleVersion`, tag `vX.Y.Z`, push, watch workflow, smoke-test, done.

Tier-3 SwiftUI rewrite is a separate plan, not in scope here. Core is ready to outlive the AppKit shell whenever you want to take it on.
