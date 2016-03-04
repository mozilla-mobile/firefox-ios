/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import Alamofire
import XCGLogger
import Deferred
import WebImage
import SWXMLHash


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
                let errorDescription = (error as NSError?)?.description ?? "No content."
                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
            }
        }
        return deferred
    }

    private func iconTypeForLink(rel:String) -> IconType {
        var iconType = IconType.Guess
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
            iconType = IconType.Guess
        }
        return iconType
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func parseHTMLForFavicons(url: NSURL) -> Deferred<Maybe<[Favicon]>> {

        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue where result.isSuccess else {
                return deferMaybe(icons)
            }

            let element = SWXMLHash.lazy(data)
            var reloadUrl: NSURL? = nil

            //lets see if this page requires a refresh to get the actual page
            do {
                let refreshNode = try element["html"]["head"]["meta"].withAttr("http-equiv", "Refresh").element
                if let urlParam = refreshNode?.attributes["content"],
                    let index = urlParam.rangeOfString("URL="),
                    let url = NSURL(string: urlParam.substringFromIndex(index.startIndex.advancedBy(4))) {
                        reloadUrl = url
                    }
            } catch {}


            if let url = reloadUrl {
              return self.parseHTMLForFavicons(url)
            }

            //map all the icon types to an array of Favicons
            let headElement = element["html"]["head"]["link"]
            let relAttributes = ["shortcut icon","icon","apple-touch-icon","apple-touch-icon-precomposed"]
            let iconsMapped = relAttributes.flatMap({ (relIcon:String) -> Favicon? in
                do {
                    guard let iconHref = try headElement.withAttr("rel", relIcon).element?.attributes["href"] else {
                        return nil
                    }
                    if let iconUrl = NSURL(string: iconHref, relativeToURL: url) {
                        let type = iconHref.endsWith(".ico") ? IconType.Guess : self.iconTypeForLink(relIcon)
                        let icon = Favicon(url: iconUrl.absoluteString, date: NSDate(), type: type)
                        return icon
                    }
                } catch {
                    return nil
                }
                return nil
            })

            //sort that array such that the first Item is the perferred type
            icons = iconsMapped.sort({ (a:Favicon, b:Favicon) -> Bool in
              return a.type.isPreferredTo(b.type)
            })

            // If we haven't got any options icons, then use the default at the root of the domain.
            if let url = NSURL(string: "/favicon.ico", relativeToURL: url) where icons.isEmpty {
                let icon = Favicon(url: url.absoluteString, date: NSDate(), type: .Guess)
                icons.append(icon)
            }
            //only return the icon with the highest resolution
            if let bestIcon = icons.first {
                icons = [bestIcon]
            }

            return deferMaybe(icons)
        })
    }

    func getFavicon(siteUrl: NSURL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
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
