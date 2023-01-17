// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Kingfisher
import UIKit

// MARK: - Kingfisher wrappers

/// Image downloader wrapper around Kingfisher image downloader
/// Used in FaviconFetcher
protocol SiteImageDownloader {
    @discardableResult
    func downloadImage(
        with url: URL,
        completionHandler: ((Result<SiteImageLoadingResult, KingfisherError>) -> Void)?
    ) -> DownloadTask?

    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult
}

extension SiteImageDownloader {
    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult {
        return try await withCheckedThrowingContinuation { continuation in
            _ = downloadImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension ImageDownloader: SiteImageDownloader {
    func downloadImage(with url: URL,
                       completionHandler: ((Result<SiteImageLoadingResult, KingfisherError>) -> Void)?
    ) -> DownloadTask? {
        downloadImage(with: url, options: nil, completionHandler: { result in
            switch result {
            case .success(let value):
                completionHandler?(.success(value))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        })
    }
}

/// Image loading result wrapper for Kingfisher type so we have control when testing
/// Used in FaviconFetcher
protocol SiteImageLoadingResult {
    var image: UIImage { get }
}

extension ImageLoadingResult: SiteImageLoadingResult {}
