// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import LinkPresentation
import Shared
import Storage

enum SiteImageType: Int {
    case heroImage = 0, favicon

    func peek() -> Self? {
        return SiteImageType(rawValue: rawValue + 1)
    }

    mutating func next() -> Self? {
        return SiteImageType(rawValue: rawValue + 1)
    }
}

/// A helper that'll fetch an image, and fallback to other image options if specified.
class SiteImageHelper {

    private static let cache = NSCache<NSString, UIImage>()
    private let throttler = Throttler(seconds: 0.5, on: .main)
    private let faviconFetcher: Favicons

    convenience init(profile: Profile) {
        self.init(faviconFetcher: profile.favicons)
    }

    init(faviconFetcher: Favicons) {
        self.faviconFetcher = faviconFetcher
    }

    /// Given a `Site`, this will fetch the type of image you're looking for while allowing you to fallback to the next `SiteImageType`.
    /// - Parameters:
    ///   - url: The site to fetch an image from.
    ///   - imageType: The `SiteImageType` that will work for you.
    ///   - shouldFallback: Allow a fallback image to be given in the case where the `SiteImageType` you specify is not available.
    ///   - metadataProvider: Metadata provider for hero image type. Default is normally used, replaced in case of tests
    ///   - completion: Work to be done after fetching an image, ideally done on the main thread.
    /// - Returns: A UIImage.
    func fetchImageFor(site: Site,
                       imageType: SiteImageType,
                       shouldFallback: Bool,
                       metadataProvider: LPMetadataProvider = LPMetadataProvider(),
                       completion: @escaping (UIImage?) -> ()) {
        var didCompleteFetch = false
        var imageType = imageType

        switch imageType {
        case .heroImage:
            fetchHeroImage(for: site, metadataProvider: metadataProvider) { image, result in
                guard let heroImage = image else { return }
                didCompleteFetch = result ?? false
                DispatchQueue.main.async {
                    completion(heroImage)
                    return
                }
            }
        case .favicon:
            fetchFavicon(for: site) { image, result in
                guard let favicon = image else { return }
                didCompleteFetch = result ?? false
                DispatchQueue.main.async {
                    completion(favicon)
                    return
                }
            }
        }

        throttler.throttle { [weak self] in
            if !didCompleteFetch && imageType.peek() != nil,
               let updatedImageType = imageType.next(), shouldFallback {
                self?.fetchImageFor(site: site,
                                    imageType: updatedImageType,
                                    shouldFallback: shouldFallback,
                                    completion: completion)
            } else { return }
        }
    }

    static func clearCacheData() {
        SiteImageHelper.cache.removeAllObjects()
    }

    // MARK: - Private

    private func fetchHeroImage(for site: Site, metadataProvider: LPMetadataProvider, completion: @escaping (UIImage?, Bool?) -> ()) {
        let heroImageCacheKey = NSString(string: "\(site.url)\(SiteImageType.heroImage.rawValue)")

        // Fetch from cache, if not then fetch with LPMetadataProvider
        if let cachedImage = SiteImageHelper.cache.object(forKey: heroImageCacheKey) {
            completion(cachedImage, true)

        } else {
            guard let url = URL(string: site.url) else {
                completion(nil, false)
                return
            }

            fetchFromMetaDataProvider(heroImageCacheKey: heroImageCacheKey,
                                      url: url,
                                      metadataProvider: metadataProvider,
                                      completion: completion)
        }
    }

    private func fetchFromMetaDataProvider(heroImageCacheKey: NSString,
                                           url: URL,
                                           metadataProvider: LPMetadataProvider,
                                           completion: @escaping (UIImage?, Bool?) -> ()) {

        metadataProvider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata = metadata, let imageProvider = metadata.imageProvider, error == nil else {
                completion(nil, false)
                return
            }

            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard error == nil, let image = image as? UIImage else {
                    completion(nil, false)
                    return
                }

                SiteImageHelper.cache.setObject(image, forKey: heroImageCacheKey)
                completion(image, true)
            }
        }
    }

    private func fetchFavicon(for site: Site, completion: @escaping (UIImage?, Bool?) -> ()) {
        let faviconCacheKey = NSString(string: "\(site.url)\(SiteImageType.favicon.rawValue)")

        // Fetch from cache, if not then fetch from profile
        if let cachedImage = SiteImageHelper.cache.object(forKey: faviconCacheKey) {
            completion(cachedImage, true)
        } else {
            faviconFetcher.getFaviconImage(forSite: site).uponQueue(.main, block: { result in
                guard let image = result.successValue else { return }
                SiteImageHelper.cache.setObject(image, forKey: faviconCacheKey)
                completion(image, true)
            })
        }
    }
}
