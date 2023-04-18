// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LinkPresentation
import UIKit

protocol HeroImageFetcher {
    /// FetchHeroImage using metadataProvider needs the main thread, hence using @MainActor for it.
    /// LPMetadataProvider is also a one shot object that we need to throw away once used.
    /// - Parameters:
    ///   - siteURL: the url to fetch the hero image with
    ///   - metadataProvider: LPMetadataProvider
    /// - Returns: the hero image
    @MainActor
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) async throws -> UIImage
}

extension HeroImageFetcher {
    @MainActor
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        try await fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
    }
}

class DefaultHeroImageFetcher: HeroImageFetcher {
    @MainActor
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        do {
            let metadata = try await metadataProvider.startFetchingMetadata(for: siteURL)
            guard let imageProvider = metadata.imageProvider else {
                throw SiteImageError.unableToDownloadImage("Metadata image provider could not be retrieved.")
            }

            return try await imageProvider.loadObject(ofClass: UIImage.self)
        } catch {
            throw error
        }
    }
}
