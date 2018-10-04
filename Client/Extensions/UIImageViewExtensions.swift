/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import SDWebImage
import Shared

public extension UIImageView {

    public func setIcon(_ icon: Favicon?, forURL url: URL?, completed completion: ((UIColor, URL?) -> Void)? = nil ) {
        func finish(filePath: String?, bgColor: UIColor) {
            if let filePath = filePath {
                self.image = UIImage(contentsOfFile: filePath)
            }
            // If the background color is clear, we may decide to set our own background based on the theme.
            let color = bgColor.components.alpha < 0.01 ? UIColor.theme.general.faviconBackground : bgColor
            self.backgroundColor = color
            completion?(color, url)
        }

        if let url = url, let defaultIcon = FaviconFetcher.getDefaultIconForURL(url: url) {
            finish(filePath: defaultIcon.url, bgColor: defaultIcon.color)
        } else {
            let imageURL = URL(string: icon?.url ?? "")
            let defaults = defaultFavicon(url)
            self.sd_setImage(with: imageURL, placeholderImage: defaults.image, options: []) {(img, err, _, _) in
                guard let image = img, let dUrl = url, err == nil else {
                    finish(filePath: nil, bgColor: defaults.color)
                    return
                }
                self.color(forImage: image, andURL: dUrl) { color in
                    finish(filePath: nil, bgColor: color)
                }
            }
        }
    }

   /*
    * Fetch a background color for a specfic favicon UIImage. It uses the URL to store the UIColor in memory for subsequent requests.
    */
    private func color(forImage image: UIImage, andURL url: URL, completed completionBlock: ((UIColor) -> Void)? = nil) {
        guard let domain = url.baseDomain else {
            self.backgroundColor = UIColor.Photon.Grey50
            completionBlock?(UIColor.Photon.Grey50)
            return
        }

        if let color = FaviconFetcher.colors[domain] {
            self.backgroundColor = color
            completionBlock?(color)
        } else {
            image.getColors(scaleDownSize: CGSize(width: 25, height: 25)) {colors in
                let isSame = [colors.primary, colors.secondary, colors.detail].every { $0 == colors.primary }
                if isSame {
                    completionBlock?(UIColor.Photon.White100)
                    FaviconFetcher.colors[domain] = UIColor.Photon.White100
                } else {
                    completionBlock?(colors.background)
                    FaviconFetcher.colors[domain] = colors.background
                }
            }
        }
    }

    public func setFavicon(forSite site: Site, onCompletion completionBlock: ((UIColor, URL?) -> Void)? = nil ) {
        self.setIcon(site.icon, forURL: site.tileURL, completed: completionBlock)
    }

    private func defaultFavicon(_ url: URL?) -> (image: UIImage, color: UIColor) {
        if let url = url {
            return (FaviconFetcher.getDefaultFavicon(url), FaviconFetcher.getDefaultColor(url))
        } else {
            return (FaviconFetcher.defaultFavicon, .white)
        }
    }
}

open class ImageOperation: NSObject, SDWebImageOperation {
    open var cacheOperation: Operation?

    var cancelled: Bool {
        return cacheOperation?.isCancelled ?? false
    }

    @objc open func cancel() {
        cacheOperation?.cancel()
    }
}

