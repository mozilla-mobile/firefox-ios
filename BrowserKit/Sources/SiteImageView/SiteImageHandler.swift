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

    /// Right now, multiple `SiteImageView`s each have their own `DefaultSiteImageHandler`. Ideally they'd all share a reference to
    /// the same `DefaultSiteImageHandler` so we could properly queue and throttle requests to get favicon URLs, download images,
    /// etc. Since that's a large architectural change, for now lets use a static queue so we can prevent too many duplicate calls to remotely fetching
    /// URLs and images. (FXIOS-9830, revised FXIOS-9427 bugfix)
    private(set) static var requestQueue: [String: Task<UIImage, Never>] = [:]

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

    // Note: Must be synchronized on an actor to avoid crashes (managing the activeRequest queue).
    @MainActor
    private func getFaviconImage(imageModel: SiteImageModel) async -> UIImage {
        // Check if we're already awaiting a request to get the favicon image for this cacheKey.
        // If so, simply await that request rather than begin a new one.
        let requestKey = imageModel.cacheKey
        if let activeRequest = DefaultSiteImageHandler.requestQueue[requestKey] {
            return await activeRequest.value
        }

        let requestHandle = Task {
            var faviconImageModel = imageModel

            do {
                if faviconImageModel.faviconURL == nil {
                    // Try to obtain the favicon URL if needed (ideally from cache, otherwise scrape the webpage)
                    faviconImageModel = try await urlHandler.getFaviconURL(site: imageModel)
                }

                // Try to load the favicon image from the cache, or make a request to the favicon URL
                // if it's not in the cache
                let icon = await imageHandler.fetchFavicon(site: faviconImageModel)
                return icon
            } catch {
                // If no favicon URL, generate favicon without it
                let letter = await imageHandler.fetchFavicon(site: imageModel)
                return letter
            }
        }

        DefaultSiteImageHandler.requestQueue[requestKey] = requestHandle
        let image = await requestHandle.value
        DefaultSiteImageHandler.requestQueue[requestKey] = nil
        return image
    }

    private func generateDomainURL(siteURL: URL) -> ImageDomain {
        let bundleDomains = BundleDomainBuilder().buildDomains(for: siteURL)
        return ImageDomain(bundleDomains: bundleDomains)
    }
}
