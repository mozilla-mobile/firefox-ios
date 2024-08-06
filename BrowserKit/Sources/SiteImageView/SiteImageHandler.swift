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

    private let serialQueue = DispatchQueue(label: "com.mozilla.DefaultSiteImageHandler")
    private var _currentInFlightRequest: String?
    private var currentInFlightRequest: String? {
        get { return serialQueue.sync { _currentInFlightRequest } }
        set { serialQueue.sync { _currentInFlightRequest = newValue } }
    }

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
        if let siteURL = URL(string: site.siteURLString ?? "", invalidCharacters: false) {
            let domain = generateDomainURL(siteURL: siteURL)
            imageModel.siteURL = siteURL
            imageModel.domain = domain
        }

        imageModel.cacheKey = generateCacheKey(siteURL: URL(string: site.siteURLString ?? "", invalidCharacters: false),
                                               faviconURL: imageModel.faviconURL,
                                               type: imageModel.expectedImageType)

        switch site.expectedImageType {
        case .heroImage:
            do {
                imageModel.heroImage = try await getHeroImage(imageModel: imageModel)
            } catch {
                // If hero image fails, we return a favicon image
                imageModel.faviconImage = await getFaviconImage(imageModel: imageModel)
            }
        case .favicon:
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
        // and fetching unnecessary duplicates
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
            while let currentSiteRequest = currentInFlightRequest,
               imageModel.siteURLString == currentSiteRequest {
                // We are already processing a favicon request for this site
                // Sleep this task until the previous request is completed
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }

            currentInFlightRequest = imageModel.siteURLString
            var faviconURLImageModel = imageModel

            // Try to obtain the favicon URL if needed (ideally from cache, otherwise scrape the webpage)
            if faviconURLImageModel.faviconURL == nil {
                // Try to fetch the favicon URL
                faviconURLImageModel = try await urlHandler.getFaviconURL(site: imageModel)
            }

            // Try to load the favicon image from the cache, or make a request to the favicon URL if it's not in the cache
            let icon = await imageHandler.fetchFavicon(imageModel: faviconURLImageModel)
            currentInFlightRequest = nil
            return icon
        } catch {
            // If no favicon URL, generate favicon without it
            currentInFlightRequest = nil
            return await imageHandler.fetchFavicon(imageModel: imageModel)
        }
    }

    private func generateDomainURL(siteURL: URL) -> ImageDomain {
        let bundleDomains = BundleDomainBuilder().buildDomains(for: siteURL)
        return ImageDomain(bundleDomains: bundleDomains)
    }
}
