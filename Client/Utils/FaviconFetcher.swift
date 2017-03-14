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
    open static var userAgent: String = ""
    static let ExpirationTime = TimeInterval(60*60*24*7) // Only check for icons once a week
    fileprivate static var characterToFaviconCache = [String: UIImage]()
    static var defaultFavicon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    static var colors: [String: UIColor] = [:] //An in-Memory data store that stores background colors domains. Stored using url.baseDomain.

    // Sites can be accessed via their baseDomain.
    static var defaultIcons: [String: (color: UIColor, url: String)] = {
        return FaviconFetcher.getDefaultIcons()
    }()

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

        queue.async { _ in
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

    lazy fileprivate var alamofire: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5

        return SessionManager.managerWithUserAgent(userAgent, configuration: configuration)
    }()

    fileprivate func fetchDataForURL(_ url: URL) -> Deferred<Maybe<Data>> {
        let deferred = Deferred<Maybe<Data>>()
        alamofire.request(url).response { response in
            // Don't cancel requests just because our Manager is deallocated.
            withExtendedLifetime(self.alamofire) {
                if response.error == nil {
                    if let data = response.data {
                        deferred.fill(Maybe(success: data))
                        return
                    }
                }
                let errorDescription = (response.error as NSError?)?.description ?? "No content."
                deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
            }
        }
        return deferred
    }

///Users/fpatel/Documents/firefox-ios/Client/Utils/FaviconFetcher.swift:117:77: Cannot convert value of type 'String' to expected argument type 'String.Index' (aka 'String.CharacterView.Index')
    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    fileprivate func parseHTMLForFavicons(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue, result.isSuccess,
                let root = try? HTMLDocument(data: data as Data) else {
                    return deferMaybe([])
            }
            var reloadUrl: URL? = nil
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let url = NSURL(string: content.substring(from: index.upperBound)) {
                    reloadUrl = url as URL
                }
            }

            if let url = reloadUrl {
                return self.parseHTMLForFavicons(url)
            }

            var bestType = IconType.noneFound
            for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
                var iconType: IconType? = nil
                if let rel = link["rel"] {
                    switch rel {
                    case "shortcut icon":
                        iconType = .icon
                    case "icon":
                        iconType = .icon
                    case "apple-touch-icon":
                        iconType = .appleIcon
                    case "apple-touch-icon-precomposed":
                        iconType = .appleIconPrecomposed
                    default:
                        iconType = nil
                    }
                }

                guard let href = link["href"], iconType != nil else {
                    continue //Skip the rest of the loop. But don't stop the loop
                }

                if href.endsWith(".ico") {
                    iconType = .guess
                }

                if let type = iconType, !bestType.isPreferredTo(type), let iconUrl = NSURL(string: href, relativeTo: url as URL), let absoluteString = iconUrl.absoluteString {
                    let icon = Favicon(url: absoluteString, date: NSDate() as Date, type: type)
                    // If we already have a list of Favicons going already, then add it…
                    if type == bestType {
                        icons.append(icon)
                    } else {
                        // otherwise, this is the first in a new best yet type.
                        icons = [icon]
                        bestType = type
                    }
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeTo: url as URL), icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString, date: NSDate() as Date, type: .guess)
                    icons = [icon]
                }

            }
            return deferMaybe(icons)
        })
    }

    func getFavicon(_ siteUrl: URL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.shared()
        let site = Site(url: siteUrl.absoluteString, title: "")

        var fav = Favicon(url: url, type: icon.type)
        if let url = url.asURL {
            var fetch: SDWebImageOperation?
            fetch = manager?.downloadImage(with: url,
                options: SDWebImageOptions.lowPriority,
                progress: { (receivedSize, expectedSize) in
                    if receivedSize > FaviconManager.maximumFaviconSize || expectedSize > FaviconManager.maximumFaviconSize {
                        fetch?.cancel()
                    }
                },
                completed: { (img, err, cacheType, success, url) -> Void in
                fav = Favicon(url: url!.absoluteString,
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

    // Returns a single Favicon UIImage for a given URL
    class func fetchFavImageForURL(forURL url: URL, profile: Profile) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()
        FaviconFetcher.getForURL(url.domainURL, profile: profile).uponQueue(DispatchQueue.main) { result in
            var iconURL: URL?
            if let favicons = result.successValue, favicons.count > 0, let faviconImageURL = favicons.first?.url.asURL {
                iconURL = faviconImageURL
            } else {
                return deferred.fill(Maybe(failure: FaviconError()))
            }
            SDWebImageManager.shared().downloadImage(with: iconURL, options: SDWebImageOptions.continueInBackground, progress: nil) { (image, error, cacheType, success, url) in
                if image != nil {
                    deferred.fill(Maybe(success: image!))
                } else {
                    deferred.fill(Maybe(failure: FaviconError()))
                }
            }
        }
        return deferred
    }

    // Returns the default favicon for a site based on the first letter of the site's domain
    class func getDefaultFavicon(_ url: URL) -> UIImage {
        guard let character = url.baseDomain?.characters.first else {
            return defaultFavicon
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = characterToFaviconCache[faviconLetter] {
            return cachedFavicon
        }

        var faviconImage = UIImage()
        let faviconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize))
        faviconLabel.text = faviconLetter
        faviconLabel.textAlignment = .center
        faviconLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium)
        faviconLabel.textColor = UIColor.white
        UIGraphicsBeginImageContextWithOptions(faviconLabel.bounds.size, false, 0.0)
        faviconLabel.layer.render(in: UIGraphicsGetCurrentContext()!)
        faviconImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        characterToFaviconCache[faviconLetter] = faviconImage
        return faviconImage
    }

    // Returns a color based on the url's hash
    class func getDefaultColor(_ url: URL) -> UIColor {
        guard let hash = url.baseDomain?.hashValue else {
            return UIColor.gray
        }
        let index = abs(hash) % (UIConstants.DefaultColorStrings.count - 1)
        let colorHex = UIConstants.DefaultColorStrings[index]
        return UIColor(colorString: colorHex)
    }

    // Default favicons and background colors provided via mozilla/tippy-top-sites
    class func getDefaultIcons() -> [String: (color: UIColor, url: String)] {
        let filePath = Bundle.main.path(forResource: "top_sites", ofType: "json")
        let file = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        let json = JSON(file)
        var icons: [String: (color: UIColor, url: String)] = [:]
        json.forEach({
            guard let url = $0.1["domain"].string, let color = $0.1["background_color"].string, var path = $0.1["image_url"].string else {
                return
            }
            path = path.replacingOccurrences(of: ".png", with: "")
            let filePath = Bundle.main.path(forResource: "TopSites/" + path, ofType: "png")
            if let filePath = filePath {
                if color == "#fff" || color == "#FFF" {
                    icons[url] = (UIColor.clear, filePath)
                } else {
                    icons[url] = (UIColor(colorString: color.replacingOccurrences(of: "#", with: "")), filePath)
                }
            }
        })
        return icons
    }
}
