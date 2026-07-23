# Release validation

This document records evidence for the current Pasteboard release candidate. Automated checks do not replace permission, Gatekeeper, accessibility, appearance, multi-display, or end-to-end interaction checks.

## Release candidate

| Item | Result |
| --- | --- |
| Version | 1.2.4 (build 9) |
| Minimum deployment target | macOS 14.0 |
| Local validation host | macOS 26.5.2 (25F84), Apple Silicon |
| Local toolchain | Xcode 26.6 (17F113), Swift 6.3.3 |
| Local Release bundle metadata | Verified as 1.2.4 (build 9), universal `x86_64 arm64` |
| Connected displays | One, 3440×1440 |
| Unsigned DMG | `Pasteboard-1.2.4-macOS.dmg` |
| DMG SHA-256 | `317eeb0da50fd8a81d394ca870b4c8c30885132585021b0c84edc0c16a76e437` |

## Automated matrix

GitHub Actions run [29999773120](https://github.com/sinaanahd/Mac-OS-Clipboard/actions/runs/29999773120) completed successfully for commit `ec9ce9595c96b342ca5fba36b21d61fbb6fce6d3` on 2026-07-23.

| Runner | Xcode | Generate | Build | Tests |
| --- | --- | --- | --- | --- |
| macOS 14 | 16.2 | Passed | Passed | Passed |
| macOS 15 | 26.3 | Passed | Passed | Passed |
| macOS 26 | 26.5 | Passed | Passed | Passed |

The local macOS 26 suite also passed 57 tests with no failures. Compiler guards ensure Xcode 16 builds only the native material fallback and does not parse macOS 26 Liquid Glass symbols. The automated matrix above covers the preceding 1.2.3 release commit; the 1.2.4 CI run is pending publication.

## Manual evidence

| Area | macOS 14 | macOS 15 | macOS 26 |
| --- | --- | --- | --- |
| Settings/history key-window interaction | Not run | Not run | Passed |
| History panel, search, pins, and keyboard navigation | Not run | Not run | Partial: 1.2.3 layout, search, pin/unpin, and selection passed; Return exposed a first-responder routing defect. The 1.2.4 fix is unit-tested and awaits installed interaction verification |
| About/version/copyright presentation | Not run | Not run | Passed for installed 1.2.3; 1.2.4 bundle metadata verified |
| Accessibility permission denial/grant/revocation | Not run | Not run | Pending |
| Screen Recording denial/grant/cancel/capture | Not run | Not run | Pending |
| Reduce Motion, Reduced Transparency, Increased Contrast, and VoiceOver | Not run | Not run | Pending |
| Light/dark appearance and multi-display placement | Not run | Not run | Pending |
| Unsigned DMG Gatekeeper flow from a clean account | Not run | Not run | Pending |

“Not run” means that no machine or virtual machine for that OS has completed the manual checklist. It must not be interpreted as a failure or a pass.

## macOS 26 host preflight

Read-only inspection on 2026-07-23 established the current test host baseline without changing permissions or security settings.

| Check | Observed state | Coverage |
| --- | --- | --- |
| Accessibility permission | Pasteboard enabled | Current granted state verified; denial and revocation remain pending |
| Screen & System Audio Recording permission | Pasteboard enabled | Current granted state verified; denial, prompt, and revocation remain pending |
| Reduce Motion | Off | Normal-motion baseline available; reduced-motion UI pass remains pending |
| Gatekeeper policy | App Store & Known Developers | Security remains enabled; clean-account unsigned-DMG flow remains pending |
| Displays | One connected display | Single-display placement is available; multi-display placement is unavailable on this host |

## Release boundary

Version 1.2.4 is buildable, tested, packaged, and verified as an unsigned universal local release. Installed Return-key interaction verification remains pending. Public distribution remains blocked on the manual rows above and, for a frictionless public install, a Developer ID Application certificate plus notarization credentials. Testing an unsigned build must use the documented Finder **Open** or System Settings **Open Anyway** flow; never disable Gatekeeper.

Record completed manual checks here with the date, OS build, machine architecture, tester, and concise evidence. Keep the detailed procedures in `MANUAL_TESTING.md`.
