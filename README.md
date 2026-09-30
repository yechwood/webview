# WebView Guard (prototype)

An Android standalone WebView host that denies HTTP/HTTPS requests while preserving local packaged HTML/CSS/JavaScript and assets. It intentionally has no `INTERNET` permission.

## Build

GitHub Actions builds a debug APK on pushes to `main`; download it from the workflow's artifacts or Releases when available.

## Important platform limitation

This app does **not** replace Android's system WebView provider and does not change WebViews inside unrelated apps. On ordinary Android 11, a regular APK cannot silently replace the system provider. System-wide enforcement requires OS/OEM integration or a suitably privileged/rooted setup. This prototype is a starting point for testing resource blocking, not a system-wide filter.

## Current behavior

- Allows packaged `file:///android_asset/` content.
- Blocks HTTP and HTTPS loads and remote resource requests.
- Does not declare `android.permission.INTERNET`.
- Target SDK is kept at 28 for broad device compatibility during initial prototyping.
