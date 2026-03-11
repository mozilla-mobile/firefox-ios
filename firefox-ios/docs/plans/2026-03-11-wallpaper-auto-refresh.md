# Wallpaper Auto-Refresh (Ph9)

**Date:** 2026-03-11  
**Branch:** `nb/themes`  
**Goal:** Allow users to set a refresh interval (Never / Every Hour / Daily / Weekly) for the Unsplash homepage wallpaper. When a non-Never interval is chosen, the app automatically fetches a random photo from Unsplash at the specified cadence, replacing whatever was previously pinned. Manual grid selection still works and resets the interval to "Never".

---

## Design Decisions

- **Manual → Auto conflict:** Selecting a refresh interval immediately triggers a new random photo fetch and replaces the current wallpaper. It does NOT wait for the interval to elapse.
- **Filter:** Fully random — no topic/query filter. `GET /photos/random?orientation=portrait&count=1`.
- **UI:** A `Picker` (`.segmented` style) row above the photo grid in the Appearance settings — clean, native iOS look.
- **Keys source:** New keys added to `UnsplashWallpaperKeys` (same place as existing keys).
- **Refresh trigger:** `checkAndRefreshIfNeeded()` called on `HomepageViewController.viewDidAppear` + `AppDelegate.applicationDidBecomeActive`. No background fetch task needed for MVP.
- **Conflict between auto-refresh photo and manual pin:** Stored separately — `autoRefreshPhotoId` vs `currentPhotoId`. The active wallpaper is whichever was set last. On app launch `configureUnsplashWallpaper()` prefers `autoRefreshPhotoId` if interval != "never", otherwise falls back to `currentPhotoId`.

---

## Files Changed

| File | Change |
|---|---|
| `Client/Frontend/Home/Homepage/Wallpapers/Unsplash/UnsplashService.swift` | Add `fetchRandomPhoto()` |
| `Client/Frontend/Home/Homepage/Wallpapers/Unsplash/UnsplashRefreshManager.swift` | **New file** — refresh logic |
| `Client/Frontend/Settings/AppearanceSettings/UnsplashWallpaperSectionView.swift` | Add `UnsplashRefreshInterval` enum + new keys + UI row |
| `Client/Frontend/Home/Homepage/HomepageViewController.swift` | Call `checkAndRefreshIfNeeded()` in `viewDidAppear` |
| `Client/Application/AppDelegate.swift` | Call `checkAndRefreshIfNeeded()` in `applicationDidBecomeActive` |
| `Client.xcodeproj/project.pbxproj` | Register `UnsplashRefreshManager.swift` |

---

## Ph9.1 — `UnsplashRefreshInterval` enum + persistence keys

**Files:** `UnsplashWallpaperSectionView.swift`

Add to `UnsplashWallpaperKeys`:
```swift
static let refreshInterval    = "prefKeyUnsplashRefreshInterval"    // String rawValue of UnsplashRefreshInterval
static let lastRefreshDate    = "prefKeyUnsplashLastRefreshDate"    // Double (timeIntervalSince1970)
static let autoRefreshPhotoId = "prefKeyUnsplashAutoRefreshPhotoId" // String
```

Add enum (top-level, before the view):
```swift
enum UnsplashRefreshInterval: String, CaseIterable, Identifiable {
    case never   = "never"
    case hourly  = "hourly"
    case daily   = "daily"
    case weekly  = "weekly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never:  return "Never"
        case .hourly: return "Every Hour"
        case .daily:  return "Daily"
        case .weekly: return "Weekly"
        }
    }

    var seconds: TimeInterval? {
        switch self {
        case .never:  return nil
        case .hourly: return 3600
        case .daily:  return 86400
        case .weekly: return 604800
        }
    }

    static func current() -> UnsplashRefreshInterval {
        let raw = UserDefaults.standard.string(forKey: UnsplashWallpaperKeys.refreshInterval) ?? "never"
        return UnsplashRefreshInterval(rawValue: raw) ?? .never
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: UnsplashWallpaperKeys.refreshInterval)
    }
}
```

**Commit:** `Ph9.1: Add UnsplashRefreshInterval enum and persistence keys`

---

## Ph9.2 — `fetchRandomPhoto()` in `UnsplashService`

**File:** `UnsplashService.swift`

Add method:
```swift
func fetchRandomPhoto() async throws -> UnsplashPhoto {
    let url = try buildURL(
        path: "/photos/random",
        queryItems: [
            URLQueryItem(name: "orientation", value: "portrait"),
            URLQueryItem(name: "count", value: "1")
        ]
    )
    let request = try authorizedRequest(for: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw UnsplashError.invalidResponse }
    guard http.statusCode == 200 else {
        throw http.statusCode == 403 ? UnsplashError.rateLimited : UnsplashError.serverError(http.statusCode)
    }
    // API returns an array when count=1
    let photos = try JSONDecoder().decode([UnsplashPhoto].self, from: data)
    guard let photo = photos.first else { throw UnsplashError.noResults }
    return photo
}
```

Add `case noResults` to `UnsplashError` enum.

**Commit:** `Ph9.2: Add fetchRandomPhoto() to UnsplashService`

---

## Ph9.3 — `UnsplashRefreshManager`

**File:** `Client/Frontend/Home/Homepage/Wallpapers/Unsplash/UnsplashRefreshManager.swift` (new)

