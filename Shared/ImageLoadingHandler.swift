// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Kingfisher
import UIKit

public enum ImageLoadingError: Error, CustomStringConvertible {
    case unableToFetchImage
    case iconUrlNotFound
    case sizeTooLarge

    public var description: String {
        switch self {
        case .unableToFetchImage: return "Favicon Image Error: Unable to fetch image"
        case .iconUrlNotFound: return "Facicon url not found"
        case .sizeTooLarge: return "Image download size too large"
        }
    }
}

public struct ImageLoadingConstants {
    public static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit
    public static let ExpirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    public static let NoLimitImageSize = 0 // 0 Means there is no limit for image size
}

protocol ImageFetcher {
    func getImageFromCacheOrDownload(with url: URL, limit maxSize: Int,
                                     completion: @escaping (UIImage?, ImageLoadingError?) -> Void)
    func saveImageToCache(img: UIImage, key: String)
    func getImageFromCache(url: URL,
                           completion: @escaping (UIImage?, ImageLoadingError?) -> Void)
    func isImageInCache(url: URL) -> Bool
    func downloadImageOnly(with url: URL,
                           limit maxSize: Int,
                           completion: @escaping (UIImage?, Data?, ImageLoadingError?) -> Void)
    func downloadAndCacheImageWithAuthentication(with url: URL,
                                                 completion: @escaping (UIImage?, ImageLoadingError?) -> Void)
}

public class ImageLoadingHandler: ImageFetcher {

    // MARK: singleton property
    public static let shared = ImageLoadingHandler()

    public var disposition: URLSession.AuthChallengeDisposition = .useCredential
    public var credential: URLCredential?

    public init() {}

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

    public func downloadAndCacheImageWithAuthentication(with url: URL,
                                                        completion: @escaping (UIImage?, ImageLoadingError?) -> Void) {
        let imageDownloader = ImageDownloader.default
        imageDownloader.authenticationChallengeResponder = self
        imageDownloader.downloadImage(with: url, options: nil) {  [unowned self] result in
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

extension ImageLoadingHandler: AuthenticationChallengeResponsible {

    public func downloader( _ downloader: ImageDownloader,
                            didReceive challenge: URLAuthenticationChallenge,
                            completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Provide `AuthChallengeDisposition` and `URLCredential`
        completionHandler(disposition, credential)
    }

    public func downloader( _ downloader: ImageDownloader, task: URLSessionTask,
                            didReceive challenge: URLAuthenticationChallenge,
                            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Provide `AuthChallengeDisposition` and `URLCredential`
        completionHandler(disposition, credential)
    }
}
