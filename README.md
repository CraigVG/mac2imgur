# mac2imgur

A simple Mac menu bar app that uploads screenshots and images to [Imgur](https://imgur.com), with the link automatically copied to your clipboard.

> A drop-in modernized fork of [mac2imgur](https://github.com/mileswd/mac2imgur) by [Miles Wu](https://github.com/mileswd) (2013-2018). Native Apple Silicon, signed and notarized, auto-updating via Sparkle 2. Same Bundle Identifier as the original, so installing this version cleanly replaces an existing 2018 install and preserves your preferences and Imgur login.

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
- Click the menu bar icon and choose "Upload Images..."

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
