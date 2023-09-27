// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol SiteImageHandler {
    func getImage(site: SiteImageModel) async -> SiteImageModel
    func cacheFaviconURL(siteURL: URL?, faviconURL: URL?)
    func clearAllCaches()
}

public class DefaultSiteImageHandler: SiteImageHandler {
    private let urlHandler: FaviconURLHandler
    private let imageHandler: ImageHandler

    public static func factory() -> DefaultSiteImageHandler {
        return DefaultSiteImageHandler()
    }

    init(urlHandler: FaviconURLHandler = DefaultFaviconURLHandler(),
         imageHandler: ImageHandler = DefaultImageHandler()) {
        self.urlHandler = urlHandler
        self.imageHandler = imageHandler
    }

    public func getImage(site: SiteImageModel) async -> SiteImageModel {
        var imageModel = site

        // urlStringRequest possibly cannot be a URL
        if let siteURL = URL(string: site.siteURLString ?? "", encodingInvalidCharacters: false) {
            let domain = generateDomainURL(siteURL: siteURL)
            imageModel.siteURL = siteURL
            imageModel.domain = domain
        }

        imageModel.cacheKey = generateCacheKey(siteURL: URL(string: site.siteURLString ?? "", encodingInvalidCharacters: false),
                                               faviconURL: imageModel.faviconURL,
                                               type: imageModel.expectedImageType)

        do {
            switch site.expectedImageType {
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

    public func cacheFaviconURL(siteURL: URL?, faviconURL: URL?) {
        guard let siteURL = siteURL,
              let faviconURL = faviconURL else {
            return
        }

        let cacheKey = generateCacheKey(siteURL: siteURL,
                                        type: .favicon)
        urlHandler.cacheFaviconURL(cacheKey: cacheKey, faviconURL: faviconURL)
    }

    public func clearAllCaches() {
        urlHandler.clearCache()
        imageHandler.clearCache()
    }

    // MARK: - Private

    private func generateCacheKey(siteURL: URL?,
                                  faviconURL: URL? = nil,
                                  type: SiteImageType) -> String {
        // If we already have a favicon url use the url as the cache key
        if let faviconURL = faviconURL {
            return faviconURL.absoluteString
        }

        guard let siteURL = siteURL else { return "" }

        // Always use the full site URL as the cache key for hero images
        if type == .heroImage {
            return siteURL.absoluteString
        }

        // For everything else use the domain as the key to avoid caching
        // and fetching unneccessary duplicates
        return siteURL.shortDomain ?? siteURL.shortDisplayString
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
            var faviconURLImageModel = imageModel
            if faviconURLImageModel.faviconURL == nil {
                // Try to fetch the favicon URL
                faviconURLImageModel = try await urlHandler.getFaviconURL(site: imageModel)
            }
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
