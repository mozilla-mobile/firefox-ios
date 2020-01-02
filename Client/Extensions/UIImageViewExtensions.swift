/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import SDWebImage
import Shared

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

public extension UIImageView {

    func setImageAndBackground(forIcon icon: Favicon?, website: URL?, completion: @escaping () -> Void) {
        func finish(bgColor: UIColor) {
            // If the background color is clear, we may decide to set our own background based on the theme.
            let color = bgColor.components.alpha < 0.01 ? UIColor.theme.general.faviconBackground : bgColor
            self.backgroundColor = color
            completion()
        }

        sd_setImage(with: nil) // cancels any pending SDWebImage operations.

        if let url = website, let bundledIcon = FaviconFetcher.getBundledIcon(forUrl: url) {
            self.image = UIImage(contentsOfFile: bundledIcon.filePath)
            finish(bgColor: bundledIcon.bgcolor)
        } else {
            let imageURL = URL(string: icon?.url ?? "")
            let defaults = defaultFavicon(website)
            self.sd_setImage(with: imageURL, placeholderImage: defaults.image, options: []) {(img, err, _, _) in
                guard let image = img, let url = website, err == nil else {
                    finish(bgColor: defaults.color)
                    return
                }
                self.color(forImage: image, andURL: url) { color in
                    finish(bgColor: color)
                }
            }
        }
    }

   /*
    * Fetch a background color for a specfic favicon UIImage. It uses the URL to store the UIColor in memory for subsequent requests.
    */
    private func color(forImage image: UIImage, andURL url: URL, completed completionBlock: ((UIColor) -> Void)? = nil) {
        let domain = url.domainURL.absoluteString
        if let color = FaviconFetcher.colors[domain] {
            self.backgroundColor = color
            completionBlock?(color)
        } else {
            completionBlock?(UIColor.Photon.White100)
            FaviconFetcher.colors[domain] = UIColor.Photon.White100
        }
    }

    func setFavicon(forSite site: Site, completion: @escaping () -> Void ) {
        setImageAndBackground(forIcon: site.icon, website: site.tileURL, completion: completion)
    }
    
   /*
    * If the webpage has low-res favicon, use defaultFavIcon
    */
    func setFaviconOrDefaultIcon(forSite site: Site, completion: @escaping () -> Void ) {
        setImageAndBackground(forIcon: site.icon, website: site.tileURL) {
            if let defaults = self.defaultIconIfNeeded(site.tileURL) {
                self.image = defaults.image
                self.backgroundColor = defaults.color
            }
            completion()
        }
    }

    private func defaultFavicon(_ url: URL?) -> (image: UIImage, color: UIColor) {
        if let url = url {
            return (FaviconFetcher.getDefaultFavicon(url), FaviconFetcher.getDefaultColor(url))
        } else {
            return (FaviconFetcher.defaultFavicon, .white)
        }
    }
    
    private func defaultIconIfNeeded(_ url: URL?) -> (image: UIImage, color: UIColor)? {
        if let image = image, let url = url, image.size.width < 32 || image.size.height < 32 {
            let defaults = defaultFavicon(url)
            return (defaults.image, defaults.color)
        }
        return nil
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

