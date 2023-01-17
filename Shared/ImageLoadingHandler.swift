// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Kingfisher
import UIKit

public enum ImageLoadingError: Error, CustomStringConvertible {
    case unableToFetchImage
    case sizeTooLarge

    public var description: String {
        switch self {
        case .unableToFetchImage: return "Favicon Image Error: Unable to fetch image"
        case .sizeTooLarge: return "Image download size too large"
        }
    }
}

public struct ImageLoadingConstants {
    public static let NoLimitImageSize = 0 // 0 Means there is no limit for image size
}

protocol ImageLoadingHandler {
    func getImageFromCacheOrDownload(with url: URL, limit maxSize: Int,
                                     completion: @escaping (UIImage?, ImageLoadingError?) -> Void)
    func saveImageToCache(img: UIImage, key: String)
    func getImageFromCache(url: URL,
                           completion: @escaping (UIImage?, ImageLoadingError?) -> Void)
    func isImageInCache(url: URL) -> Bool
    func downloadImageOnly(with url: URL,
                           limit maxSize: Int,
                           completion: @escaping (UIImage?, Data?, ImageLoadingError?) -> Void)
}

/// Useful to load random images into the project. For Favicons or hero images please use SiteImageView from BrowserKit.
public class DefaultImageLoadingHandler: ImageLoadingHandler {
    public static let shared = DefaultImageLoadingHandler()

    public var disposition: URLSession.AuthChallengeDisposition = .useCredential
    public var credential: URLCredential?

    public func getImageFromCacheOrDownload(with url: URL, limit maxSize: Int,
                                            completion: @escaping (UIImage?, ImageLoadingError?) -> Void) {
        // Check if image is in cache
        guard isImageInCache(url: url) else {
            // Download image as its not in cache
            downloadImageOnly(with: url, limit: maxSize) { [unowned self] image, _, error in
                completion(image, error)
                guard error == nil, let image = image else { return }
                // cache downloaded image for future
                self.saveImageToCache(img: image, key: url.absoluteString)
            }

            return
        }

        getImageFromCache(url: url, completion: completion)
    }

    public func saveImageToCache(img: UIImage, key: String) {
        ImageCache.default.store(img, forKey: key)
    }

    public func getImageFromCache(url: URL, completion: @escaping (UIImage?, ImageLoadingError?) -> Void) {
        ImageCache.default.retrieveImage(forKey: url.absoluteString) { result in
            switch result {
            case .success(let value):
                completion(value.image, nil)
            case .failure:
                completion(nil, ImageLoadingError.unableToFetchImage)
            }
        }
    }

    public func isImageInCache(url: URL) -> Bool {
        return ImageCache.default.isCached(forKey: url.absoluteString)
    }

    public func downloadAndCacheImage(with url: URL, completion: @escaping (UIImage?, ImageLoadingError?) -> Void) {
        let imageDownloader = ImageDownloader.default
        imageDownloader.downloadImage(with: url, options: nil) { [unowned self] result in
            switch result {
            case .success(let value):
                self.saveImageToCache(img: value.image, key: url.absoluteString)
                completion(value.image, nil)
            case .failure:
                completion(nil, ImageLoadingError.unableToFetchImage)
            }
        }
    }

    public func downloadImageOnly(with url: URL, limit maxSize: Int,
                                  completion: @escaping (UIImage?, Data?, ImageLoadingError?) -> Void) {
        let imgDownloader = ImageDownloader.default
        var onProgress: DownloadProgressBlock?

        // Progress is only set for size greater than 0
        if maxSize > 0 {
            onProgress = {
                receivedSize, totalSize in
                if receivedSize > maxSize ||
                    totalSize > maxSize {
                    imgDownloader.cancel(url: url)
                    completion(nil, nil, ImageLoadingError.sizeTooLarge)
                }
            }
        }

        imgDownloader.downloadImage(with: url, options: nil, progressBlock: onProgress) {
            result in
            switch result {
            case .success(let value):
                completion(value.image, value.originalData, nil)
            case .failure:
                completion(nil, nil, ImageLoadingError.unableToFetchImage)
            }
        }
    }
}
