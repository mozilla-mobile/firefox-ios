// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - PexelsError

enum PexelsError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case invalidImageData
    case unauthorized
    case rateLimited
    case noResults
    case storageUnavailable
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Pexels API key not configured."
        case .invalidURL: return "Invalid request URL."
        case .invalidResponse: return "Unexpected server response."
        case .invalidImageData: return "Could not decode image data."
        case .unauthorized: return "Invalid or missing Pexels API key."
        case .rateLimited: return "Pexels rate limit exceeded. Try again later."
        case .noResults: return "No photos found."
        case .storageUnavailable: return "Cannot access local storage."
        case .serverError(let code): return "Server error (HTTP \(code))."
        }
    }
}

// MARK: - PexelsService

/// Wallpaper service backed by the Pexels API.
/// Conforms to `WallpaperProvider` so it can be swapped with `UnsplashService`.
final class PexelsService: WallpaperProvider {
    static let shared = PexelsService()

    private let baseURL = "https://api.pexels.com/v1"
    private let providerName = WallpaperProviderType.pexels.displayName

    // MARK: - Storage

    private var wallpaperDirectory: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("wallpapers/pexels", isDirectory: true)
    }

    private func wallpaperFileURL(photoId: String) -> URL? {
        wallpaperDirectory?.appendingPathComponent("\(photoId)/wallpaper.jpg")
    }

    // MARK: - WallpaperProvider

    func fetchRandom() async throws -> WallpaperPhoto {
        let page = Int.random(in: 1...50)
        let photos = try await fetchCurated(page: page, perPage: 15)
        guard let photo = photos.randomElement() else { throw PexelsError.noResults }
        return photo
    }

    func fetchCurated(page: Int, perPage: Int) async throws -> [WallpaperPhoto] {
        guard let config = PexelsConfig.load() else { throw PexelsError.notConfigured }
        var components = URLComponents(string: "\(baseURL)/curated")
        components?.queryItems = [
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        guard let url = components?.url else { throw PexelsError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)

        let decoded = try JSONDecoder().decode(PexelsCuratedResponse.self, from: data)
        return decoded.photos.compactMap { wallpaperPhoto(from: $0) }
    }

    func search(query: String, page: Int, perPage: Int) async throws -> [WallpaperPhoto] {
        guard let config = PexelsConfig.load() else { throw PexelsError.notConfigured }
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "orientation", value: "portrait")
        ]
        guard let url = components?.url else { throw PexelsError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(config.apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)

        let decoded = try JSONDecoder().decode(PexelsCuratedResponse.self, from: data)
        return decoded.photos.compactMap { wallpaperPhoto(from: $0) }
    }

    func downloadImage(for photo: WallpaperPhoto) async throws -> URL {
        guard let dir = wallpaperDirectory else { throw PexelsError.storageUnavailable }
        let photoDir = dir.appendingPathComponent(photo.id, isDirectory: true)
        let fileURL = photoDir.appendingPathComponent("wallpaper.jpg")

        if FileManager.default.fileExists(atPath: fileURL.path) { return fileURL }

        try FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)

        let (data, response) = try await URLSession.shared.data(from: photo.fullURL)
        try validateHTTPResponse(response)
        guard UIImage(data: data) != nil else { throw PexelsError.invalidImageData }
        try data.write(to: fileURL)
        return fileURL
    }

    func loadSavedImage(photoId: String) -> UIImage? {
        guard let url = wallpaperFileURL(photoId: photoId) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    func isImageDownloaded(photoId: String) -> Bool {
        guard let url = wallpaperFileURL(photoId: photoId) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func removeDownloadedImage(photoId: String) {
        guard let url = wallpaperFileURL(photoId: photoId) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Helpers

    private func wallpaperPhoto(from photo: PexelsPhoto) -> WallpaperPhoto? {
        guard let thumbURL = URL(string: photo.src.medium),
              let fullURL = URL(string: photo.src.large2x),
              let pageURL = URL(string: photo.photographerURL) else { return nil }
        return WallpaperPhoto(
            id: String(photo.id),
            photographerName: photo.photographer,
            providerName: providerName,
            thumbnailURL: thumbURL,
            fullURL: fullURL,
            pageURL: pageURL
        )
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw PexelsError.invalidResponse }
        switch http.statusCode {
        case 200...299: return
        case 401: throw PexelsError.unauthorized
        case 429: throw PexelsError.rateLimited
        default: throw PexelsError.serverError(statusCode: http.statusCode)
        }
    }
}
