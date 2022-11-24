// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Kingfisher

protocol SiteImageFetcher {
    /// Fetches an image from a specific URL
    /// - Parameters:
    ///   - imageURL: Given a certain image URL
    ///   - completion: The return will be an image or an image error following Result type
    func fetchImage(imageURL: URL,
                    completion: @escaping ((Result<UIImage, ImageError>) -> Void))
}

struct DefaultSiteImageFetcher: SiteImageFetcher {

    private let imageDownloader: SiteImageDownloader

    init(imageDownloader: SiteImageDownloader = ImageDownloader.default) {
        self.imageDownloader = imageDownloader
    }

    func fetchImage(imageURL: URL,
                    completion: @escaping ((Result<UIImage, ImageError>) -> Void)) {
        imageDownloader.downloadImage(with: imageURL,
                                      completionHandler: { result in
            switch result {
            case .success(let value):
                completion(.success(value.image))
            case .failure(let error):
                completion(.failure(ImageError.unableToDownloadImage(error.errorDescription ?? "No description")))
            }
        })
    }
}
