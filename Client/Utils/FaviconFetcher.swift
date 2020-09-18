/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import XCGLogger
import SDWebImage
import Fuzi
import SwiftyJSON

private let log = Logger.browserLogger
private let queue = DispatchQueue(label: "FaviconFetcher", attributes: DispatchQueue.Attributes.concurrent)

class FaviconFetcherErrorType: MaybeErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/* A helper class to find the favicon associated with a URL.
 * This will load the page and parse any icons it finds out of it.
 * If that fails, it will attempt to find a favicon.ico in the root host domain.
 */
open class FaviconFetcher: NSObject, XMLParserDelegate {
    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    public static var userAgent: String = ""
    static let ExpirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    fileprivate static var characterToFaviconCache = [String: UIImage]()
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

    class func getForURL(_ url: URL, profile: Profile) -> Deferred<Maybe<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url, profile: profile)
    }

    fileprivate func loadFavicons(_ url: URL, profile: Profile, oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()

        var oldIcons: [Favicon] = oldIcons

        queue.async {
            self.parseHTMLForFavicons(url).bind({ (result: Maybe<[Favicon]>) -> Deferred<[Maybe<Favicon>]> in
                var deferreds = [Deferred<Maybe<Favicon>>]()
                if let icons = result.successValue {
                    deferreds = icons.map { self.getFavicon(url, icon: $0, profile: profile) }
                }
                return all(deferreds)
            }).bind({ (results: [Maybe<Favicon>]) -> Deferred<Maybe<[Favicon]>> in
                for result in results {
                    if let icon = result.successValue {
                        oldIcons.append(icon)
                    }
                }

                oldIcons = oldIcons.sorted {
                    return $0.width! > $1.width!
                }

                return deferMaybe(oldIcons)
            }).upon({ (result: Maybe<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }

        return deferred
    }

    lazy fileprivate var urlSession: URLSession = makeURLSession(userAgent: FaviconFetcher.userAgent, configuration: URLSessionConfiguration.default, timeout: 5)

    fileprivate func fetchDataForURL(_ url: URL) -> Deferred<Maybe<Data>> {
        let deferred = Deferred<Maybe<Data>>()
        urlSession.dataTask(with: url) { (data, _, error) in
            if let data = data {
                deferred.fill(Maybe(success: data))
                return
            }

            let errorDescription = (error as NSError?)?.description ?? "No content."
            deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
        }.resume()

        return deferred
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    fileprivate func parseHTMLForFavicons(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue, result.isSuccess,
                let root = try? HTMLDocument(data: data as Data) else {
                    return deferMaybe([])
            }
            var reloadUrl: URL?
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let url = NSURL(string: String(content[index.upperBound...])) {
                    reloadUrl = url as URL
                }
            }

            if let url = reloadUrl {
                return self.parseHTMLForFavicons(url)
            }

            for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
                guard let href = link["href"] else {
                    continue //Skip the rest of the loop. But don't stop the loop
                }

                if let iconUrl = NSURL(string: href, relativeTo: url as URL), let absoluteString = iconUrl.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeTo: url as URL), icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

            }
            return deferMaybe(icons)
        })
    }

    func getFavicon(_ siteUrl: URL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.shared
        let site = Site(url: siteUrl.absoluteString, title: "")

        var fav = Favicon(url: url)
        if let url = url.asURL {
            var fetch: SDWebImageOperation?
            fetch = manager.loadImage(with: url,
                options: .lowPriority,
                progress: { (receivedSize, expectedSize, _) in
                    if receivedSize > FaviconFetcher.MaximumFaviconSize || expectedSize > FaviconFetcher.MaximumFaviconSize {
                        fetch?.cancel()
                    }
                },
                completed: { (img, _, _, _, _, url) in
                    guard let url = url else {
                        deferred.fill(Maybe(failure: FaviconError()))
                        return
                    }
                    fav = Favicon(url: url.absoluteString)

                    if let img = img {
                        fav.width = Int(img.size.width)
                        fav.height = Int(img.size.height)
                        profile.favicons.addFavicon(fav, forSite: site)
                    } else {
                        fav.width = 0
                        fav.height = 0
                    }

                    deferred.fill(Maybe(success: fav))
            })
        } else {
            return deferMaybe(FaviconFetcherErrorType(description: "Invalid URL \(url)"))
        }

        return deferred
    }

    // Returns the largest Favicon UIImage for a given URL
    class func fetchFavImageForURL(forURL url: URL, profile: Profile) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()
        FaviconFetcher.getForURL(url.domainURL, profile: profile).uponQueue(.main) { result in
            var iconURL: URL?
            
            if let favicons = result.successValue, favicons.count > 0, let faviconImageURL =
                favicons.first?.url.asURL {
                iconURL = faviconImageURL
            } else {
                return deferred.fill(Maybe(failure: FaviconError()))
            }
            SDWebImageManager.shared.loadImage(with: iconURL, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                if let image = image {
                    deferred.fill(Maybe(success: image))
                } else {
                    deferred.fill(Maybe(failure: FaviconError()))
                }
            }
        }
        return deferred
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
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
