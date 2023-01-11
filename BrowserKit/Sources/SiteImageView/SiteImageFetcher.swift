// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

public protocol SiteImageFetcher {
    func getImage(urlStringRequest: String,
                  type: SiteImageType,
                  id: UUID,
                  usesIndirectDomain: Bool) async -> SiteImageModel
}

public class DefaultSiteImageFetcher: SiteImageFetcher {
    private let urlHandler: FaviconURLHandler
    private let imageHandler: ImageHandler

    public static func factory() -> DefaultSiteImageFetcher {
        return DefaultSiteImageFetcher()
    }

    init(urlHandler: FaviconURLHandler = DefaultFaviconURLHandler(),
         imageHandler: ImageHandler = DefaultImageHandler()) {
        self.urlHandler = urlHandler
        self.imageHandler = imageHandler
    }

    public func getImage(urlStringRequest: String,
                         type: SiteImageType,
                         id: UUID,
                         usesIndirectDomain: Bool) async -> SiteImageModel {
        var imageModel = SiteImageModel(id: id,
                                        expectedImageType: type,
                                        urlStringRequest: urlStringRequest,
                                        siteURL: nil,
                                        cacheKey: "",
                                        domain: nil,
                                        faviconURL: nil,
                                        faviconImage: nil,
                                        heroImage: nil)

        // urlStringRequest possibly cannot be a URL
        if let siteURL = URL(string: urlStringRequest) {
            let domain = generateDomainURL(siteURL: siteURL)
            imageModel.siteURL = siteURL
            imageModel.domain = domain
            imageModel.cacheKey = generateCacheKey(siteURL: siteURL,
                                                   type: type,
                                                   usesIndirectDomain: usesIndirectDomain)
        }

        do {
            switch type {
            case .heroImage:
                imageModel.heroImage = try await getHeroImage(imageModel: imageModel)
            case .favicon:
                imageModel.faviconImage = await getFaviconImage(imageModel: imageModel)
            }
        } catch {
            // If hero image fails, we return a favicon image
            imageModel.faviconImage = await getFaviconImage(imageModel: imageModel)
        }

        return imageModel
    }

    // MARK: - Private

    private func generateCacheKey(siteURL: URL,
                                  type: SiteImageType,
                                  usesIndirectDomain: Bool) -> String {
        guard usesIndirectDomain else {
            return siteURL.shortDomain ?? siteURL.shortDisplayString
        }
        return siteURL.absoluteString
    }

    private func getHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        do {
            return try await imageHandler.fetchHeroImage(site: imageModel)
        } catch {
            throw error
        }
    }

    private func getFaviconImage(imageModel: SiteImageModel) async -> UIImage {
        do {
            // Try to fetch the favicon URL
            let faviconURLImageModel = try await urlHandler.getFaviconURL(site: imageModel)
            return await imageHandler.fetchFavicon(site: faviconURLImageModel)
        } catch {
            // If no favicon URL, generate favicon without it
            return await imageHandler.fetchFavicon(site: imageModel)
        }
    }

    private func generateDomainURL(siteURL: URL) -> ImageDomain {
        let bundleDomains = BundleDomainBuilder().buildDomains(for: siteURL)
        return ImageDomain(bundleDomains: bundleDomains)
    }
}
