// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FaviconURLHandler {
    func getFaviconURL(model: SiteImageModel) async throws -> URL
    func cacheFaviconURL(cacheKey: String, faviconURL: URL)
    func clearCache()
}

struct DefaultFaviconURLHandler: FaviconURLHandler {
    private let urlFetcher: FaviconURLFetcher
    private let urlCache: FaviconURLCache

    init(urlFetcher: FaviconURLFetcher = DefaultFaviconURLFetcher(),
         urlCache: FaviconURLCache = DefaultFaviconURLCache.shared) {
        self.urlFetcher = urlFetcher
        self.urlCache = urlCache
    }

    /// Attempts to get the favicon URL associated with this site. First checks the URL cache. If the URL can't be obtained
    /// from the cache, then a network request is made to hopefully scrape the favicon URL from a webpage's metadata.
    /// **Note**: This is a slow call when the URL is not cached.
    func getFaviconURL(model: SiteImageModel) async throws -> URL {
        guard model.siteURL.scheme != "internal" else {
            // For internal URLs, skip trying to fetch a faviconURL (result in `"unsupported URL"` network errors)
            throw SiteImageError.noFaviconFound
        }

        do {
            let url = try await urlCache.getURLFromCache(cacheKey: model.cacheKey)
            return url
        } catch {
            do {
                let url = try await urlFetcher.fetchFaviconURL(siteURL: model.siteURL) // Slow call
                await urlCache.cacheURL(cacheKey: model.cacheKey, faviconURL: url)
                return url
            } catch {
                throw SiteImageError.noFaviconURLFound
            }
        }
    }

    func cacheFaviconURL(cacheKey: String, faviconURL: URL) {
        Task {
            await urlCache.cacheURL(cacheKey: cacheKey, faviconURL: faviconURL)
        }
    }

    func clearCache() {
        Task {
            await urlCache.clearCache()
        }
    }
}
