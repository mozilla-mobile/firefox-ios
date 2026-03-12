// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Keys

enum UnsplashWallpaperKeys {
    static let currentPhotoId = "prefKeyUnsplashWallpaperPhotoId"
    static let currentPhotoJSON = "prefKeyUnsplashWallpaperPhotoJSON"
    static let refreshInterval    = "prefKeyUnsplashRefreshInterval"
    static let lastRefreshDate    = "prefKeyUnsplashLastRefreshDate"
    static let autoRefreshPhotoId = "prefKeyUnsplashAutoRefreshPhotoId"
}

extension Notification.Name {
    static let UnsplashWallpaperDidChange = Notification.Name("UnsplashWallpaperDidChange")
}

// MARK: - Refresh Interval

enum UnsplashRefreshInterval: String, CaseIterable, Identifiable {
    case never
    case hourly
    case daily
    case weekly

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
        let raw = UserDefaults.standard.string(forKey: WallpaperKeys.refreshInterval) ?? "never"
        return UnsplashRefreshInterval(rawValue: raw) ?? .never
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: WallpaperKeys.refreshInterval)
    }
}
