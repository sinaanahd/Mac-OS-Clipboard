# Pasteboard contributor instructions

Pasteboard is a native, local-only clipboard-history and screenshot utility for macOS 14+ on Apple Silicon. Use Swift 6, SwiftUI, and AppKit only where macOS integration requires it. Do not introduce Electron, React, Tauri, WebView, analytics SDKs, cloud storage, or runtime third-party dependencies.

Source lives under `Pasteboard/`, grouped by feature; tests live under `PasteboardTests/`. Generate with `xcodegen generate`. Build with `xcodebuild -project Pasteboard.xcodeproj -scheme Pasteboard -configuration Debug -destination "platform=macOS" build`; test with the same project and scheme using the `test` action.

Keep changes small, idiomatic, accessible, concurrency-safe, and buildable. Prefer value types, explicit dependencies, native system colors and typography, and tests for behavior. Avoid unrelated changes. Update PRODUCT_SPEC.md, ROADMAP.md, CHANGELOG.md, and relevant decisions whenever behavior or architecture changes.

All clipboard data stays on-device. Never log complete clipboard contents. Never commit clipboard databases, captured images, history, credentials, tokens, passwords, signing certificates, provisioning profiles, or personal signing material. Use system credential storage and local ignored configuration. Do not weaken privacy or permission checks for convenience.

Use conventional commits on `main` during bootstrap. Inspect diffs, run `git diff --cached --check`, build, and test before every commit. Never force-push or rewrite shared history without explicit authorization.
