/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import XCGLogger
import SDWebImage
import Fuzi
import SwiftyJSON

private let log = Logger.browserLogger

class FaviconFetcherErrorType: MaybeErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/* A helper class to find the favicon associated with a URL.
 * This will load the page and parse any icons it finds out of it.
 * If that fails, it will attempt to find a favicon.ico in the root host domain.
 * This file focuses on fetching just bundled or letter-generated favicons, for fetching others,
 * look at the extension.
 */
open class FaviconFetcher: NSObject, XMLParserDelegate {
    internal let queue = DispatchQueue(label: "FaviconFetcher", attributes: DispatchQueue.Attributes.concurrent)
    
    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    public static var userAgent: String = ""
    static let ExpirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    
    private static var characterToFaviconCache = [String: UIImage]()
    static var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    typealias BundledIconType = (bgcolor: UIColor, filePath: String)
    // Sites can be accessed via their baseDomain.
    static let bundledIcons: [String: BundledIconType] = FaviconFetcher.getBundledIcons()

    static let multiRegionDomains = ["craigslist", "google", "amazon"]

    class func getBundledIcon(forUrl url: URL) -> BundledIconType? {
        // Problem: Sites like amazon exist with .ca/.de and many other tlds.
        // Solution: They are stored in the default icons list as "amazon" instead of "amazon.com" this allows us to have favicons for every tld."
        // Here, If the site is in the multiRegionDomain array look it up via its second level domain (amazon) instead of its baseDomain (amazon.com)
        let hostName = url.shortDisplayString
        if multiRegionDomains.contains(hostName), let icon = bundledIcons[hostName] {
            return icon
        }
        let fullURL = url.absoluteDisplayString.remove("\(url.scheme ?? "")://")
        if let name = url.baseDomain, let icon = bundledIcons[name] ?? bundledIcons[fullURL] {
            return icon
        }
        return nil
    }

    lazy internal var urlSession: URLSession = makeURLSession(userAgent: FaviconFetcher.userAgent, configuration: URLSessionConfiguration.default, timeout: 5)

    private struct BundledIcon: Codable {
        var title: String
        var url: String?
        var image_url: String
        var background_color: String
        var domain: String
    }

    // Default favicons and background colors provided via mozilla/tippy-top-sites
    private class func getBundledIcons() -> [String: BundledIconType] {
        
        // Alows us to access bundle from extensions
        // Also found in `SentryIntegration`. Taken from: https://stackoverflow.com/questions/26189060/get-the-main-app-bundle-from-within-extension
        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        
        let filePath = bundle.path(forResource: "top_sites", ofType: "json")
        let file = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        let decoder = JSONDecoder()
        var icons = [String: BundledIconType]()
        var decoded = [BundledIcon]()
        do {
            decoded = try decoder.decode([BundledIcon].self, from: file)
        } catch {
            print(error)
            assert(false)
            return icons
        }

        decoded.forEach {
            let path = $0.image_url.replacingOccurrences(of: ".png", with: "")
            let url = $0.domain
            let color = $0.background_color
            let filePath = Bundle.main.path(forResource: "TopSites/" + path, ofType: "png")
            if let filePath = filePath {
                if color == "#fff" || color == "#FFF" {
                    icons[url] = (UIColor.clear, filePath)
                } else {
                    icons[url] = (UIColor(colorString: color.replacingOccurrences(of: "#", with: "")), filePath)
                }
            }
        }

        return icons
    }

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
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
