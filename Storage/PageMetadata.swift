/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SDWebImage

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

        if let mediaURL = mediaURL, let url = URL(string: mediaURL), cacheImages {
            self.cacheImage(fromDataURI: mediaDataURI, forURL: url)
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

    fileprivate func cacheImage(fromDataURI dataURI: String?, forURL url: URL) {
        let webimage = SDWebImageManager.shared()

        func cacheUsingURLOnly() {
            webimage.cachedImageExists(for: url) { exists in
                if !exists {
                    self.downloadAndCache(fromURL: url)
                }
            }
        }

        guard let dataURI = dataURI, let dataURL = URL(string: dataURI) else {
            cacheUsingURLOnly()
            return
        }

        webimage.cachedImageExists(for: dataURL) { exists in
            if let data = try? Data(contentsOf: dataURL), let image = UIImage(data: data), !exists {
                self.cache(image: image, forURL: url)
            } else {
                cacheUsingURLOnly()
            }
        }
    }

    fileprivate func downloadAndCache(fromURL webUrl: URL) {
        let webimage = SDWebImageManager.shared()
        webimage.loadImage(with: webUrl, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
            if let image = image {
                self.cache(image: image, forURL: webUrl)
            }
        }
    }

    fileprivate func cache(image: UIImage, forURL url: URL) {
        let imageManager = SDWebImageManager.shared()
        imageManager.saveImage(toCache: image, for: url)
    }
}
