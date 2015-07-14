import Storage
import Shared

private let queue = dispatch_queue_create("FaviconFetcher", DISPATCH_QUEUE_CONCURRENT)

class FaviconFetcherErrorType: ErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/* A helper class to find the favicon associated with a url. This will load the page and parse any icons it finds out of it
 * If that fails, it will attempt to find a favicon.ico in the root host domain
 */
class FaviconFetcher : NSObject, NSXMLParserDelegate {
    static let ExpirationTime = NSTimeInterval(60*60*24*7) // Only check for icons once a week

    private var siteUrl: NSURL // The url we're looking for favicons for
    private var _favicons = [Favicon]() // An internal cache of favicons found for this url

    class func getForUrl(url: NSURL, profile: Profile) -> Deferred<Result<[Favicon]>> {
        let f = FaviconFetcher(url: url)
        return f.loadFavicons(profile)
    }

    private init(url: NSURL) {
        siteUrl = url
    }

    private func loadFavicons(profile: Profile) -> Deferred<Result<[Favicon]>> {
        let deferred = Deferred<Result<[Favicon]>>()

        dispatch_async(queue) { _ in
            if self._favicons.count == 0 {
                // Initially look for tags in the page
                self.loadFromDoc()
            }

            // If that didn't find anything, look for a favicon.ico for this host
            if self._favicons.count == 0 {
                self.loadFromHost()
            }

            var filledCount = 0
            for (i, icon) in enumerate(self._favicons) {
                // For each icon we set of an async load of the data (in order to get the width/height.
                self.getFavicon(icon, profile: profile).upon { result in
                    if let icon = result.successValue {
                        self._favicons[i] = icon
                    }
                    filledCount++

                    // When they've all completed, we can fill the deferred with the results
                    if filledCount == self._favicons.count {
                        self._favicons.sort({ (a, b) -> Bool in
                            return a.width > b.width
                        })

                        deferred.fill(Result(success: self._favicons))
                    }
                }
            }
        }

        return deferred
    }

    // Loads favicon.ico on the host domain for this url
    private func loadFromHost() {
        if let url = NSURL(scheme: siteUrl.scheme!, host: siteUrl.host, path: "/favicon.ico") {
            let icon = Favicon(url: url.absoluteString!, type: IconType.Guess)
            _favicons.append(icon)
        }
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func loadFromDoc() {
        var err: NSError?

        if let data = NSData(contentsOfURL: siteUrl),
           let element = RXMLElement(fromHTMLData: data) {
            element.iterate("head.meta") { meta in
                if let refresh = meta.attribute("http-equiv"),
                   let content = meta.attribute("content"),
                   let index = content.rangeOfString("URL="),
                   let url = NSURL(string: content.substringFromIndex(advance(index.startIndex,4))) {
                    if refresh == "Refresh" {
                        self.siteUrl = url
                        self.loadFromDoc()
                        return
                    }
                }
            }

            element.iterate("head.link") { link in
                if var rel = link.attribute("rel") where (rel == "shortcut icon" || rel == "icon" || rel == "apple-touch-icon"),
                    var href = link.attribute("href"),
                    var url = NSURL(string: href, relativeToURL: self.siteUrl) {
                        let icon = Favicon(url: url.absoluteString!, date: NSDate(), type: IconType.Icon)
                        self._favicons.append(icon)
                }
            }
        }
    }

    private func getFavicon(icon: Favicon, profile: Profile) -> Deferred<Result<Favicon>> {
        let deferred = Deferred<Result<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.sharedManager()
        let site = Site(url: siteUrl.absoluteString!, title: "")

        var fav = Favicon(url: url, type: IconType.Icon)
        if let url = url.asURL {
            manager.downloadImageWithURL(url, options: SDWebImageOptions.LowPriority, progress: nil, completed: { (img, err, cacheType, success, url) -> Void in
                fav = Favicon(url: url.absoluteString!,
                    type: IconType.Icon)

                if let img = img {
                    fav.width = Int(img.size.width)
                    fav.height = Int(img.size.height)
                    profile.favicons.addFavicon(fav, forSite: site)
                } else {
                    fav.width = 0
                    fav.height = 0
                }

                deferred.fill(Result(success: fav))
            })
        } else {
            return deferResult(FaviconFetcherErrorType(description: "Invalid url \(url)"))
        }

        return deferred
    }
}

