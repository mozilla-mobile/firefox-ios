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

    private let serialQueue = DispatchQueue(label: "com.mozilla.DefaultSiteImageHandler")
    private var _currentInFlightRequest: URL?
    private var currentInFlightRequest: URL? {
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
            return await getFaviconImage(imageModel: model) // FIXME [fire 1]
        }
    }

    public func cacheFaviconURL(siteURL: URL, faviconURL: URL) {
        // Note: We do NOT want to cache by the faviconURL FIXME
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

    private func getFaviconImage(imageModel: SiteImageModel) async -> UIImage {
        do {
            while let currentSiteRequest = currentInFlightRequest,
                  imageModel.siteURL == currentSiteRequest {
                // We are already processing a favicon request for this site
                // Sleep this task until the previous request is completed
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }

            currentInFlightRequest = imageModel.siteURL
            var faviconImageModel: SiteImageModel = imageModel

            if imageModel.resourceURL == nil {
                // Try to obtain the favicon URL if needed (ideally from cache, otherwise scrape the webpage)
                let resourceURL = try await urlHandler.getFaviconURL(model: imageModel)
                faviconImageModel = SiteImageModel(siteImageModel: imageModel, resourceURL: resourceURL)
            }

            // Try to load the favicon image from the cache, or make a request to the favicon URL if it's not in the cache
            let icon = await imageHandler.fetchFavicon(imageModel: faviconImageModel)
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
