# Architecture & Firefox Fork Conventions

This is a **fork of Mozilla Firefox iOS** with Ecosia customizations layered on top. Minimize modifications to Firefox core to reduce upstream merge conflicts.

## Key Directories

| Path | Purpose |
|---|---|
| `Ecosia/` | **Ecosia Framework** — isolated Ecosia logic (analytics, core models, networking, experiments, UI). New Ecosia code goes here. |
| `firefox-ios/Client/Ecosia/` | Ecosia code within the Client target (extensions on Firefox classes, NTP, settings, onboarding). Legacy location — prefer the framework when possible. |
| `firefox-ios/Client/` | Firefox Client app — Ecosia modifications are marked with `// Ecosia:` comments. |
| `firefox-ios/EcosiaTests/` | Ecosia unit tests and snapshot tests. |
| `BrowserKit/` | Shared Swift package (Common, Redux, SiteImageView, TabDataStore, WebEngine, etc.). |

## Core Ecosia Modules (inside `Ecosia/`)

- **Core/** — `User`, `Environment`, `HTTPClient`, `Statistics`, `Referrals`, `SearchesCounter`, `Navigation`
- **Analytics/** — Snowplow-based analytics via `Analytics.shared`
- **FeatureManagement/** — feature toggles and Unleash client: `LocalFeatureFlags/` for hardcoded/temporary flags, `Unleash/Experiments/` for A/B experiments, `Unleash/FeatureFlags/` for remote on/off toggles
- **Braze/** — Push notification integration (`BrazeService`)
- **UI/** — SwiftUI/UIKit design system, NTP components, settings, onboarding

## Extension Pattern for Firefox Customization

Ecosia extends Firefox classes via `+Ecosia` extension files in `firefox-ios/Client/Ecosia/Extensions/` (e.g., `BrowserViewController+Ecosia.swift`). Use this pattern to add behavior to Firefox classes without modifying their original files.

## Commenting Rules for Ecosia Code in Firefox Files

Use `// Ecosia: <reason>` for new code additions. Use `/* Ecosia: <reason> … */` to comment out original Firefox code, keeping it visible inside the block, then place the Ecosia replacement immediately after — this preserves context for upstream merges. For full examples of the swap pattern and shared declaration pattern, see [Ecosia/Ecosia.docc/Ecosia.md](../Ecosia.md).

## Environment Detection

Environments are detected by bundle ID in `Ecosia/Core/Environment/Environment.swift`:
- `com.ecosia.ecosiaapp` → production
- `com.ecosia.ecosiaapp.firefox` → staging
- Any other → debug
