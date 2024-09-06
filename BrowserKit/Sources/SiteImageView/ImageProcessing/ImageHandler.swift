// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol ImageHandler {
    /// The ImageHandler will fetch the favicon with the following precedence:
    ///     1. Tries to fetch from the cache.
    ///     2. If there is a URL, tries to fetch from the web.
    ///     3. When all fails, returns the letter favicon.
    ///
    /// Any time a favicon is fetched, it will be cached for future usage.
    /// - Parameters:
    ///   - imageModel: The image URL, can be nil if it could not be retrieved from the site
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
            // If this is one of our special bundled favicons, simply return it from the bundle
            if case let .bundleAsset(assetName, _) = imageModel.siteResource {
                return try getBundleImage(assetName: assetName)
            }

            return try await imageCache.getImage(cacheKey: imageModel.cacheKey, type: imageModel.imageType)
        } catch {
            return await fetchFaviconFromFetcher(imageModel: imageModel)
        }
    }

    func fetchHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        do {
            return try await imageCache.getImage(cacheKey: imageModel.cacheKey, type: imageModel.imageType)
        } catch {
            return try await fetchHeroImageFromFetcher(imageModel: imageModel)
        }
    }

    func clearCache() {
        Task {
            await self.imageCache.clear()
        }
    }

    // MARK: Private

    private func fetchFaviconFromFetcher(imageModel: SiteImageModel) async -> UIImage {
        do {
            guard let resourceType = imageModel.siteResource else {
                throw SiteImageError.noFaviconURLFound
            }
            switch resourceType {
            case .bundleAsset(let assetName, _):
                assertionFailure("You shouldn't be trying to fetch a bundled asset image! \(assetName)")
                return try getBundleImage(assetName: assetName)
            case .remoteURL(let faviconURL):

                let image = try await faviconFetcher.fetchFavicon(from: faviconURL)
                await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: imageModel.imageType)
                return image
            }
        } catch {
            return await fallbackToLetterFavicon(imageModel: imageModel)
        }
    }

    private func fetchHeroImageFromFetcher(imageModel: SiteImageModel) async throws -> UIImage {
        do {
            let image = try await heroImageFetcher.fetchHeroImage(from: imageModel.siteURL)
            await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: .heroImage)
            return image
        } catch {
            throw SiteImageError.noHeroImage
        }
    }

    private func fallbackToLetterFavicon(imageModel: SiteImageModel) async -> UIImage {
        do {
            var siteString = imageModel.cacheKey
            if imageModel.siteURL.scheme == "internal", imageModel.siteURL.lastPathComponent == "home" {
                // We should use an "H" letter favicon for the home page with internal URL `internal://local/about/home`,
                // not an "L" from the "local" shortDomain.
                siteString = "home"
            }

            let image = try await letterImageGenerator.generateLetterImage(siteString: siteString)
            // FIXME Do we really want to cache letter icons and never attempt to get a favicon again?
            //       We can drop into here on a network timeout.
            await imageCache.cacheImage(image: image, cacheKey: imageModel.cacheKey, type: imageModel.imageType)
            return image
        } catch {
            return UIImage(named: "globeLarge")?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        }
    }

    private func getBundleImage(assetName: String) throws -> UIImage {
        guard let image = UIImage(named: assetName) else {
            throw SiteImageError.noImageInBundle
        }
        return image
    }
}
