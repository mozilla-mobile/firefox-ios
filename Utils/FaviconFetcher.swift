import Storage
import Shared
import Alamofire
import XCGLogger

private let log = XCGLogger.defaultInstance()
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
public class FaviconFetcher : NSObject, NSXMLParserDelegate {
    public static var userAgent: String = ""
    static let ExpirationTime = NSTimeInterval(60*60*24*7) // Only check for icons once a week
    private var attemptedSubdomains = [String]()

    class func getForUrl(url: NSURL, profile: Profile) -> Deferred<Result<[Favicon]>> {
        let f = FaviconFetcher()
        return f.loadFavicons(url, profile: profile)
    }

    private func loadFavicons(url: NSURL, profile: Profile, var oldIcons: [Favicon] = [Favicon]()) -> Deferred<Result<[Favicon]>> {
        let deferred = Deferred<Result<[Favicon]>>()

        dispatch_async(queue) { _ in
            var url = url
            self.parseHTMLForFavicons(&url).bind({ (result: Result<[Favicon]>) -> Deferred<[Result<Favicon>]> in
                var deferreds = [Deferred<Result<Favicon>>]()
                if let icons = result.successValue {
                    deferreds = map(icons) { self.getFavicon(url, icon: $0, profile: profile) }
                }
                return all(deferreds)
            }).bind({ (results: [Result<Favicon>]) -> Deferred<Result<[Favicon]>> in
                for result in results {
                    if let icon = result.successValue {
                        oldIcons.append(icon)
                    }
                }

                oldIcons.sort({ (a, b) -> Bool in
                    if a.type == .OpenGraph && a.width > 48 && b.type != .OpenGraph && b.width > 48 {
                        return false
                    } else if a.type != .OpenGraph && a.width > 48 && b.type == .OpenGraph && b.width > 48 {
                        return true
                    }
                    return a.width > b.width
                })

                // If we haven't found any sizable icons yet...
                if oldIcons.count > 0 && oldIcons[0].width < 48 {
                    // Try the base version of this subdomain. i.e. http://mail.google.com/u/22344 -> http://mail.google.com/
                    if let newUrl = NSURL(scheme: url.scheme ?? "http", host: url.host, path: "/") where newUrl != url {
                        println("\(url) failed, trying \(newUrl)")
                        return self.loadFavicons(newUrl, profile: profile, oldIcons: oldIcons)
                    }

                    // If we're alredy at the root of a domain and still haven't found anything big, lets try other subdomains.
                    // NOTE: This could return something awful. i.e. mail.google.com != www.google.com, but at this point we're
                    //       running out of options.
                    if let base = url.baseDomain() {
                        let subdomains = ["www", "m", "mobile"]
                        for domain in subdomains {
                            if let index = find(self.attemptedSubdomains, domain) {
                                // do nothing
                            } else {
                                self.attemptedSubdomains.append(domain)
                                if let newUrl = NSURL(scheme: url.scheme ?? "http", host: "\(domain).\(base)", path: "/") where newUrl != url {
                                    println("\(url) failed, trying \(newUrl)")
                                    return self.loadFavicons(newUrl, profile: profile, oldIcons: oldIcons)
                                }
                            }
                        }
                    }
                }

                return deferResult(oldIcons)
            }).upon({ (result: Result<[Favicon]>) in
                deferred.fill(result)
                return
            })
        }

        return deferred
    }

    lazy private var alamofire: Alamofire.Manager = {
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = userAgent

        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 5
        configuration.HTTPAdditionalHeaders = defaultHeaders

        return Alamofire.Manager(configuration: configuration)
    }()

    private func fetchDataForUrl(inout url: NSURL) -> Deferred<Result<NSData>> {
        let deferred = Deferred<Result<NSData>>()
        alamofire.request(.GET, url).response { (request, response, data, error) in
            if let error = error {
                deferred.fill(Result(failure: FaviconFetcherErrorType(description: error.description)))
            } else {
                // Alamofire handles redirects for us. Update the url so that any new attempts use the resolved one.
                if let newUrl = response?.URL {
                    url = newUrl
                }
                deferred.fill(Result(success: data as! NSData))
            }
        }
        return deferred
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func parseHTMLForFavicons(inout url: NSURL) -> Deferred<Result<[Favicon]>> {
        var err: NSError?

        return fetchDataForUrl(&url).bind({ result -> Deferred<Result<[Favicon]>> in
            var icons = [Favicon]()

            if let data = result.successValue,
               let element = RXMLElement(fromHTMLData: data) {
                var reloadUrl: NSURL? = nil
                element.iterate("head.meta") { meta in
                    if let refresh = meta.attribute("http-equiv") where refresh == "Refresh",
                        let content = meta.attribute("content"),
                        let index = content.rangeOfString("URL="),
                        let url = NSURL(string: content.substringFromIndex(advance(index.startIndex,4))) {
                            reloadUrl = url
                    }

                    if let property = meta.attribute("property") where property == "og:image",
                        let content = meta.attribute("content"),
                        let url = NSURL(string: content, relativeToURL: url) {
                            let icon = Favicon(url: url.absoluteString!, date: NSDate(), type: IconType.OpenGraph)
                            icons.append(icon)
                    }
                }

                if let url = reloadUrl {
                   return self.parseHTMLForFavicons(&url)
                }

                element.iterate("head.link") { link in
                    if let rel = link.attribute("rel") where (rel == "shortcut icon" || rel == "icon" || rel == "apple-touch-icon" || rel == "apple-touch-icon-precomposed"),
                        let href = link.attribute("href"),
                        let url = NSURL(string: href, relativeToURL: url) {
                            let type: IconType
                            switch rel {
                                case "apple-touch-icon":
                                    type = IconType.AppleIcon
                                case "apple-touch-icon-precomposed":
                                    type = IconType.AppleIconPrecomposed
                                default:
                                    type = IconType.Icon
                            }
                            let icon = Favicon(url: url.absoluteString!, date: NSDate(), type: type)
                            icons.append(icon)
                    }
                }
            }

            if let url = NSURL(scheme: url.scheme ?? "http", host: url.host, path: "/favicon.ico"),
               let urlString = url.absoluteString {
                icons.append(Favicon(url: urlString, date: NSDate(), type: IconType.Guess))
            }

            return deferResult(icons)
        })
    }

    private func getFavicon(siteUrl: NSURL, icon: Favicon, profile: Profile) -> Deferred<Result<Favicon>> {
        let deferred = Deferred<Result<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.sharedManager()
        let site = Site(url: siteUrl.absoluteString!, title: "")

        var fav = Favicon(url: url, type: icon.type)
        if let url = url.asURL {
            manager.downloadImageWithURL(url, options: SDWebImageOptions.LowPriority, progress: nil, completed: { (img, err, cacheType, success, url) -> Void in
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

                deferred.fill(Result(success: fav))
            })
        } else {
            return deferResult(FaviconFetcherErrorType(description: "Invalid url \(url)"))
        }

        return deferred
    }
}

