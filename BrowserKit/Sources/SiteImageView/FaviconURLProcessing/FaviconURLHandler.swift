// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

protocol FaviconURLHandler {
    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel
}

struct DefaultFaviconURLHandler: FaviconURLHandler {
    private let urlFetcher: FaviconURLFetcher
    private let urlCache: FaviconURLCache

    init(urlFetcher: FaviconURLFetcher = DefaultFaviconURLFetcher(),
         urlCache: FaviconURLCache = DefaultFaviconURLCache.shared) {
        self.urlFetcher = urlFetcher
        self.urlCache = urlCache
    }

    func getFaviconURL(site: SiteImageModel) async throws -> SiteImageModel {
        // Don't fetch favicon URL if we don't have a URL or domain for it
        guard let siteURL = site.siteURL, let domain = site.domain else {
            throw SiteImageError.noFaviconURLFound
        }

        var imageModel = site
        do {
            let url = try await urlCache.getURLFromCache(domain: domain)
            imageModel.faviconURL = url
            return imageModel
        } catch {
            do {
                let url = try await urlFetcher.fetchFaviconURL(siteURL: siteURL)
                await urlCache.cacheURL(domain: domain, faviconURL: url)
                imageModel.faviconURL = url
                return imageModel
            } catch {
                throw SiteImageError.noFaviconURLFound
            }
        }
    }
}
