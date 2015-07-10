import Storage

private let queue = dispatch_queue_create("FaviconFetcher", DISPATCH_QUEUE_CONCURRENT)

/* A helper class to find the favicon associated with a url. This will load the page and parse any icons it finds out of it
 * If that fails, it will attempt to find a favicon.ico in the root host domain
 */
class FaviconFetcher : NSObject, NSXMLParserDelegate {
    static let ExpirationTime = NSTimeInterval(60*60*24*7) // Only check for icons once a week

    private var siteUrl: NSURL // The url we're looking for favicons for
    private var _favicons = [Favicon]() // An internal cache of favicons found for this url

    class func getForUrl(url: NSURL, profile: Profile, callback: ([Favicon]) -> Void) {
        dispatch_async(queue) {
            let f = FaviconFetcher(url: url)
            f.loadFavicons(profile, callback: callback)
        }
    }

    private init(url: NSURL) {
        siteUrl = url
    }

    private func loadFavicons(profile: Profile, callback: ([Favicon]) -> Void) {
        if _favicons.count == 0 {
            // Initially look for tags in the page
            loadFromDoc()
        }

        // If that didn't find anything, look for a favicon.ico for this host
        if _favicons.count == 0 {
            loadFromHost()
        }

        var filledCount = 0
        for (i, icon) in enumerate(_favicons) {
            getFavicon(icon, profile: profile) { icon in
                if let icon = icon {
                    self._favicons[i] = icon
                }

                filledCount++
                if filledCount == self._favicons.count {
                    self._favicons.sort({ (a, b) -> Bool in
                        return a.width > b.width
                    })

                    dispatch_async(dispatch_get_main_queue()) {
                        callback(self._favicons)
                    }
                }
            }
        }
    }

    // Loads favicon.ico on the host domain for this url
    private func loadFromHost() {
        var url = NSURL(scheme: siteUrl.scheme!, host: siteUrl.host, path: "/favicon.ico")
        var request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.timeoutInterval = 5

        var response: NSURLResponse? = nil;
        var err = NSErrorPointer()
        NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: err)
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                let icon = Favicon(url: url!.absoluteString!, date: NSDate(), type: IconType.Guess)
                _favicons.append(icon)
            }
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
                        println("Refresh with \(self.siteUrl)")
                        return self.loadFromDoc()
                    }
                }
            }

            element.iterate("head.link") { link in
                let rel = link.attribute("rel")
                let href = link.attribute("href")
                // println("Found link \(rel) \(href)")
                if var rel = link.attribute("rel") where (rel == "shortcut icon" || rel == "icon" || rel == "apple-touch-icon"),
                    var href = link.attribute("href"),
                    var url = NSURL(string: href, relativeToURL: self.siteUrl) {
                        let icon = Favicon(url: url.absoluteString!, date: NSDate(), type: IconType.Icon)
                        self._favicons.append(icon)
                }
            }
        }
    }

    private func getFavicon(icon: Favicon, profile: Profile, callback: (Favicon?) -> Void) {
        let url = icon.url
        let manager = SDWebImageManager.sharedManager()
        let site = Site(url: siteUrl.absoluteString!, title: "")

        var fav = Favicon(url: url, date: NSDate(), type: IconType.Icon)
        manager.downloadImageWithURL(url.asURL!, options: SDWebImageOptions.LowPriority, progress: nil, completed: { (img, err, cacheType, success, url) -> Void in
            fav = Favicon(url: url.absoluteString!,
                date: NSDate(),
                type: IconType.Icon)

            if let img = img {
                fav.width = Int(img.size.width)
                fav.height = Int(img.size.height)
                profile.favicons.addFavicon(fav, forSite: site)
                callback(fav)
                return
            }

            fav.width = 0
            fav.height = 0
            return callback(fav)
        })
    }
}

