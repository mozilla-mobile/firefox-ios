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
    /// Specifies the timeout on image downloads
    var timeoutDelay: Double { get }
    var logger: Logger { get }

    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult
}

extension SiteImageDownloader {
    /// Downloads an image at the given URL. Throws `SiteImageError` errors.
    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult {
        // Override Kingfisher's default timeout (which is 15s)
        let modifier = AnyModifier { [weak self] request in
            var modifiedRequest = request
            modifiedRequest.timeoutInterval = self?.timeoutDelay ?? 15
            return modifiedRequest
        }

        do {
            let result = try await ImageDownloader.default.downloadImage(
                with: url,
                options: [
                    .processor(SVGImageProcessor()),
                    .requestModifier(modifier)
                ]
            )
            return result
        } catch let error as KingfisherError {
            // Log telemetry for Kingfisher timeout errors
            if case .responseError(let reason) = error,
               case .URLSessionError(let sessionError) = reason,
               let error = sessionError as? URLError,
               error.code == .timedOut {
                self.logger.log("Timeout when downloading image reached",
                                level: .warning,
                                category: .images)
            }

            throw SiteImageError.unableToDownloadImage(error.errorDescription ?? "No description")
        } catch {
            throw SiteImageError.unableToDownloadImage(error.localizedDescription)
        }
    }
}

/// Image loading result wrapper for Kingfisher type so we have control when testing
/// Used in FaviconFetcher
protocol SiteImageLoadingResult {
    var image: UIImage { get }
}

extension ImageLoadingResult: SiteImageLoadingResult {}
