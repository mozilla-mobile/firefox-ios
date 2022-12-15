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
        do {
            let url = try await urlCache.getURLFromCache(domain: site.domain)
            return createSiteImageModel(site, faviconURL: url)
        } catch {
            do {
                let url = try await urlFetcher.fetchFaviconURL(siteURL: site.siteURL)
                await urlCache.cacheURL(domain: site.domain, faviconURL: url)
                return createSiteImageModel(site, faviconURL: url)
            } catch {
                throw SiteImageError.noFaviconURLFound
            }
        }
    }

    private func createSiteImageModel(_ site: SiteImageModel, faviconURL: URL) -> SiteImageModel {
        return SiteImageModel(id: site.id,
                              expectedImageType: site.expectedImageType,
                              siteURL: site.siteURL,
                              domain: site.domain,
                              faviconURL: faviconURL,
                              faviconImage: nil,
                              heroImage: nil)
    }
}
