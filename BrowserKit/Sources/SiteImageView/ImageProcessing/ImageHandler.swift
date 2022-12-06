// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

protocol ImageHandler {
    func fetchFavicon(imageURL: URL?, domain: String) async throws -> UIImage
    func fetchHeroImage(siteURL: URL, domain: String) async throws -> UIImage
}

class DefaultImageHandler: ImageHandler {

    private let bundleImageFetcher: BundleImageFetcher
    private let imageCache: SiteImageCache
    private let imageFetcher: SiteImageFetcher
    private let letterImageGenerator: LetterImageGenerator
    private let heroImageFetcher: HeroImageFetcher

    init(bundleImageFetcher: BundleImageFetcher = DefaultBundleImageFetcher(),
         imageCache: SiteImageCache = DefaultSiteImageCache(),
         imageFetcher: SiteImageFetcher = DefaultSiteImageFetcher(),
         letterImageGenerator: LetterImageGenerator = DefaultLetterImageGenerator(),
         heroImageFetcher: HeroImageFetcher = DefaultHeroImageFetcher()) {
        self.bundleImageFetcher = bundleImageFetcher
        self.imageCache = imageCache
        self.imageFetcher = imageFetcher
        self.letterImageGenerator = letterImageGenerator
        self.heroImageFetcher = heroImageFetcher
    }

    func fetchFavicon(imageURL: URL?, domain: String) async throws -> UIImage {
        do {
            return try bundleImageFetcher.getImageFromBundle(domain: domain)

        } catch is BundleError {
            return try await imageCache.getImageFromCache(domain: domain, type: .favicon)

        } catch SiteImageError.unableToRetrieveFromCache {
            guard let url = imageURL else {
                return await fallbackLetterFavicon(domain: domain)
            }

            let image = try await imageFetcher.fetchImage(from: url)
            await imageCache.cacheImage(image: image, domain: domain, type: .favicon)
            return image

        } catch {
            return await fallbackLetterFavicon(domain: domain)
        }
    }

    // If we have no image URL or all other method fails, then use the letter favicon
    private func fallbackLetterFavicon(domain: String) async -> UIImage {
        let image = letterImageGenerator.generateLetterImage(domain: domain)
        await imageCache.cacheImage(image: image, domain: domain, type: .favicon)
        return image
    }

    func fetchHeroImage(siteURL: URL, domain: String) async throws -> UIImage {
        do {
            return try await imageCache.getImageFromCache(domain: domain, type: .heroImage)

        } catch SiteImageError.unableToRetrieveFromCache {
            let image = try await heroImageFetcher.fetchHeroImage(from: siteURL)
            await imageCache.cacheImage(image: image, domain: domain, type: .heroImage)
            return image

        } catch {
            throw SiteImageError.noHeroImage
        }
    }
}
