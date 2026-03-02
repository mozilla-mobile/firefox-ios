// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a photo from the Unsplash API.
/// Only the fields we need are decoded; the API returns many more.
struct UnsplashPhoto: Codable, Identifiable, Equatable {
    let id: String
    let slug: String?
    let description: String?
    let altDescription: String?
    let urls: UnsplashPhotoURLs
    let user: UnsplashUser
    let links: UnsplashPhotoLinks
    let color: String? // Dominant hex color, e.g. "#6E633A"
    let width: Int
    let height: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, description, urls, user, links, color, width, height
        case altDescription = "alt_description"
    }

    static func == (lhs: UnsplashPhoto, rhs: UnsplashPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

/// Photo URLs at various sizes.
struct UnsplashPhotoURLs: Codable {
    let raw: String
    let full: String
    let regular: String  // 1080px wide — good for phone wallpapers
    let small: String    // 400px wide — good for thumbnails
    let thumb: String    // 200px wide — smallest thumbnail
}

/// Photo author information.
struct UnsplashUser: Codable {
    let id: String
    let username: String
    let name: String
    let portfolioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username, name
        case portfolioUrl = "portfolio_url"
    }
}

/// Links related to a photo (download tracking, HTML page, etc.).
struct UnsplashPhotoLinks: Codable {
    let html: String
    let download: String
    let downloadLocation: String // Must be called to trigger download tracking

    enum CodingKeys: String, CodingKey {
        case html, download
        case downloadLocation = "download_location"
    }
}

/// Wrapper for search results from `/search/photos`.
struct UnsplashSearchResult: Codable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]

    enum CodingKeys: String, CodingKey {
        case total, results
        case totalPages = "total_pages"
    }
}
