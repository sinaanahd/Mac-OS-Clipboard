# Pasteboard release archive

These are checksum-verified universal macOS builds retained for rollback. Every DMG contains `arm64` and `x86_64` slices.

| Version | DMG | SHA-256 |
| --- | --- | --- |
| 1.2.3 (current) | [Pasteboard-1.2.3-macOS.dmg](Pasteboard-1.2.3-macOS.dmg) | `7a01a4f7ccac1b0ef490569274488c8580de497b040de22cb54c896036624cf2` |
| 1.2.2 | [Pasteboard-1.2.2-macOS.dmg](Pasteboard-1.2.2-macOS.dmg) | `7fdc9d6702148b12d453ca17517fa8a167f8f7ed697d80c9f5a772287f5ed159` |
| 1.2.1 | [Pasteboard-1.2.1-macOS.dmg](Pasteboard-1.2.1-macOS.dmg) | `fe467d8792535d5d8d1ff6cd25d8366ee939f9b7829093febc6176446a414ea0` |
| 1.2.0 | [Pasteboard-1.2.0-macOS.dmg](Pasteboard-1.2.0-macOS.dmg) | `3c47238c37b79a77b7ec973231747e5882e6ba02bcfe47b7e39f3a48d21ced80` |

Verify a download before opening it:

```bash
shasum -a 256 -c Pasteboard-1.2.3-macOS.dmg.sha256
hdiutil verify Pasteboard-1.2.3-macOS.dmg
```

These builds are unsigned and not notarized. macOS may require the documented Finder **Open** or System Settings **Open Anyway** flow. Never disable Gatekeeper. Prefer the current version unless you are rolling back a regression; older releases may contain bugs fixed later.
