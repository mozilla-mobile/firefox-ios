// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Kingfisher
import UIKit

// MARK: - Kingfisher wrappers

/// Image downloader wrapper around Kingfisher image downloader
/// Used in FaviconFetcher
protocol SiteImageDownloader {
    /// Provides the KingFisher ImageDownloader with a Timeout in case the completion isn't called
    var timer: Timer? { get set }
    var timeoutDelay: Double { get }
    var shouldContinue: Bool { get }
    func createTimer(completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?)

    @discardableResult
    func downloadImage(
        with url: URL,
        completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?
    ) -> DownloadTask?

    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult
}

extension SiteImageDownloader {
    var shouldContinue: Bool {
        // Ensure timer is valid and hasn't fired to avoid calling continuation twice
        guard timer?.isValid ?? true else { return false }
        timer?.invalidate()

        return true
    }

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

/// Image loading result wrapper for Kingfisher type so we have control when testing
/// Used in FaviconFetcher
protocol SiteImageLoadingResult {
    var image: UIImage { get }
}

extension ImageLoadingResult: SiteImageLoadingResult {}
