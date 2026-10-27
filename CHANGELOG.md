# Changelog

All notable changes to the `redlink_flutter_sdk` package are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.3.2] - 2026-10-27

### Changed
- Updated Redlink iOS SDK to 1.1.22.
- Updated Redlink Android SDK to 1.16.12, Firebase Messaging to 24.1.0 and AndroidX AppCompat
  to 1.7.0.
- Android apps now need `compileSdk` 35 or newer and Kotlin 2.0 or newer, as required by
  Redlink Android SDK 1.16.12 and its dependencies.

### Security

A real, non-placeholder API credential was committed to the example app's iOS configuration
file.

- **Impact:** `example/ios/Runner/RedlinkConfig.plist`'s `EventsToken` field held a
  live-looking, 128-character value instead of a placeholder. Anyone with read access to this
  repository, or any historical clone or fork of it, could recover it from git history
  regardless of this fix.
- **Severity:** Low. The other three fields in the same file (`AppId`, `Token`, `Secret`) were
  already placeholders by the time this was found, so this value alone is not sufficient to
  authenticate against the backend; the affected file is part of the example app only and is
  not shipped to any integrator's production app.
- **Affected:** this repository's git history. Not a `redlink_flutter_sdk` package/pub.dev
  version — the affected file lives under `example/` and is not published as part of the
  plugin.
- **Fixed in:** 1.3.2 — `EventsToken` replaced with an obvious placeholder (`EVENTS_TOKEN`),
  matching the style already used for the other fields.
- **Remediation:** Reported internally. The value should be treated as compromised and
  rotated on the backend if this has not already happened. Replacing the value in the working
  tree does **not** remove it from git history: anyone who already cloned this repository
  retains access to the original value regardless of this release.

## [1.3.1] - 2025-07-11

### Fixed
- Fixed Android build failures under newer Android Gradle Plugin toolchains.

### Added
- `RedlinkUser().detachToken()` to unsubscribe the device's push token.

## [1.1.9] - 2025-07-04

### Changed
- Updated Redlink Android SDK, Firebase Messaging, and Redlink iOS SDK dependencies.
- Raised minimum supported Android version to API 21 (Android 5.0).

## [1.1.8] - 2024-07-10

Dependency update.

## [1.1.7] - 2024-06-20

### Fixed
- Guarded against a crash on malformed push extras in the Android broadcast handler.

### Changed
- Updated Redlink Android SDK dependency.

## [1.1.5] - 2023-01-05

Dependency update.

## [1.1.3] - 2022-12-23

Dependency update.

## [1.1.2] - 2022-12-09

Dependency update.

## [1.1.1] - 2022-11-29

Dependency update.

## [1.1.0] - 2022-10-17

### Changed
- Enhanced support for Android 12 & 13.

## [1.0.7] - 2022-07-22

### Fixed
- Corrected README title and wording.

### Changed
- Updated Firebase Messaging Android dependency.

## [1.0.6] - 2022-06-09

### Added
- `companyName` and `externalId` parameters on `RedlinkUser.setUser()`.

### Fixed
- Resolved an iOS Simulator build conflict.

### Changed
- Added Flutter 3.0 support.

## [1.0.5] - 2022-05-24

Dependency update.

## [1.0.4] - 2022-04-26

Dependency update.

## [1.0.3] - 2022-03-18

### Added
- `deletePushToken` parameter on `RedlinkUser().removeUser()`.

## [1.0.2] - 2022-03-10

### Changed
- Unset user fields are now passed through as optional instead of defaulting to an empty string.

## [1.0.1] - 2022-02-03

Version bump only.

## [1.0.0] - 2022-02-03

### Added
- `RedlinkUser.setUser()` / `RedlinkUser.removeUser()` Dart API.
- `RedlinkAnalytics.trackEvent()` Dart API.
- Deep-link handling and Notification Service Extension setup documentation.

## [1.0.0-dev.1] - 2020-08-14

### Added
- Initial release: Android and iOS plugin implementation, example app.
