/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebImage

enum MetadataKeys: String {
    case imageURL = "image_url"
    case imageDataURI = "image_data_uri"
    case pageURL = "url"
    case title = "title"
    case description = "description"
    case type = "type"
    case provider = "provider"
}

/*
 * Value types representing a page's metadata
 */
public struct PageMetadata {
    public let id: Int?
    public let siteURL: String
    public let mediaURL: String?
    public let title: String?
    public let description: String?
    public let type: String?
    public let providerName: String?

    public init(id: Int?, siteURL: String, mediaURL: String?, title: String?, description: String?, type: String?, providerName: String?, mediaDataURI: String?, cacheImages: Bool = true) {
        self.id = id
        self.siteURL = siteURL
        self.mediaURL = mediaURL
        self.title = title
        self.description = description
        self.type = type
        self.providerName = providerName

        if cacheImages {
            self.cacheImage(fromDataURI: mediaDataURI, forURL: mediaURL)
        }
    }

    public static func fromDictionary(_ dict: [String: Any]) -> PageMetadata? {
        guard let siteURL = dict[MetadataKeys.pageURL.rawValue] as? String else {
            return nil
        }

        return PageMetadata(id: nil, siteURL: siteURL, mediaURL: dict[MetadataKeys.imageURL.rawValue] as? String,
                            title: dict[MetadataKeys.title.rawValue] as? String, description: dict[MetadataKeys.description.rawValue] as? String,
                            type: dict[MetadataKeys.type.rawValue] as? String, providerName: dict[MetadataKeys.provider.rawValue] as? String, mediaDataURI: dict[MetadataKeys.imageDataURI.rawValue] as? String)
    }

    fileprivate func cacheImage(fromDataURI dataURI: String?, forURL urlString: String?) {
        if let urlString = urlString,
            let url = URL(string: urlString) {
            if let dataURI = dataURI,
                let dataURL = URL(string: dataURI),
                !SDWebImageManager.shared().cachedImageExists(for: dataURL),
                let data = try? Data(contentsOf: dataURL),
                let image = UIImage(data: data) {

                self.cache(image: image, forURL: url)
            } else if !SDWebImageManager.shared().cachedImageExists(for: url) {
                // download image direct from URL
                self.downloadAndCache(fromURL: url)
            }
        }
    }

    fileprivate func downloadAndCache(fromURL webUrl: URL) {
        let imageManager = SDWebImageManager.shared()
        _ = imageManager?.downloadImage(with: webUrl, options: SDWebImageOptions.continueInBackground, progress: nil) { (image, error, cacheType, success, url) in
            guard let image = image else {
                return
            }
            self.cache(image: image, forURL: webUrl)
        }
    }

    fileprivate func cache(image: UIImage, forURL url: URL) {
        let imageManager = SDWebImageManager.shared()
        imageManager?.saveImage(toCache: image, for: url)
    }
}
