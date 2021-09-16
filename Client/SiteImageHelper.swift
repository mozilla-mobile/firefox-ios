/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import LinkPresentation

/// If a site follows the open graph protocol, this class can help you extract the object's title, type, image and canonical URL.
/// For more information, see https://ogp.me.
class OpenGraphProtocolHelper {
    private static let cache = NSCache<NSString, UIImage>()

    /// Given a URL, this can help you fetch a "hero" image if one exists for it.
    /// - Parameter url: The site to fetch an image from.
    /// - Returns: A "hero" image, if one exists.
    static func fetchHeroImage(for url: URL, completion: @escaping (UIImage?) -> ()) {
        let linkPresentationProvider = LPMetadataProvider()

        let heroImageCacheKey = NSString(string: url.absoluteString)
        if let image = cache.object(forKey: heroImageCacheKey) { DispatchQueue.main.async { completion(image) } }

        linkPresentationProvider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata = metadata,
                  let imageProvider = metadata.imageProvider,
                  error == nil else { return }

            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard error == nil, let image = image as? UIImage else { return }
                cache.setObject(image, forKey: heroImageCacheKey)
                DispatchQueue.main.async { completion(image) }
            }
        }
    }
}

enum SiteImageType {
    case HeroImage
    case Screenshot
    case Favicon
    case LocalImage
}

/// A helper that'll fetch an image, and fallback to other image options if specified.
class SiteImageHelper {
    
    /// Cache images based on `SiteImageType`
    private static let cache = NSCache<NSString, UIImage>()
    
    /// Given a `URL`, this will fetch the type of image you're looking for while allowing you to fallback to the next `SiteImageType`.
    /// - Parameters:
    ///   - url: The site to fetch an image from.
    ///   - imageType: The `SiteImageType` that will work for you.
    ///   - fallback: Allow a fallback image to be given in the case where the `SiteImageType` you specify is not available.
    ///   - completion: Work to be done after fetching an image, done on the main thread.
    /// - Returns: A UIImage, to be used on the main thread in a completion.
    static func fetchSiteImage(url: URL, imageType: SiteImageType, fallback: Bool, completion: @escaping (UIImage?) -> ()) {
        switch imageType {
        case .HeroImage:
            fetchHeroImage(for: url, completion: completion)
        default:
            break
        }
    }
    
    static func fetchHeroImage(for url: URL, completion: @escaping (UIImage?) -> ()) {
        let linkPresentationProvider = LPMetadataProvider()

        let heroImageCacheKey = NSString(string: url.absoluteString)
        if let image = cache.object(forKey: heroImageCacheKey) { DispatchQueue.main.async { completion(image) } }

        linkPresentationProvider.startFetchingMetadata(for: url) { metadata, error in
            guard let metadata = metadata,
                  let imageProvider = metadata.imageProvider,
                  error == nil else { return }

            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard error == nil, let image = image as? UIImage else { return }
                cache.setObject(image, forKey: heroImageCacheKey)
                DispatchQueue.main.async { completion(image) }
            }
        }
    }
}
