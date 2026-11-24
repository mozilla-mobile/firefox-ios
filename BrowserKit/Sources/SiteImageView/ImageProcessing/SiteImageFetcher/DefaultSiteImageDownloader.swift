// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Kingfisher
import Common

final class DefaultSiteImageDownloader: ImageDownloader, @unchecked Sendable, SiteImageDownloader {
    var timeoutDelay: Double { return 10 }
    var logger: Logger

    init(name: String = "default", logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(name: name)
        // Created per fetch, so it picks up the VPN proxy stack active at that time.
        // Only replaced while proxied, since setting it recreates Kingfisher's session.
        if #available(iOS 17.0, *), VPNProxySessionProvider.shared.isProxyActive {
            sessionConfiguration = URLSessionConfiguration.ephemeral.withVPNProxy()
        }
    }

    /// Downloads an image at the given URL. Throws `SiteImageError` errors.
    func downloadImage(with url: URL) async throws -> SiteImageLoadingResult {
        // Override Kingfisher's default timeout (which is 15s)
        let modifier = AnyModifier { [weak self] request in
            var modifiedRequest = request
            modifiedRequest.timeoutInterval = self?.timeoutDelay ?? 15
            return modifiedRequest
        }

        do {
            let result = try await downloadImage(
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
