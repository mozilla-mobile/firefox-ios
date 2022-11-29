// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Kingfisher

protocol SiteImageFetcher {
    /// Fetches an image from a specific URL
    /// - Parameter imageURL: Given a certain image URL
    /// - Returns: An image or an image error following Result type
    func fetchImage(from imageURL: URL) async -> Result<UIImage, ImageError>
}

struct DefaultSiteImageFetcher: SiteImageFetcher {

    private let imageDownloader: SiteImageDownloader

    init(imageDownloader: SiteImageDownloader = ImageDownloader.default) {
        self.imageDownloader = imageDownloader
    }

    func fetchImage(from imageURL: URL) async -> Result<UIImage, ImageError> {
        let result = await imageDownloader.downloadImage(with: imageURL)

        switch result {
        case .success(let value):
            return .success(value.image)
        case .failure(let error):
            return .failure(ImageError.unableToDownloadImage(error.errorDescription ?? "No description"))
        }
    }
}
