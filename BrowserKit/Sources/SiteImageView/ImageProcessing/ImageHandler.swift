// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol ImageHandler {
    /// The ImageHandler will fetch the favicon with the following precedence:
    ///     1. Tries to fetch from the cache.
    ///     2. Tries to fetch from the favicon fetcher (from the web) if there's a URL.
    ///        If there's no URL it fallbacks to the letter favicon.
    ///     3. When all fails it returns the letter favicon.
    ///
    /// Any time the favicon is fetched, it will be cache for future usage.
    ///
    /// - Parameters:
    ///   - imageURL: The image URL, can be nil if it could not be retrieved from the site
    ///   - domain: The domain this favicon will be associated with
    /// - Returns: The favicon image
    func fetchFavicon(imageModel: SiteImageModel) async -> UIImage

    /// The ImageHandler will fetch the hero image with the following precedence
    ///     1. Tries to fetch from the cache.
    ///     2. Tries to fetch from the hero image fetcher (from the web).
    ///     3. If all fails it throws an error
    ///
    /// Any time the hero image is fetched, it will be cached for future use.
    /// - Parameters:
    ///   - siteURL: The site URL to fetch the hero image from
    ///   - domain: The domain this hero image will be associated with
    /// - Returns: The hero image
    func fetchHeroImage(imageModel: SiteImageModel) async throws -> UIImage

    /// Clears the image cache
    func clearCache()
}

class DefaultImageHandler: ImageHandler {
    private let imageCache: SiteImageCache
    private let faviconFetcher: FaviconFetcher
    private let letterImageGenerator: LetterImageGenerator
    private let heroImageFetcher: HeroImageFetcher

    init(imageCache: SiteImageCache = DefaultSiteImageCache(),
         faviconFetcher: FaviconFetcher = DefaultFaviconFetcher(),
         letterImageGenerator: LetterImageGenerator = DefaultLetterImageGenerator(),
         heroImageFetcher: HeroImageFetcher = DefaultHeroImageFetcher()) {
        self.imageCache = imageCache
        self.faviconFetcher = faviconFetcher
        self.letterImageGenerator = letterImageGenerator
        self.heroImageFetcher = heroImageFetcher
    }

    func fetchFavicon(imageModel: SiteImageModel) async -> UIImage {
        do {
            return try await imageCache.getImageFromCache(cacheKey: imageModel.cacheKey, type: imageModel.expectedImageType)
        } catch {
            return await fetchFaviconFromFetcher(imageModel: imageModel)
        }
    }

    func fetchHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        do {
            return try await imageCache.getImageFromCache(cacheKey: imageModel.cacheKey, type: .heroImage)
        } catch {
            return try await fetchHeroImageFromFetcher(imageModel: imageModel)
        }
    }

    func clearCache() {
        Task {
            await self.imageCache.clearCache()
        }
    }

    // MARK: Private

    private func fetchFaviconFromFetcher(imageModel: SiteImageModel) async -> UIImage {
        do {
            guard let url = imageModel.faviconURL else {
                return await fallbackToLetterFavicon(imageModel: imageModel)
            }

            let image = try await faviconFetcher.fetchFavicon(from: url)
            await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: imageModel.expectedImageType)
            return image
        } catch {
            return await fallbackToLetterFavicon(imageModel: imageModel)
        }
    }

    private func fetchHeroImageFromFetcher(imageModel: SiteImageModel) async throws -> UIImage {
        guard let siteURL = imageModel.siteURL else {
            throw SiteImageError.noHeroImage
        }
        do {
            let image = try await heroImageFetcher.fetchHeroImage(from: siteURL)
            await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: .heroImage)
            return image
        } catch {
            throw SiteImageError.noHeroImage
        }
    }

    private func fallbackToLetterFavicon(imageModel: SiteImageModel) async -> UIImage {
        do {
            let image = try await letterImageGenerator.generateLetterImage(siteString: imageModel.cacheKey)
            await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: imageModel.expectedImageType)
            return image
        } catch {
            return UIImage(named: "globeLarge")?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        }
    }
}
