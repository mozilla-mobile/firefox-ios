// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Fuzi
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
    ///   - network: Fetches the page HTML when the VPN proxy is active
    /// - Returns: the hero image
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider,
                        network: HTMLDataRequest) async throws -> UIImage
}

extension HeroImageFetcher {
    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider(),
                        network: HTMLDataRequest = DefaultHTMLDataRequest()
    ) async throws -> UIImage {
        try await fetchHeroImage(from: siteURL, metadataProvider: metadataProvider, network: network)
    }
}

final class DefaultHeroImageFetcher: HeroImageFetcher {
    /// Checked in priority order. `og:` tags use `property`, `twitter:` tags use `name`, but sites mix them up.
    private static let imageMetaKeys = [
        "og:image", "og:image:url", "og:image:secure_url", "twitter:image", "twitter:image:src"
    ]

    private static var isVPNProxyActive: Bool {
        guard #available(iOS 17.0, *) else { return false }
        return VPNProxySessionProvider.shared.isProxyActive
    }

    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider(),
                        network: HTMLDataRequest = DefaultHTMLDataRequest()
    ) async throws -> UIImage {
        // LPMetadataProvider fetches outside the app's URLSessions, so scrape meta tags through the proxy instead.
        if Self.isVPNProxyActive {
            return try await fetchHeroImageFromMetaTags(siteURL: siteURL, network: network)
        }
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

    func heroImageURL(from data: Data, siteURL: URL) -> URL? {
        guard let root = try? HTMLDocument(data: data) else { return nil }
        return Self.imageMetaKeys.lazy
            .compactMap { root.firstChild(xpath: "//head/meta[@property='\($0)' or @name='\($0)']")?["content"] }
            .compactMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines), relativeTo: siteURL)?.absoluteURL }
            .first { $0.scheme == "https" || $0.scheme == "http" }
    }

    // MARK: - Private

    private func fetchHeroImageFromMetaTags(siteURL: URL, network: HTMLDataRequest) async throws -> UIImage {
        let data = try await network.fetchDataForURL(siteURL)
        // The site URL may point directly at an image rather than an HTML page.
        if let image = UIImage(data: data) { return image }
        guard let imageURL = heroImageURL(from: data, siteURL: siteURL) else {
            throw SiteImageError.noHeroImage
        }
        // Created per fetch so it picks up the current proxy stack.
        return try await DefaultSiteImageDownloader().downloadImage(with: imageURL).image
    }
}
