# Release Smoke Test

Run before tagging any new version. Check each box on a clean Mac (or after deleting `~/Library/Application Support/mac2imgur` and `~/Library/Preferences/com.mileswd.mac2imgur.plist` for state-clean tests).

## Install & migration

- [ ] Fresh install on Mac with no prior mac2imgur — app launches, status icon appears in menu bar
- [ ] Install over the 2018 build — preferences (album, login state) preserved
- [ ] App quarantine flag handled (Gatekeeper opens cleanly with no "unverified developer" warning — Path B notarized release)

## Upload flows

- [ ] ⌘⇧3 screenshot — uploads, notification fires, URL on clipboard
- [ ] ⌘⇧4 selection — uploads, notification, clipboard
- [ ] Drag image file onto status bar icon — uploads
- [ ] "Upload Images…" menu item — file picker opens, multi-select uploads all

## Account

- [ ] Log in with Imgur OAuth — ASWebAuthenticationSession opens system browser, returns token
- [ ] After login, "Signed in to Imgur" header in menu
- [ ] Sign out — falls back to anonymous, refresh token cleared

## Album upload

- [ ] Set album ID in Settings → Account
- [ ] Upload an image — verify on imgur.com that the image landed in the named album
- [ ] Clear album ID — uploads go to the default account location

## Preferences (SwiftUI Settings scene)

- [ ] Open via ⌘, or "Preferences…" menu item — Settings window opens
- [ ] Each toggle persists across app restart
- [ ] Launch at Login toggle — actually launches at next login (verify with `launchctl list | grep mac2imgur`)
- [ ] Delete-after-upload — original screenshot moved to Trash
- [ ] Confirmation-before-upload — dialog appears, cancel skips upload
- [ ] Copy-link-to-clipboard off — URL not pasted

## Sparkle

- [ ] App with build 300 fed an appcast advertising build 301 — update prompt appears
- [ ] Update downloads, EdDSA signature verifies, app relaunches on new version
- [ ] Manually corrupted signature in test appcast — update is rejected with error (negative test)

## Definition of done for v2.0.0

A v2.0.0 release ships only when **all** of these are green:

1. ✅ All Core unit tests pass in CI (`swift test` → 27 tests in 9 suites)
2. ✅ Smoke test checklist above run by hand on Apple Silicon Mac
3. ✅ Release workflow produces a notarized, stapled `.app`
4. ✅ Sparkle `appcast.xml` updated and committed by the workflow
5. ✅ Downloaded zip from GitHub Releases opens cleanly with no Gatekeeper warning
6. ✅ README, NOTICE.md, CREDITS.md attributions correct
