# Multi-Provider Wallpapers (Unsplash + Pexels)

**Date:** 2026-03-12  
**Branch:** nb/themes  
**Status:** Planning

---

## Goal

Add Pexels as a second wallpaper provider alongside Unsplash. Only one provider is active at a time. The active provider is chosen in Settings → Feature Flags (Debug). The wallpaper grid in Appearance Settings always shows photos from the currently active provider. Attribution reads "Photo by {photographer} on {providerName}" dynamically.

---

## Pexels API Reference

- **Base URL:** `https://api.pexels.com/v1/`
- **Auth:** `Authorization: {API_KEY}` header (same pattern as Unsplash `Client-ID`)
- **Curated photos:** `GET /curated?per_page=20&page={n}`
- **Search:** `GET /search?query=nature&orientation=portrait&per_page=20`
- **Random:** Curated with random `page` in 1…100
- **Response:** `{ photos: [{ id: Int, photographer: String, photographer_url: String, src: { original, large2x, large, medium, small, portrait, tiny } }] }`
- **Download size for wallpaper:** `src.large2x` (~2x retina, ~1880px wide)
- **Thumbnail:** `src.medium` (~1280px) or `src.small` (640px)
- **No download tracking** (unlike Unsplash — no need to call a tracking endpoint)
- **Attribution required:** "Photo by {photographer} on Pexels"
- **Storage path:** `applicationSupport/wallpapers/pexels/{photoId}/wallpaper.jpg`

---

## Architecture

### Provider Abstraction

Introduce a `WallpaperProvider` protocol. Both `UnsplashService` and new `PexelsService` conform to it. A `WallpaperProviderManager` singleton routes all calls to the currently active service.

Everything above this layer (HomepageVC, RefreshManager, WallpaperSectionView) only talks to `WallpaperProviderManager` — never directly to `UnsplashService` or `PexelsService`.

### Shared Model: `WallpaperPhoto`

Provider-agnostic struct:

```swift
struct WallpaperPhoto {
    let id: String           // String for both (Pexels Int cast to String)
    let photographerName: String
    let providerName: String // "Unsplash" | "Pexels"
    let thumbnailURL: URL
    let fullURL: URL         // high-res for download
    let pageURL: URL         // for attribution link
}
```

### Active Provider Persistence

- Key: `PrefsKeys.CustomTheming.activeWallpaperProvider` → `String` in UserDefaults
- Values: `"unsplash"` | `"pexels"`
- **Default: `"pexels"`** (Pexels is the new default)
- Switching provider clears the saved wallpaper from the old provider so the homepage shows no wallpaper until a new one is picked

### Wallpaper UserDefaults Keys (provider-agnostic)

Replace `UnsplashWallpaperKeys.currentPhotoId` with `WallpaperKeys.currentPhotoId`. The value stored is always from the active provider. On provider switch, `currentPhotoId` is cleared.

Keep `UnsplashWallpaperKeys` as a typealias or keep it in place for backward compat with the refresh interval / auto-refresh prefs (those are provider-agnostic anyway).

---

## Files to Create

| File | Purpose |
|------|---------|
| `Wallpapers/WallpaperProvider.swift` | `WallpaperPhoto` model, `WallpaperProvider` protocol, `WallpaperProviderType` enum |
| `Wallpapers/WallpaperProviderManager.swift` | Singleton, routes to active provider, handles switching |
| `Wallpapers/Pexels/PexelsConfig.swift` | 3-tier key loading (bundle JSON → UserDefaults → placeholder) |
| `Wallpapers/Pexels/PexelsPhoto.swift` | `Codable` model matching Pexels JSON response |
| `Wallpapers/Pexels/PexelsService.swift` | Conforms to `WallpaperProvider`, disk storage, image download |
| `Settings/.../PexelsKeyTextSetting.swift` | Text-entry Setting subclass for Pexels API key |

## Files to Modify

| File | Change |
|------|--------|
| `Wallpapers/Unsplash/UnsplashService.swift` | Add `WallpaperProvider` conformance (adapter methods mapping `UnsplashPhoto` → `WallpaperPhoto`) |
| `Wallpapers/Unsplash/UnsplashRefreshManager.swift` | Route fetch/download through `WallpaperProviderManager` instead of `UnsplashService` directly; rename to `WallpaperRefreshManager` |
| `AppearanceSettings/UnsplashWallpaperSectionView.swift` | Use `WallpaperProviderManager` for fetch + attribution; rename to `WallpaperSectionView` |
| `HomepageViewController.swift` | Update `hasActiveWallpaper`, notification handler; remove direct `UnsplashService` refs |
| `FeatureFlagsDebugViewController.swift` | Add provider toggle + Pexels key rows; rename section header |
| `Shared/Prefs.swift` (`BrowserKit`) | Add `activeWallpaperProvider`, `pexelsApiKey` to `PrefsKeys.CustomTheming` |
| `Client.xcodeproj/project.pbxproj` | Register all new Swift files |

---

## Phase Breakdown

### Ph11-A: Provider protocol + shared model
**New file:** `Wallpapers/WallpaperProvider.swift`
- `struct WallpaperPhoto` (provider-agnostic model)
- `protocol WallpaperProvider`: `fetchRandom() async throws -> WallpaperPhoto`, `fetchCurated(page:perPage:) async throws -> [WallpaperPhoto]`, `downloadImage(for:) async throws -> URL`, `loadSavedImage(photoId:) -> UIImage?`, `isImageDownloaded(photoId:) -> Bool`, `removeDownloadedImage(photoId:)`
- `enum WallpaperProviderType: String, CaseIterable`: `.pexels` (default), `.unsplash`
- Add `activeWallpaperProvider` + `pexelsApiKey` constants to `PrefsKeys.CustomTheming`
- Commit: "Ph11-A: WallpaperProvider protocol, WallpaperPhoto model, WallpaperProviderType enum"

