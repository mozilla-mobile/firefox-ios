// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Manages automatic periodic refresh of the Unsplash homepage wallpaper.
///
/// Call `checkAndRefreshIfNeeded()` when the app becomes active or the homepage appears.
/// When the configured refresh interval has elapsed, fetches a new random photo and
/// posts `Notification.Name.UnsplashWallpaperDidChange` — which `HomepageViewController`
/// already handles with zero additional wiring.
@MainActor
final class UnsplashRefreshManager {
    static let shared = UnsplashRefreshManager()

    private let service = UnsplashService.shared
    private var isRefreshing = false

    private init() {}

    // MARK: - Public

    /// Checks whether the configured refresh interval has elapsed and, if so,
    /// fetches and applies a new random wallpaper. No-op when interval is `.never`
    /// or no Unsplash credentials are configured.
    func checkAndRefreshIfNeeded() {
        let interval = UnsplashRefreshInterval.current()
        guard let seconds = interval.seconds else { return }
        guard UnsplashConfig.load() != nil else { return }
        guard !isRefreshing else { return }

        let lastRefresh = UserDefaults.standard.double(forKey: UnsplashWallpaperKeys.lastRefreshDate)
        let elapsed = Date().timeIntervalSince1970 - lastRefresh
        guard elapsed >= seconds else { return }

        Task { await refresh() }
    }

    /// Forces an immediate random wallpaper fetch, ignoring the interval check.
    /// Used when the user selects a new interval in the Appearance settings.
    func forceRefresh() {
        guard UnsplashConfig.load() != nil else { return }
        guard !isRefreshing else { return }
        Task { await refresh() }
    }

    // MARK: - Private

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let photo = try await service.fetchRandomPhoto()
            // downloadWallpaperImage returns a local file URL and internally
            // triggers download tracking per Unsplash API guidelines.
            let fileURL = try await service.downloadWallpaperImage(for: photo)

            guard let image = UIImage(contentsOfFile: fileURL.path) else { return }

            // Clean up previous auto-refresh photo from disk (if different from manual pin)
            let defaults = UserDefaults.standard
            if let oldId = defaults.string(forKey: UnsplashWallpaperKeys.autoRefreshPhotoId),
               oldId != defaults.string(forKey: UnsplashWallpaperKeys.currentPhotoId) {
                service.removeDownloadedWallpaper(photoId: oldId)
            }

            defaults.set(photo.id, forKey: UnsplashWallpaperKeys.autoRefreshPhotoId)
            defaults.set(Date().timeIntervalSince1970, forKey: UnsplashWallpaperKeys.lastRefreshDate)

            NotificationCenter.default.post(
                name: .UnsplashWallpaperDidChange,
                object: nil,
                userInfo: [
                    "image": image,
                    "photoId": photo.id,
                    "photographerName": photo.user.name
                ]
            )
        } catch {
            // Silent failure — keep existing wallpaper
        }
    }
}
