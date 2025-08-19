// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LinkPresentation
import UIKit

// FXIOS-13243: LPMetadataProvider and LPLinkMetadata are not Sendable across boundaries
extension LPLinkMetadata: @unchecked @retroactive Sendable {}
extension LPMetadataProvider: @unchecked @retroactive Sendable {}

protocol HeroImageFetcher: Sendable {
    /// FetchHeroImage using metadataProvider needs the main thread, hence using @MainActor for it.
    /// LPMetadataProvider is also a one shot object that we need to throw away once used.
    /// - Parameters:
    ///   - siteURL: the url to fetch the hero image with
    ///   - metadataProvider: LPMetadataProvider
    /// - Returns: the hero image
    func fetchHeroImage(from siteURL: URL, metadataProvider: LPMetadataProvider) async throws -> UIImage
}

extension HeroImageFetcher {
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        try await fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
    }
}

final class DefaultHeroImageFetcher: HeroImageFetcher {
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        do {
            // `startFetchingMetadata` needs to be called on the main thread on older devices. See PRs #12694 and #27951
            let metadata = try await Task { @MainActor in
                try await metadataProvider.startFetchingMetadata(for: siteURL)
            }.value
            guard let imageProvider = metadata.imageProvider else {
                throw SiteImageError.unableToDownloadImage("Metadata image provider could not be retrieved.")
            }

            return try await withCheckedThrowingContinuation { continuation in
                imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                    guard error == nil else {
                        continuation.resume(
                            throwing: SiteImageError.unableToDownloadImage(error.debugDescription.description)
                        )
                        return
                    }

                    guard let image = image as? UIImage else {
                        continuation.resume(
                            throwing: SiteImageError.unableToDownloadImage("NSItemProviderReading not an image")
                        )
                        return
                    }

                    continuation.resume(returning: image)
                }
            }
        } catch {
            throw error
        }
    }
}
