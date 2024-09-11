// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit
import Common

// MARK: - Kingfisher wrappers

/// Image downloader wrapper around Kingfisher image downloader
/// Used in FaviconFetcher
protocol SiteImageDownloader: AnyObject {
    /// Provides the KingFisher ImageDownloader with a Timeout in case the completion isn't called
    var timeoutDelay: UInt64 { get }
    var continuation: CheckedContinuation<any SiteImageLoadingResult, any Error>? { get set }
    var logger: Logger { get }

    @discardableResult
    func downloadImage(
        with url: URL,
        completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?
    ) -> DownloadTask?

    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult
}

extension SiteImageDownloader {
    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult {
        return try await withThrowingTaskGroup(of: SiteImageLoadingResult.self) { group in
            // Use task groups to have a timeout when downloading an image from Kingfisher
            // due to https://sentry.io/share/issue/951b878416374dd98eccb6fd88fd8427
            group.addTask {
                return try await self.handleImageDownload(url: url)
            }

            group.addTask {
                try await self.handleTimeout()
            }

            // wait for the first task and cancel the other one
            let result = try await group.next()
            group.cancelAll()
            guard let result = result else {
                throw SiteImageError.unableToDownloadImage("Result not present")
            }
            return result
        }
    }

    private func handleImageDownload(url: URL) async throws -> any SiteImageLoadingResult {
        return try await withCheckedThrowingContinuation { continuation in
            // Store a copy of the continuation to act on in the case the sleep finishes first
            self.continuation = continuation

            _ = self.downloadImage(with: url) { result in
                guard let continuation = self.continuation else { return }
                switch result {
                case .success(let imageResult):
                    continuation.resume(returning: imageResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                self.continuation = nil
            }
        }
    }

    private func handleTimeout() async throws -> any SiteImageLoadingResult {
        try await Task.sleep(nanoseconds: self.timeoutDelay * NSEC_PER_SEC)
        try Task.checkCancellation()
        let error = SiteImageError.unableToDownloadImage("Timeout reached")
        self.continuation?.resume(throwing: error)
        self.continuation = nil

        self.logger.log("Timeout when downloading image reached",
                        level: .warning,
                        category: .images)
        throw error
    }
}

/// Image loading result wrapper for Kingfisher type so we have control when testing
/// Used in FaviconFetcher
protocol SiteImageLoadingResult {
    var image: UIImage { get }
}

extension ImageLoadingResult: SiteImageLoadingResult {}
