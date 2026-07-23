# Pasteboard contributor instructions

Pasteboard is a native, local-only clipboard-history and screenshot utility for macOS 14+ on Apple Silicon. Use Swift 6, SwiftUI, and AppKit only where macOS integration requires it. Do not introduce Electron, React, Tauri, WebView, analytics SDKs, cloud storage, or runtime third-party dependencies.

Source lives under `Pasteboard/`, grouped by feature; tests live under `PasteboardTests/`. Generate with `xcodegen generate`. Build with `xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -configuration Debug -destination "platform=macOS" build`; test with the same project and scheme using the `test` action.

Keep changes small, idiomatic, accessible, concurrency-safe, and buildable. Prefer value types, explicit dependencies, native system colors and typography, and tests for behavior. Avoid unrelated changes. Update PRODUCT_SPEC.md, ROADMAP.md, CHANGELOG.md, and relevant decisions whenever behavior or architecture changes.

All clipboard data stays on-device. Never log complete clipboard contents. Never commit clipboard databases, captured images, history, credentials, tokens, passwords, signing certificates, provisioning profiles, or personal signing material. Use system credential storage and local ignored configuration. Do not weaken privacy or permission checks for convenience.

Preferences use typed `UserDefaults`; clipboard metadata uses coalesced atomic JSON and image payloads use separate files in Application Support. Do not describe SQLite as implemented. Pinned entries are exempt from automatic limits and expiration. Keep macOS 26 visual APIs availability-guarded, preserve macOS 14 fallbacks, and respect system Reduce Motion, Reduced Transparency, and Increased Contrast.

The credential-free package command is `./scripts/build-local-dmg.sh`. Optional notarization uses `./scripts/build-notarized-dmg.sh` only with secure local environment/keychain configuration. Commit checksum-verified, versioned release DMGs and their matching `.sha256` files under `dist/` so older releases remain available. Never commit unpackaged built apps, temporary build output, unversioned artifacts, Developer ID material, Team credentials, notary profiles, or any other signing secrets.

Use conventional commits on `main` during bootstrap. Inspect diffs, run `git diff --cached --check`, build, and test before every commit. Never force-push or rewrite shared history without explicit authorization.

Versioning starts at `1.0.0`. For every publishable change after that baseline, update `MARKETING_VERSION` in `project.yml` before committing. Increment the patch component for ordinary changes and fixes (`1.0.X`). Increment the minor component and reset patch to zero for substantial feature releases (`1.X.0`). Keep the displayed version, generated project, bundle metadata, documentation, and changelog consistent with that value. Do not change the major version without explicit user direction.
