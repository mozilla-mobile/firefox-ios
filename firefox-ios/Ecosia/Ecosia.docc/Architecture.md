# Architecture & design — Ecosia iOS

High level

Ecosia is provided as a framework under firefox-ios/Ecosia. The framework contains Ecosia-specific UI, assets and business logic while the rest of the app is provided by the upstream Firefox code.

Key components

- Ecosia Framework (firefox-ios/Ecosia)
  - UI, assets and feature logic
  - New Tab Page (NTP)
- User scripts: Client/Frontend/UserContent/UserScripts/

New Tab Page (NTP) — quick notes

- Wallpaper asset: `Ecosia/UI/Common.xcassets/ntpBackground.imageset` (loaded via `UIImage.ecosia(named:)`).
- Impact tiles: `NTPImpactCell` / `NTPImpactCellViewModel`, driven by `TreesProjection` and `InvestmentsProjection`.
- Rotating title: `RotatingTitlesService` (CDN-backed, cached in `UserDefaults`).
- Shortcut tiles: `TopSiteCell` with Ecosia glassmorphism background.
- Toolbar order: back → forward → new-tab → tabs → menu (new-tab uses `nav-add`, menu uses `elipsis`).

Design notes

- Keep Ecosia-specific changes scoped to the Ecosia framework where possible to reduce rebase conflicts.
- When editing upstream Firefox files for Ecosia behavior, use clear comment prefixes so rebasing is simpler (see Contributing.md).

If you'd like, I can add a small symbol map (most important classes and file locations) for a specific area such as NTP or user scripts.