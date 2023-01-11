// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

/* A helper class to find the favicon associated with a URL.
 * This will load the page and parse any icons it finds out of it.
 * If that fails, it will attempt to find a favicon.ico in the root host domain.
 * This file focuses on fetching just bundled or letter-generated favicons, for fetching others,
 * look at the extension.
 */
open class FaviconFetcher: NSObject, XMLParserDelegate {
    private static var characterToFaviconCache = [String: UIImage]()
    static var defaultFavicon: UIImage = {
        return UIImage(named: ImageIdentifiers.defaultFavicon)!
    }()

    // Create (or return from cache) a fallback image for a site based on the first letter of the site's domain
    // Letter is white on a colored background
    class func letter(forUrl url: URL) -> UIImage {
        guard let character = url.baseDomain?.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = characterToFaviconCache[faviconLetter] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
        faviconLabel.textColor = UIColor.Photon.White100
        faviconLabel.backgroundColor = color(forUrl: url)
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        characterToFaviconCache[faviconLetter] = faviconImage
        return faviconImage
    }

    // Returns a color based on the url's hash
    class func color(forUrl url: URL) -> UIColor {
        // A stable hash (unlike hashValue), from https://useyourloaf.com/blog/swift-hashable/
        func stableHash(_ str: String) -> Int {
            let unicodeScalars = str.unicodeScalars.map { $0.value }
            return unicodeScalars.reduce(5381) {
                ($0 << 5) &+ $0 &+ Int($1)
            }
        }

        guard let domain = url.baseDomain else {
            return UIColor.Photon.Grey50
        }
        let index = abs(stableHash(domain)) % (DefaultFaviconBackgroundColors.count - 1)
        let colorHex = DefaultFaviconBackgroundColors[index]

        return UIColor(colorString: colorHex)
    }

    class func checkWidgetKitImageCache(imageKey: String) -> Bool {
        let fileManager = FileManager.default
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier) else {
            return false
        }
        let imageKeyDirectoryUrl = container.appendingPathComponent("Library/Caches/fxfavicon/\(imageKey)")
        return fileManager.fileExists(atPath: imageKeyDirectoryUrl.path)
    }

    class func getFaviconFromDiskCache(imageKey: String) -> UIImage? {
        guard checkWidgetKitImageCache(imageKey: imageKey) else { return nil }
        // image cache found now we retrieve image
        let fileManager = FileManager.default
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier) else { return nil }
        let imageKeyDirectoryUrl = container.appendingPathComponent("Library/Caches/fxfavicon/\(imageKey)")
        guard let data = fileManager.contents(atPath: imageKeyDirectoryUrl.path) else { return nil }
        return UIImage(data: data)
    }
}
