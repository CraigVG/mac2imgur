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