### Ph11-B: Pexels service
**New files:** `PexelsConfig.swift`, `PexelsPhoto.swift`, `PexelsService.swift`
- `PexelsConfig.load()`: bundle `PexelsConfig.json` (gitignored) → UserDefaults `pexelsApiKey` → placeholder
- `PexelsPhoto`: Codable matching `{ id, photographer, photographer_url, src: { large2x, medium } }`
- `PexelsService.shared`: conforms to `WallpaperProvider`, stores at `wallpapers/pexels/{id}/wallpaper.jpg`, no tracking call
- Commit: "Ph11-B: PexelsService, PexelsConfig, PexelsPhoto model"

### Ph11-C: Unsplash conforms to WallpaperProvider
- Add `WallpaperProvider` conformance to `UnsplashService` via extension
- `fetchRandom()` → maps `UnsplashPhoto` to `WallpaperPhoto(providerName: "Unsplash", ...)`
- Existing API unchanged; extension is purely additive
- Commit: "Ph11-C: UnsplashService conforms to WallpaperProvider"

### Ph11-D: WallpaperProviderManager
**New file:** `Wallpapers/WallpaperProviderManager.swift`
- `@MainActor` singleton
- `var activeProviderType: WallpaperProviderType` — reads/writes UserDefaults
- `var activeProvider: WallpaperProvider` — returns correct service
- `func switchProvider(to: WallpaperProviderType)` — persists, clears `WallpaperKeys.currentPhotoId`, posts `WallpaperProviderDidChange` notification
- Commit: "Ph11-D: WallpaperProviderManager singleton"

### Ph11-E: Rename UnsplashRefreshManager → WallpaperRefreshManager
- Route through `WallpaperProviderManager.shared.activeProvider.fetchRandom()` + `.downloadImage(for:)`
- Keep notification name `Notification.Name.UnsplashWallpaperDidChange` as is (avoids wider refactor)
- Commit: "Ph11-E: WallpaperRefreshManager routes through active provider"

### Ph11-F: Update WallpaperSectionView (was UnsplashWallpaperSectionView)
- Rename file + struct to `WallpaperSectionView`
- Fetch using `WallpaperProviderManager.shared.activeProvider.fetchCurated(...)`
- Grid items are `WallpaperPhoto` (provider-agnostic)
- Attribution label: `"Photo by \(photo.photographerName) on \(photo.providerName)"`
- `WallpaperKeys.currentPhotoId` (not `UnsplashWallpaperKeys.currentPhotoId`)
- Update `AppearanceSettingsView` to reference `WallpaperSectionView`
- Commit: "Ph11-F: WallpaperSectionView uses active provider, dynamic attribution"

### Ph11-G: Settings — provider toggle + Pexels key entry
**New file:** `PexelsKeyTextSetting.swift`
- In `FeatureFlagsDebugViewController`:
  - Rename Unsplash section header → "Wallpaper Provider"
  - Row 1: **"Active Provider"** — `WallpaperProviderToggleSetting` — shows "Pexels" / "Unsplash", tapping toggles and calls `WallpaperProviderManager.shared.switchProvider(to:)`
  - Row 2: **"Pexels API Key"** — `PexelsKeyTextSetting` (writes `PrefsKeys.CustomTheming.pexelsApiKey`)
  - Row 3+: existing Unsplash key rows unchanged
- Commit: "Ph11-G: Provider toggle + Pexels key entry in Feature Flags debug settings"

### Ph11-H: HomepageViewController + PrefsKeys cleanup
- `hasActiveWallpaper`: check `UserDefaults.standard.string(forKey: WallpaperKeys.currentPhotoId) != nil`
- Listen for `WallpaperProviderDidChange` notification → clear wallpaper on provider switch
- Commit: "Ph11-H: HomepageVC uses provider-agnostic WallpaperKeys, handles provider switch"

---

## UserDefaults Key Migration

| Old key | New key | Notes |
|---------|---------|-------|
| `UnsplashWallpaperKeys.currentPhotoId` | `WallpaperKeys.currentPhotoId` | Same UserDefaults value, new constant name |
| `UnsplashWallpaperKeys.refreshInterval` | `WallpaperKeys.refreshInterval` | Same |
| *(new)* | `PrefsKeys.CustomTheming.activeWallpaperProvider` | `"pexels"` default |
| *(new)* | `PrefsKeys.CustomTheming.pexelsApiKey` | User-entered Pexels key |

`UnsplashWallpaperKeys` in `UnsplashWallpaperSectionView.swift` stays as-is for the time being and gets migrated in Ph11-F.

---

## Constraints & Gotchas

- **SwiftLint:** `closure_body_length` ≤ 34, `file_length` ≤ 400, no trailing commas
- **New files** need 4 entries in `project.pbxproj`
- **`PexelsConfig.json`** goes in gitignore alongside `UnsplashConfig.json`
- **Pexels photo id is `Int`** in JSON — cast to `String` when creating `WallpaperPhoto.id`
- **No tracking call** for Pexels downloads
- **`WallpaperRefreshManager`** must check `WallpaperProviderManager.shared.activeProvider` at call time (not at init) since provider can change at runtime
- **Provider switch** must clear the saved wallpaper + post notification so HomepageVC hides it immediately
- **`PexelsService` key loading** must handle placeholder → return `nil` same as `UnsplashConfig`