```swift
/// Manages automatic periodic refresh of the Unsplash homepage wallpaper.
/// Call `checkAndRefreshIfNeeded()` on app foreground and homepage appearance.
@MainActor
final class UnsplashRefreshManager {
    static let shared = UnsplashRefreshManager()
    private let service = UnsplashService.shared

    private init() {}

    /// Checks whether the refresh interval has elapsed and fetches a new random
    /// photo if needed. No-op if interval is .never or no Unsplash config is available.
    func checkAndRefreshIfNeeded() {
        let interval = UnsplashRefreshInterval.current()
        guard let seconds = interval.seconds else { return }
        guard UnsplashConfig.load() != nil else { return }

        let lastRefresh = UserDefaults.standard.double(forKey: UnsplashWallpaperKeys.lastRefreshDate)
        let elapsed = Date().timeIntervalSince1970 - lastRefresh
        guard elapsed >= seconds else { return }

        Task { await refresh() }
    }

    /// Forces an immediate refresh regardless of interval.
    func forceRefresh() {
        guard UnsplashConfig.load() != nil else { return }
        Task { await refresh() }
    }

    // MARK: - Private

    private func refresh() async {
        do {
            let photo = try await service.fetchRandomPhoto()
            let image = try await service.downloadWallpaperImage(for: photo)

            // Clean up previous auto-refresh photo (not the manually pinned one)
            if let oldId = UserDefaults.standard.string(forKey: UnsplashWallpaperKeys.autoRefreshPhotoId),
               oldId != UserDefaults.standard.string(forKey: UnsplashWallpaperKeys.currentPhotoId) {
                service.removeDownloadedWallpaper(photoId: oldId)
            }

            UserDefaults.standard.set(photo.id, forKey: UnsplashWallpaperKeys.autoRefreshPhotoId)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: UnsplashWallpaperKeys.lastRefreshDate)

            try? service.triggerDownloadTracking(for: photo)

            NotificationCenter.default.post(
                name: .UnsplashWallpaperDidChange,
                object: nil,
                userInfo: ["image": image, "photoId": photo.id, "photographerName": photo.user.name]
            )
        } catch {
            // Silent failure — keep existing wallpaper
        }
    }
}
```

**Commit:** `Ph9.3: Add UnsplashRefreshManager for periodic auto-refresh`

---

## Ph9.4 — Refresh Interval UI in `UnsplashWallpaperSectionView`

**File:** `UnsplashWallpaperSectionView.swift`

Add `@State private var refreshInterval: UnsplashRefreshInterval` initialised from `UnsplashRefreshInterval.current()`.

Add a row above the photo grid:

```swift
private var refreshIntervalRow: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Auto-Refresh Wallpaper")
            .font(.subheadline)
            .foregroundColor(Color(theme?.colors.textPrimary ?? .label))
        Picker("Refresh interval", selection: $refreshInterval) {
            ForEach(UnsplashRefreshInterval.allCases) { interval in
                Text(interval.displayName).tag(interval)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: refreshInterval) { newInterval in
            newInterval.save()
            // Reset lastRefreshDate so new interval applies from now
            if newInterval == .never {
                UserDefaults.standard.removeObject(forKey: UnsplashWallpaperKeys.lastRefreshDate)
            } else {
                UserDefaults.standard.set(
                    Date().timeIntervalSince1970,
                    forKey: UnsplashWallpaperKeys.lastRefreshDate
                )
                UnsplashRefreshManager.shared.forceRefresh()
            }
        }
    }
}
```

Add `refreshIntervalRow` above the photo grid in the section body. When `selectPhoto()` is called (manual pin), also reset interval to `.never` and save it.

**Commit:** `Ph9.4: Add auto-refresh interval picker UI to UnsplashWallpaperSectionView`

---

## Ph9.5 — Hook into app lifecycle

**Files:** `HomepageViewController.swift`, `AppDelegate.swift`

In `HomepageViewController.viewDidAppear(_:)`:
```swift
UnsplashRefreshManager.shared.checkAndRefreshIfNeeded()
```

In `AppDelegate.applicationDidBecomeActive(_:)`:
```swift
UnsplashRefreshManager.shared.checkAndRefreshIfNeeded()
```

**Commit:** `Ph9.5: Hook UnsplashRefreshManager into app lifecycle`

---

## Ph9.6 — Add new file to project, SwiftLint, build verify, commit

- Add `UnsplashRefreshManager.swift` to `project.pbxproj` (same group as `UnsplashService.swift`)
- Run SwiftLint, fix any violations
- Run build, fix any errors

**Commit:** `Ph9.6: Build fixes and project registration for wallpaper auto-refresh`

---

## Edge Cases

| Case | Handling |
|---|---|
| Interval changed while no API keys configured | `checkAndRefreshIfNeeded()` no-ops if `UnsplashConfig.load() == nil` |
| Rate limit hit | `UnsplashError.rateLimited` caught silently, existing wallpaper kept |
| Network offline | `URLSession` throws, caught silently |
| First launch with interval != never | `lastRefreshDate == 0` → `elapsed >= seconds` always true → fetches immediately |
| Manual pin + interval set | Manual pin resets interval to `.never`, auto-refresh stops |
| No results from random endpoint | `UnsplashError.noResults` caught silently |
