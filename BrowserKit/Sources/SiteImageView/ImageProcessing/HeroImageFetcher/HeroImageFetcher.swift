// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import LinkPresentation
import UIKit

protocol HeroImageFetcher {
    func fetchHeroImage(from siteURL: URL) async throws -> UIImage
}

class DefaultHeroImageFetcher: HeroImageFetcher {
    private let metadataProvider: LPMetadataProvider

    init(metadataProvider: LPMetadataProvider = LPMetadataProvider()) {
        self.metadataProvider = metadataProvider
    }

    func fetchHeroImage(from siteURL: URL) async throws -> UIImage {
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
