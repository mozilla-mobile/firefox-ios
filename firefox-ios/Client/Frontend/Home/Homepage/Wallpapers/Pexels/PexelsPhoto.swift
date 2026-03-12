// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - PexelsPhoto

/// Pexels photo model decoded directly from the Pexels API JSON response.
struct PexelsPhoto: Codable, Identifiable {
    let id: Int
    let photographer: String
    let photographerURL: String
    let src: PexelsPhotoSrc

    enum CodingKeys: String, CodingKey {
        case id
        case photographer
        case photographerURL = "photographer_url"
        case src
    }
}

// MARK: - PexelsPhotoSrc

struct PexelsPhotoSrc: Codable {
    /// ~1880 px wide — used for the full wallpaper download.
    let large2x: String
    /// ~940 px wide — used for grid thumbnails.
    let medium: String

    enum CodingKeys: String, CodingKey {
        case large2x
        case medium
    }
}

// MARK: - PexelsCuratedResponse

struct PexelsCuratedResponse: Codable {
    let photos: [PexelsPhoto]
    let totalResults: Int
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case photos
        case totalResults = "total_results"
        case nextPage = "next_page"
    }
}
