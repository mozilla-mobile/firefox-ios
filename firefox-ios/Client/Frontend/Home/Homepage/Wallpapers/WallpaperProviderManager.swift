// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

// MARK: - Notification

extension Notification.Name {
    /// Posted when the active wallpaper provider changes.
    /// userInfo is empty — callers should clear their cached wallpaper.
    static let wallpaperProviderDidChange = Notification.Name("WallpaperProviderDidChange")
}

// MARK: - WallpaperProviderManager

/// Routes wallpaper requests to the currently active provider (Pexels or Unsplash).
/// The active provider is persisted in UserDefaults and defaults to Pexels.
@MainActor
final class WallpaperProviderManager {
    static let shared = WallpaperProviderManager()

    // MARK: - Active Provider

    /// The currently selected provider type. Reads/writes UserDefaults.
    var activeProviderType: WallpaperProviderType {
        get {
            let raw = UserDefaults.standard.string(
                forKey: PrefsKeys.CustomTheming.activeWallpaperProvider
            ) ?? WallpaperProviderType.pexels.rawValue
            return WallpaperProviderType(rawValue: raw) ?? .unsplash
        }
        set {
            UserDefaults.standard.set(
                newValue.rawValue,
                forKey: PrefsKeys.CustomTheming.activeWallpaperProvider
            )
        }
    }

    /// The service that should be used for all wallpaper operations.
    var activeProvider: WallpaperProvider {
        switch activeProviderType {
        case .pexels: return PexelsService.shared
        case .unsplash: return UnsplashService.shared
        }
    }

    // MARK: - Switching Providers

    /// Switches to a new provider, clears the saved wallpaper photo id,
    /// and posts `wallpaperProviderDidChange` so the UI can reset.
    func switchProvider(to type: WallpaperProviderType) {
        guard type != activeProviderType else { return }
        activeProviderType = type
        // Clear the saved wallpaper so the homepage shows no image until a new one is chosen.
        UserDefaults.standard.removeObject(forKey: WallpaperKeys.currentPhotoId)
        NotificationCenter.default.post(name: .wallpaperProviderDidChange, object: nil)
    }
}

// MARK: - WallpaperKeys

/// Provider-agnostic UserDefaults key constants for active wallpaper state.
enum WallpaperKeys {
    /// The photo id of the currently selected wallpaper (any provider).
    static let currentPhotoId = "WallpaperCurrentPhotoId"
    /// Auto-refresh interval raw value (mirrors UnsplashWallpaperKeys.refreshInterval).
    static let refreshInterval = "WallpaperRefreshInterval"
    /// Timestamp of the last auto-refresh (mirrors UnsplashWallpaperKeys.lastRefreshDate).
    static let lastRefreshDate = "WallpaperLastRefreshDate"
    /// Photo id set by the last auto-refresh (mirrors UnsplashWallpaperKeys.autoRefreshPhotoId).
    static let autoRefreshPhotoId = "WallpaperAutoRefreshPhotoId"
}
