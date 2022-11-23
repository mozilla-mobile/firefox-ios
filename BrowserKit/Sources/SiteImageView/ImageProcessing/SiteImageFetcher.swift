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
    func fetchImage(imageURL: URL, completion: ((Result<UIImage, ImageError>) -> Void))
}

/// Image downloader wrapper around Kingfisher
protocol ImageDownloader {
    func downloadImage(with url: URL,
                       completion: ((Result<UIImage, ImageError>) -> Void))
}

// TODO: Laurie - extension on Kingfisher

struct DefaultSiteImageFetcher: SiteImageFetcher {

    private let imageDownloader: ImageDownloader

    // TODO: Kingfisher ImageDownloader.default
    init(imageDownloader: ImageDownloader) {
        self.imageDownloader = imageDownloader
    }

    //        imageDownloader.downloadImage(with: url, options: nil) { [unowned self] result in
    //            switch result {
    //            case .success(let value):
    ////                self.saveImageToCache(img: value.image, key: url.absoluteString)
    //                completion(value.image, nil)
    //            case .failure:
    //                completion(nil, ImageLoadingError.unableToFetchImage)
    //            }
    //        }

    func fetchImage(imageURL: URL, completion: ((Result<UIImage, ImageError>) -> Void)) {
        imageDownloader.downloadImage(with: imageURL, completion: completion)
    }
}
