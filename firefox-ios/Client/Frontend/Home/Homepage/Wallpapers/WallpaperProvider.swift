// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - WallpaperProviderType

/// The set of supported wallpaper providers. Pexels is the default.
public enum WallpaperProviderType: String, CaseIterable {
    case pexels
    case unsplash

    /// Human-readable display name shown in settings and attribution labels.
    var displayName: String {
        switch self {
        case .pexels: return "Pexels"
        case .unsplash: return "Unsplash"
        }
    }
}

// MARK: - WallpaperPhoto

/// Provider-agnostic photo model shared by all wallpaper services.
public struct WallpaperPhoto: Identifiable, Equatable, Codable {
    public let id: String
    public let photographerName: String
    /// Display name of the provider, e.g. "Pexels" or "Unsplash".
    public let providerName: String
    /// Low-resolution URL used for grid thumbnails.
    public let thumbnailURL: URL
    /// Full-resolution URL used when downloading the wallpaper.
    public let fullURL: URL
    /// Web page for this photo, used for attribution links.
    public let pageURL: URL

    /// Attribution string shown below the wallpaper grid item.
    public var attribution: String {
        return "Photo by \(photographerName) on \(providerName)"
    }
}

// MARK: - WallpaperProvider

/// Protocol all wallpaper services must conform to.
public protocol WallpaperProvider {
    /// Fetch a single random photo suitable for use as a wallpaper.
    func fetchRandom() async throws -> WallpaperPhoto

    /// Fetch a page of curated/popular photos.
    func fetchCurated(page: Int, perPage: Int) async throws -> [WallpaperPhoto]

    /// Download the full-resolution wallpaper image to local storage and return its file URL.
    func downloadImage(for photo: WallpaperPhoto) async throws -> URL

    /// Return the cached full-resolution image for a previously downloaded photo, or nil.
    func loadSavedImage(photoId: String) -> UIImage?

    /// Search for photos matching a query string. Returns an empty array if unsupported.
    func search(query: String, page: Int, perPage: Int) async throws -> [WallpaperPhoto]

    /// Return true if the wallpaper for this photo id has already been downloaded.
    func isImageDownloaded(photoId: String) -> Bool

    /// Delete the downloaded wallpaper file for this photo id.
    func removeDownloadedImage(photoId: String)
}
