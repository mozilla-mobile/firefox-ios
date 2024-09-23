// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public protocol SiteImageHandler {
    func getImage(model: SiteImageModel) async -> UIImage
    func cacheFaviconURL(siteURL: URL, faviconURL: URL)
    func clearAllCaches()
}

public class DefaultSiteImageHandler: SiteImageHandler {
    private let urlHandler: FaviconURLHandler
    private let imageHandler: ImageHandler

    /// Right now, multiple `SiteImageView`s each have their own `DefaultSiteImageHandler`. Ideally they'd all share a
    /// reference to the same `DefaultSiteImageHandler` so we could properly queue and throttle requests to get favicon
    /// URLs, download images, etc. Since that's a large architectural change, for now lets use a static queue so we can
    /// prevent too many duplicate calls to remotely fetching URLs and images. (FXIOS-9830, revised FXIOS-9427 bugfix)
    private(set) static var requestQueue: [String: Task<UIImage, Never>] = [:]

    public static func factory() -> DefaultSiteImageHandler {
        return DefaultSiteImageHandler()
    }

    init(urlHandler: FaviconURLHandler = DefaultFaviconURLHandler(),
         imageHandler: ImageHandler = DefaultImageHandler()) {
        self.urlHandler = urlHandler
        self.imageHandler = imageHandler
    }

    public func getImage(model: SiteImageModel) async -> UIImage {
        switch model.imageType {
        case .heroImage:
            do {
                return try await getHeroImage(imageModel: model)
            } catch {
                // If hero image fails, we return a favicon image
                return await getFaviconImage(imageModel: model)
            }
        case .favicon:
            return await getFaviconImage(imageModel: model)
        }
    }

    public func cacheFaviconURL(siteURL: URL, faviconURL: URL) {
        let cacheKey = SiteImageModel.generateCacheKey(siteURL: siteURL, type: .favicon)
        urlHandler.cacheFaviconURL(cacheKey: cacheKey, faviconURL: faviconURL)
    }

    public func clearAllCaches() {
        urlHandler.clearCache()
        imageHandler.clearCache()
    }

    // MARK: - Private

    private func getHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        do {
            return try await imageHandler.fetchHeroImage(imageModel: imageModel)
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

            // Try to obtain the favicon URL if needed (ideally from cache, otherwise scrape the webpage)
            if faviconImageModel.siteResource == nil,
               let faviconURL = try? await urlHandler.getFaviconURL(model: imageModel) {
                faviconImageModel.siteResource = .remoteURL(url: faviconURL)
            }

            // If this resource is in the bundle (as with Home screen SuggestedSites), cache its associated URL. 
            // - Note:  This is a small optimization for when a SuggestedSite is actually visited and/or bookmarked by a user
            //           and the `SiteImageModel` isn't generated from a Home tile `Site` type.
            if case let .bundleAsset(_, resourceURL) = faviconImageModel.siteResource {
                urlHandler.cacheFaviconURL(cacheKey: faviconImageModel.cacheKey, faviconURL: resourceURL)
            }

            // Try to load the favicon image from the cache, or make a request to the favicon URL if it's not in the cache
            let icon = await imageHandler.fetchFavicon(imageModel: faviconImageModel)
            return icon
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
