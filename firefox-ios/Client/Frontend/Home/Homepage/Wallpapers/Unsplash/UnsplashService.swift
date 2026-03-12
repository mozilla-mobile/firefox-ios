// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Service for interacting with the Unsplash API.
/// Handles fetching curated/search photos, downloading full-size images,
/// and triggering download tracking per Unsplash API guidelines.
final class UnsplashService {
    static let shared = UnsplashService()

    private let session: URLSession
    private let baseURL = "https://api.unsplash.com"
    private var config: UnsplashConfig?

    /// Directory where downloaded Unsplash wallpapers are stored.
    private var wallpaperDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("wallpapers/unsplash", isDirectory: true)
    }

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
        self.config = UnsplashConfig.load()
    }

    /// Whether the service is configured (API key available).
    var isConfigured: Bool {
        config != nil
    }

    // MARK: - Fetch Photos

    /// Fetches a page of curated/editorial photos.
    func fetchCuratedPhotos(page: Int = 1, perPage: Int = 20) async throws -> [UnsplashPhoto] {
        let url = try buildURL(
            path: "/photos",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "order_by", value: "popular"),
            ]
        )
        let request = try authorizedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode([UnsplashPhoto].self, from: data)
    }

    /// Searches photos by query string.
    func searchPhotos(query: String, page: Int = 1, perPage: Int = 20) async throws -> UnsplashSearchResult {
        let url = try buildURL(
            path: "/search/photos",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "orientation", value: "portrait"),
            ]
        )
        let request = try authorizedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(UnsplashSearchResult.self, from: data)
    }

    /// Fetches a single random portrait photo from the Unsplash library.
    /// Uses GET /photos/random?orientation=portrait&count=1
    func fetchRandomPhoto() async throws -> UnsplashPhoto {
        let url = try buildURL(
            path: "/photos/random",
            queryItems: [
                URLQueryItem(name: "orientation", value: "portrait"),
                URLQueryItem(name: "count", value: "1"),
            ]
        )
        let request = try authorizedRequest(for: url)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        // Unsplash returns an array when count=1
        let photos = try JSONDecoder().decode([UnsplashPhoto].self, from: data)
        guard let photo = photos.first else { throw UnsplashError.noResults }
        return photo
    }

    // MARK: - Download Image

    /// Downloads the regular-sized image for a photo and saves it to disk.
    /// Returns the local file URL of the saved image.
    @discardableResult
    func downloadWallpaperImage(for photo: UnsplashPhoto) async throws -> URL {
        guard let dir = wallpaperDirectory else {
            throw UnsplashError.storageUnavailable
        }

        let photoDir = dir.appendingPathComponent(photo.id, isDirectory: true)
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)

        // Download the regular-size image (1080px wide, good for phone screens)
        guard let imageURL = URL(string: photo.urls.regular) else {
            throw UnsplashError.invalidURL
        }

        let (data, response) = try await session.data(from: imageURL)
        try validateResponse(response)

        let fileURL = photoDir.appendingPathComponent("wallpaper.jpg")
        try data.write(to: fileURL)

        // Trigger download tracking per Unsplash API guidelines
        await triggerDownloadTracking(for: photo)

        return fileURL
    }

    /// Downloads a thumbnail image and returns it as UIImage.
    func downloadThumbnail(for photo: UnsplashPhoto) async throws -> UIImage {
        guard let url = URL(string: photo.urls.small) else {
            throw UnsplashError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        guard let image = UIImage(data: data) else {
            throw UnsplashError.invalidImageData
        }

        return image
    }

    /// Loads a previously downloaded wallpaper image from disk.
    func loadSavedWallpaper(photoId: String) -> UIImage? {
        guard let dir = wallpaperDirectory else { return nil }
        let fileURL = dir
            .appendingPathComponent(photoId, isDirectory: true)
            .appendingPathComponent("wallpaper.jpg")
        return UIImage(contentsOfFile: fileURL.path)
    }

    /// Checks if a wallpaper image is already downloaded.
    func isWallpaperDownloaded(photoId: String) -> Bool {
        guard let dir = wallpaperDirectory else { return false }
        let fileURL = dir
            .appendingPathComponent(photoId, isDirectory: true)
            .appendingPathComponent("wallpaper.jpg")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Removes a downloaded wallpaper from disk.
    func removeDownloadedWallpaper(photoId: String) {
        guard let dir = wallpaperDirectory else { return }
        let photoDir = dir.appendingPathComponent(photoId, isDirectory: true)
        try? FileManager.default.removeItem(at: photoDir)
    }

    // MARK: - Download Tracking (Unsplash Guideline Requirement)

    /// Per Unsplash API guidelines, we must trigger the download endpoint
    /// when a photo is actually downloaded for use (not just displayed as thumbnail).
    private func triggerDownloadTracking(for photo: UnsplashPhoto) async {
        guard let config = config,
              let url = URL(string: photo.links.downloadLocation + "?client_id=\(config.accessKey)") else {
            return
        }

        // Fire and forget — we don't need the response
        _ = try? await session.data(from: url)
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw UnsplashError.invalidURL
        }
        return url
    }

    private func authorizedRequest(for url: URL) throws -> URLRequest {
        guard let config = config else {
            throw UnsplashError.notConfigured
        }

        var request = URLRequest(url: url)
        request.setValue("Client-ID \(config.accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnsplashError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw UnsplashError.unauthorized
        case 403:
            throw UnsplashError.rateLimited
        case 404:
            throw UnsplashError.notFound
        default:
            throw UnsplashError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - WallpaperProvider Conformance

extension UnsplashService: WallpaperProvider {
    func fetchRandom() async throws -> WallpaperPhoto {
        let photo = try await fetchRandomPhoto()
        return wallpaperPhotoValue(from: photo)
    }

    func fetchCurated(page: Int, perPage: Int) async throws -> [WallpaperPhoto] {
        let photos = try await fetchCuratedPhotos(page: page, perPage: perPage)
        return photos.map { wallpaperPhotoValue(from: $0) }
    }

    func search(query: String, page: Int, perPage: Int) async throws -> [WallpaperPhoto] {
        let result = try await searchPhotos(query: query, page: page, perPage: perPage)
        return result.results.map { wallpaperPhotoValue(from: $0) }
    }

    func downloadImage(for photo: WallpaperPhoto) async throws -> URL {
        guard let dir = wallpaperDirectory else { throw UnsplashError.storageUnavailable }
        let photoDir = dir.appendingPathComponent(photo.id, isDirectory: true)
        let fileURL = photoDir.appendingPathComponent("wallpaper.jpg")
        if FileManager.default.fileExists(atPath: fileURL.path) { return fileURL }
        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        let (data, response) = try await session.data(from: photo.fullURL)
        try validateResponse(response)
        try data.write(to: fileURL)
        return fileURL
    }

    func loadSavedImage(photoId: String) -> UIImage? {
        return loadSavedWallpaper(photoId: photoId)
    }

    func isImageDownloaded(photoId: String) -> Bool {
        return isWallpaperDownloaded(photoId: photoId)
    }

    func removeDownloadedImage(photoId: String) {
        removeDownloadedWallpaper(photoId: photoId)
    }

    // Maps an UnsplashPhoto to the provider-agnostic WallpaperPhoto.
    func wallpaperPhotoValue(from photo: UnsplashPhoto) -> WallpaperPhoto {
        let thumbURL = URL(string: photo.urls.small) ?? URL(string: photo.urls.thumb)!
        let fullURL = URL(string: photo.urls.regular)!
        let pageURL = URL(string: photo.links.html)!
        return WallpaperPhoto(
            id: photo.id,
            photographerName: photo.user.name,
            providerName: WallpaperProviderType.unsplash.displayName,
            thumbnailURL: thumbURL,
            fullURL: fullURL,
            pageURL: pageURL
        )
    }
}

// MARK: - Errors

enum UnsplashError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case invalidImageData
    case unauthorized
    case rateLimited
    case notFound
    case noResults
    case storageUnavailable
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Unsplash API is not configured. Add UnsplashConfig.json to the project."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .invalidImageData:
            return "Could not decode image data."
        case .unauthorized:
            return "Unsplash API key is invalid."
        case .rateLimited:
            return "Unsplash API rate limit exceeded. Try again later."
        case .notFound:
            return "Photo not found."
        case .noResults:
            return "No photos were returned."
        case .storageUnavailable:
            return "Cannot access wallpaper storage directory."
        case .serverError(let code):
            return "Server error (\(code))."
        }
    }
}
