// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Kingfisher

protocol FaviconFetcher {
    /// Fetches a favicon image from a specific URL
    /// - Parameter imageURL: Given a certain image URL
    /// - Returns: An image or an image error following Result type
    func fetchFavicon(from imageURL: URL) async throws -> UIImage
}

struct DefaultFaviconFetcher: FaviconFetcher {
    private let imageDownloader: SiteImageDownloader

    init(imageDownloader: SiteImageDownloader = ImageDownloader.default) {
        self.imageDownloader = imageDownloader
    }

    func fetchFavicon(from imageURL: URL) async throws -> UIImage {
        do {
            let result = try await imageDownloader.downloadImage(with: imageURL)
            return result.image
        } catch let error as KingfisherError {
            throw SiteImageError.unableToDownloadImage(error.errorDescription ?? "No description")
        } catch {
            throw SiteImageError.unableToDownloadImage("No description")
        }
    }
}
