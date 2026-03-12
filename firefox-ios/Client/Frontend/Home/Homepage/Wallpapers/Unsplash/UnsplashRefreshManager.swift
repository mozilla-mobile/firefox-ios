// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Manages automatic periodic refresh of the homepage wallpaper using the active provider.
///
/// Call `checkAndRefreshIfNeeded()` when the app becomes active or the homepage appears.
/// When the configured refresh interval has elapsed, fetches a new random photo via
/// `WallpaperProviderManager.shared.activeProvider` and posts
/// `Notification.Name.UnsplashWallpaperDidChange` so `HomepageViewController` updates.
@MainActor
final class UnsplashRefreshManager {
    static let shared = UnsplashRefreshManager()

    private var isRefreshing = false

    private init() {}

    // MARK: - Public

    /// Checks whether the configured refresh interval has elapsed and, if so,
    /// fetches and applies a new random wallpaper from the active provider.
    /// No-op when interval is `.never`.
    func checkAndRefreshIfNeeded() {
        let interval = UnsplashRefreshInterval.current()
        guard let seconds = interval.seconds else { return }
        guard !isRefreshing else { return }

        let lastRefresh = UserDefaults.standard.double(forKey: WallpaperKeys.lastRefreshDate)
        let elapsed = Date().timeIntervalSince1970 - lastRefresh
        guard elapsed >= seconds else { return }

        Task { await refresh() }
    }

    /// Forces an immediate random wallpaper fetch via the active provider,
    /// ignoring the interval check. Used when the user selects a new interval.
    func forceRefresh() {
        guard !isRefreshing else { return }
        Task { await refresh() }
    }

    // MARK: - Private

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let provider = WallpaperProviderManager.shared.activeProvider
        let defaults = UserDefaults.standard

        do {
            let photo = try await provider.fetchRandom()
            let fileURL = try await provider.downloadImage(for: photo)
            guard let image = UIImage(contentsOfFile: fileURL.path) else { return }

            // Clean up previous auto-refresh photo if it differs from the pinned one
            if let oldId = defaults.string(forKey: WallpaperKeys.autoRefreshPhotoId),
               oldId != defaults.string(forKey: WallpaperKeys.currentPhotoId) {
                provider.removeDownloadedImage(photoId: oldId)
            }

            defaults.set(photo.id, forKey: WallpaperKeys.autoRefreshPhotoId)
            defaults.set(Date().timeIntervalSince1970, forKey: WallpaperKeys.lastRefreshDate)

            NotificationCenter.default.post(
                name: .UnsplashWallpaperDidChange,
                object: nil,
                userInfo: [
                    "image": image,
                    "photoId": photo.id,
                    "photographerName": photo.photographerName
                ]
            )
        } catch {
            // Silent failure — keep the existing wallpaper
        }
    }
}
