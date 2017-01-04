/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import Alamofire
import XCGLogger
import Deferred
import WebImage
import Fuzi

private let log = Logger.browserLogger
private let queue = dispatch_queue_create("FaviconFetcher", DISPATCH_QUEUE_CONCURRENT)

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
public class FaviconFetcher: NSObject, NSXMLParserDelegate {
    public static var userAgent: String = ""
    static let ExpirationTime = NSTimeInterval(60*60*24*7) // Only check for icons once a week
    private static var characterToFaviconCache = [String : UIImage]()
    static var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    class func getForURL(url: NSURL, profile: Profile) -> Deferred<Maybe<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url, profile: profile)
    }

    private func loadFavicons(url: NSURL, profile: Profile, oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()

        var oldIcons: [Favicon] = oldIcons

        dispatch_async(queue) { _ in
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

                oldIcons = oldIcons.sort {
                    return $0.width > $1.width
                }

                return deferMaybe(oldIcons)
            }).upon({ (result: Maybe<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }

        return deferred
    }

    lazy private var alamofire: Alamofire.Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 5

        return Alamofire.Manager.managerWithUserAgent(userAgent, configuration: configuration)
    }()

    private func fetchDataForURL(url: NSURL) -> Deferred<Maybe<NSData>> {
        let deferred = Deferred<Maybe<NSData>>()
        alamofire.request(.GET, url).response { (request, response, data, error) in
            // Don't cancel requests just because our Manager is deallocated.
            withExtendedLifetime(self.alamofire) {
                if error == nil {
                    if let data = data {
                        deferred.fill(Maybe(success: data))
                        return
                    }
                }
                let errorDescription = (error as NSError?)?.description ?? "No content."
                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
            }
        }
        return deferred
    }



    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func parseHTMLForFavicons(url: NSURL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue where result.isSuccess,
                let root = try? HTMLDocument(data: data) else {
                    return deferMaybe([])
            }
            var reloadUrl: NSURL? = nil
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"] where refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.rangeOfString("URL="),
                    let url = NSURL(string: content.substringFromIndex(index.startIndex.advancedBy(4))) {
                    reloadUrl = url
                }
            }

            if let url = reloadUrl {
                return self.parseHTMLForFavicons(url)
            }

            var bestType = IconType.NoneFound
            for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
                var iconType: IconType? = nil
                if let rel = link["rel"] {
                    switch (rel) {
                    case "shortcut icon":
                        iconType = .Icon
                    case "icon":
                        iconType = .Icon
                    case "apple-touch-icon":
                        iconType = .AppleIcon
                    case "apple-touch-icon-precomposed":
                        iconType = .AppleIconPrecomposed
                    default:
                        iconType = nil
                    }
                }

                guard let href = link["href"] where iconType != nil else {
                    continue //Skip the rest of the loop. But don't stop the loop
                }

                if (href.endsWith(".ico")) {
                    iconType = .Guess
                }

                if let type = iconType where !bestType.isPreferredTo(type), let iconUrl = NSURL(string: href, relativeToURL: url), let absoluteString = iconUrl.absoluteString {
                    let icon = Favicon(url: absoluteString, date: NSDate(), type: type)
                    // If we already have a list of Favicons going already, then add it…
                    if (type == bestType) {
                        icons.append(icon)
                    } else {
                        // otherwise, this is the first in a new best yet type.
                        icons = [icon]
                        bestType = type
                    }
                }


                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeToURL: url) where icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString, date: NSDate(), type: .Guess)
                    icons = [icon]
                }

            }
            return deferMaybe(icons)
        })
    }

    func getFavicon(siteUrl: NSURL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.sharedManager()
        let site = Site(url: siteUrl.absoluteString!, title: "")

        var fav = Favicon(url: url, type: icon.type)
        if let url = url.asURL {
            var fetch: SDWebImageOperation?
            fetch = manager.downloadImageWithURL(url,
                options: SDWebImageOptions.LowPriority,
                progress: { (receivedSize, expectedSize) in
                    if receivedSize > FaviconManager.maximumFaviconSize || expectedSize > FaviconManager.maximumFaviconSize {
                        fetch?.cancel()
                    }
                },
                completed: { (img, err, cacheType, success, url) -> Void in
                fav = Favicon(url: url.absoluteString!,
                    type: icon.type)

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

    // Returns the default favicon for a site based on the first letter of the site's domain
    class func getDefaultFavicon(url: NSURL) -> UIImage {
        guard let character = url.baseDomain?.characters.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercaseString

        if let cachedFavicon = characterToFaviconCache[faviconLetter] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .Center
        faviconLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
        faviconLabel.textColor = UIColor.whiteColor()
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        characterToFaviconCache[faviconLetter] = faviconImage
        return faviconImage
    }

    // Returns a color based on the url's hash
    class func getDefaultColor(url: NSURL) -> UIColor {
        guard let hash = url.baseDomain?.hashValue else {
            return UIColor.grayColor()
        }
        let index = abs(hash) % (UIConstants.DefaultColorStrings.count - 1)
        let colorHex = UIConstants.DefaultColorStrings[index]
        return UIColor(colorString: colorHex)
    }
}
