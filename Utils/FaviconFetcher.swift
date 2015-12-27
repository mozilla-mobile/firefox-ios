/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import Alamofire
import XCGLogger

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
public class FaviconFetcher : NSObject, NSXMLParserDelegate {
    public static var userAgent: String = ""
    static let ExpirationTime = NSTimeInterval(60*60*24*7) // Only check for icons once a week

    class func getForURL(url: NSURL, profile: Profile) -> Deferred<Maybe<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url, profile: profile)
    }

    private func loadFavicons(url: NSURL, profile: Profile, var oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()

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

                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: error?.description ?? "No content.")))
            }
        }
        return deferred
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func parseHTMLForFavicons(url: NSURL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()

            if let data = result.successValue where result.isSuccess,
               let element = RXMLElement(fromHTMLData: data) where element.isValid {
                var reloadUrl: NSURL? = nil
                element.iterate("head.meta") { meta in
                    if let refresh = meta.attribute("http-equiv") where refresh == "Refresh",
                        let content = meta.attribute("content"),
                        let index = content.rangeOfString("URL="),
                        let url = NSURL(string: content.substringFromIndex(index.startIndex.advancedBy(4))) {
                            reloadUrl = url
                    }
                }

                if let url = reloadUrl {
                    return self.parseHTMLForFavicons(url)
                }

                var bestType = IconType.NoneFound
                element.iterate("head.link") { link in
                    var iconType: IconType? = nil
                    if let rel = link.attribute("rel") {
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
                    if let type = iconType where !bestType.isPreferredTo(type),
                        let href = link.attribute("href"),
                        let iconUrl = NSURL(string: href, relativeToURL: url) {
                            let icon = Favicon(url: iconUrl.absoluteString, date: NSDate(), type: type)
                            // If we already have a list of Favicons going already, then add it…
                            if (type == bestType) {
                                icons.append(icon)
                            } else {
                                // otherwise, this is the first in a new best yet type.
                                icons = [icon]
                                bestType = type
                            }
                    }
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeToURL: url) where icons.isEmpty {
                    let icon = Favicon(url: url.absoluteString, date: NSDate(), type: .Icon)
                    icons = [icon]
                }
            }
            return deferMaybe(icons)
        })
    }

    private func getFavicon(siteUrl: NSURL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.sharedManager()
        let site = Site(url: siteUrl.absoluteString, title: "")

        var fav = Favicon(url: url, type: icon.type)
        if let url = url.asURL {
            manager.downloadImageWithURL(url,
                options: SDWebImageOptions.LowPriority,
                progress: nil,
                completed: { (img, err, cacheType, success, url) -> Void in
                fav = Favicon(url: url.absoluteString,
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
}

