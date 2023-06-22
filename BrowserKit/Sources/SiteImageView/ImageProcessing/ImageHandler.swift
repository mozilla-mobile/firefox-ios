// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol ImageHandler {
    /// The ImageHandler will fetch the favicon with the following precedence:
    ///     1. Tries to fetch from the bundle.
    ///     2. Tries to fetch from the cache.
    ///     3. Tries to fetch from the favicon fetcher (from the web) if there's a URL. If there's no URL it fallbacks to the letter favicon.
    ///     4. When all fails it returns the letter favicon.
    ///
    /// Any time the favicon is fetched, it will be cache for future usage.
    ///
    /// - Parameters:
    ///   - imageURL: The image URL, can be nil if it could not be retrieved from the site
    ///   - domain: The domain this favicon will be associated with
    /// - Returns: The favicon image
    func fetchFavicon(site: SiteImageModel) async -> UIImage

    /// The ImageHandler will fetch the hero image with the following precedence
    ///     1. Tries to fetch from the cache.
    ///     2. Tries to fetch from the hero image fetcher (from the web).
    ///     3. If all fails it throws an error
    ///
    /// Any time the hero image  is fetched, it will be cache for future usage.
    /// - Parameters:
    ///   - siteURL: The site URL to fetch the hero image from
    ///   - domain: The domain this hero image will be associated with
    /// - Returns: The hero image
    func fetchHeroImage(site: SiteImageModel) async throws -> UIImage

    /// Clears the image cache
    func clearCache()
}

class DefaultImageHandler: ImageHandler {
    private let bundleImageFetcher: BundleImageFetcher
    private let imageCache: SiteImageCache
    private let faviconFetcher: FaviconFetcher
    private let letterImageGenerator: LetterImageGenerator
    private let heroImageFetcher: HeroImageFetcher

    init(bundleImageFetcher: BundleImageFetcher = DefaultBundleImageFetcher(),
         imageCache: SiteImageCache = DefaultSiteImageCache(),
         faviconFetcher: FaviconFetcher = DefaultFaviconFetcher(),
         letterImageGenerator: LetterImageGenerator = DefaultLetterImageGenerator(),
         heroImageFetcher: HeroImageFetcher = DefaultHeroImageFetcher()) {
        self.bundleImageFetcher = bundleImageFetcher
        self.imageCache = imageCache
        self.faviconFetcher = faviconFetcher
        self.letterImageGenerator = letterImageGenerator
        self.heroImageFetcher = heroImageFetcher
    }

    func fetchFavicon(site: SiteImageModel) async -> UIImage {
        do {
            return try bundleImageFetcher.getImageFromBundle(domain: site.domain)
        } catch {
            return await fetchFaviconFromCache(site: site)
        }
    }

    func fetchHeroImage(site: SiteImageModel) async throws -> UIImage {
        do {
            return try await imageCache.getImageFromCache(cacheKey: site.cacheKey, type: .heroImage)
        } catch {
            return try await fetchHeroImageFromFetcher(site: site)
        }
    }

    func clearCache() {
        Task {
            await self.imageCache.clearCache()
        }
    }

    // MARK: Private

    private func fetchFaviconFromCache(site: SiteImageModel) async -> UIImage {
        do {
            return try await imageCache.getImageFromCache(cacheKey: site.cacheKey, type: site.expectedImageType)
        } catch {
            return await fetchFaviconFromFetcher(site: site)
        }
    }

    private func fetchFaviconFromFetcher(site: SiteImageModel) async -> UIImage {
        do {
            guard let url = site.faviconURL else {
                return await fallbackToLetterFavicon(site: site)
            }

            let image = try await faviconFetcher.fetchFavicon(from: url)
            await imageCache.cacheImage(image: image, cacheKey: site.cacheKey, type: site.expectedImageType)
            return image
        } catch {
            return await fallbackToLetterFavicon(site: site)
        }
    }

    private func fetchHeroImageFromFetcher(site: SiteImageModel) async throws -> UIImage {
        guard let siteURL = site.siteURL else {
            throw SiteImageError.noHeroImage
        }
        do {
            let image = try await heroImageFetcher.fetchHeroImage(from: siteURL)
            await imageCache.cacheImage(image: image, cacheKey: site.cacheKey, type: .heroImage)
            return image
        } catch {
            throw SiteImageError.noHeroImage
        }
    }

    private func fallbackToLetterFavicon(site: SiteImageModel) async -> UIImage {
        do {
            let image = try await letterImageGenerator.generateLetterImage(siteString: site.cacheKey)
            await imageCache.cacheImage(image: image, cacheKey: site.cacheKey, type: site.expectedImageType)
            return image
        } catch {
            return UIImage(named: "globeLarge")?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        }
    }
}
