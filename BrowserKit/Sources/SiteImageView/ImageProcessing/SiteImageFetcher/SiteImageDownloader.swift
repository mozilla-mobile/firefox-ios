// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Kingfisher
import UIKit
import Common

// MARK: - Kingfisher wrappers

/// Image downloader wrapper around Kingfisher image downloader
/// Used in FaviconFetcher
protocol SiteImageDownloader: Sendable, AnyObject {
    /// Specifies the timeout on image downloads
    var timeoutDelay: Double { get }
    var logger: Logger { get }

    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult
}

/// Image loading result wrapper for Kingfisher type so we have control when testing
/// Used in FaviconFetcher
protocol SiteImageLoadingResult {
    var image: UIImage { get }
}

extension ImageLoadingResult: SiteImageLoadingResult {}
