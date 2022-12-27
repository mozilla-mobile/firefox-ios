// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Fuzi
import SwiftyJSON
import Shared

private let log = Logger.syncLogger

// Set up for downloading web content for parsing.
// NOTE: We use the desktop UA to try and get hi-res icons.
private var urlSession: URLSession = makeURLSession(userAgent: UserAgent.desktopUserAgent(), configuration: URLSessionConfiguration.default, timeout: 5)

// If all else fails, this is the default "default" icon.
private var defaultFavicon: UIImage = {
    return UIImage(named: ImageIdentifiers.defaultFavicon)!
}()

// An in-memory cache of "default" favicons keyed by the
// first character of a site's domain name.
private var defaultFaviconImageCache = [String: UIImage]()

// Some of our top-sites domains exist in various
// region-specific TLDs. This helps us resolve them.
private let multiRegionTopSitesDomains = ["craigslist", "google", "amazon"]

private let topSitesIcons: [String: (color: UIColor, fileURL: URL)] = {
    var icons: [String: (color: UIColor, fileURL: URL)] = [:]

    let filePath = Bundle.main.path(forResource: "top_sites", ofType: "json")
    let file = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
    JSON(file).forEach({
        guard let domain = $0.1["domain"].string,
            let color = $0.1["background_color"].string?.lowercased(),
            let path = $0.1["image_url"].string?.replacingOccurrences(of: ".png", with: "") else {
            return
        }

        if let fileURL = Bundle.main.url(forResource: "TopSites/" + path, withExtension: "png") {
            if color == "#fff" {
                icons[domain] = (UIColor.clear, fileURL)
            } else {
                icons[domain] = (UIColor(colorString: color.replacingOccurrences(of: "#", with: "")), fileURL)
            }
        }
    })

    return icons
}()

class FaviconLookupError: MaybeErrorType {
    let siteURL: String
    init(siteURL: String) {
        self.siteURL = siteURL
    }
    var description: String {
        return "Unable to find favicon for site URL: \(siteURL)"
    }
}

class FaviconDownloadError: MaybeErrorType {
    let faviconURL: String
    init(faviconURL: String) {
        self.faviconURL = faviconURL
    }
    internal var description: String {
        return "Unable to download favicon at URL: \(faviconURL)"
    }
}

extension SQLiteHistory: Favicons {
    public func getFaviconImage(forSite site: Site, completionHandler: @escaping (UIImage?) -> Void) {
        // First, attempt to lookup the favicon from our bundled top sites.
        return getTopSitesFaviconImage(forSite: site) { result in
            guard let image = result else {
                // Note: "Attempt to lookup the favicon URL from the database" was removed as part of FXIOS-5164 and
                // FXIOS-5294. This code will be removed soon as part of the SiteImageView replacement solution,
                // but we're still supporting it in the meantime.

                // Attempt to scrape its URL from the web page.
                return self.lookupFaviconURLFromWebPage(forSite: site) { result in
                    guard let faviconURL = result else {
                        // Otherwise, get the default favicon image.
                        self.generateDefaultFaviconImage(forSite: site, completionHandler: completionHandler)
                        return
                    }
                    // Try to get the favicon from the URL scraped from the web page.
                    return self.retrieveTopSiteSQLiteHistoryFaviconImage(faviconURL: faviconURL) { result in
                        // If the favicon could not be downloaded, use the generated "default" favicon.
                        guard let image = result else {
                            self.generateDefaultFaviconImage(forSite: site, completionHandler: completionHandler)
                            return
                        }

                        completionHandler(image)
                        return
                    }
                }
            }

            completionHandler(image)
        }
    }

    // Downloads a favicon image from the web or retrieves it from the cache.
    fileprivate func retrieveTopSiteSQLiteHistoryFaviconImage(faviconURL: URL,
                                                              completionHandler: @escaping (UIImage?) -> Void) {
        ImageLoadingHandler.shared.getImageFromCacheOrDownload(with: faviconURL,
                                                               limit: ImageLoadingConstants.MaximumFaviconSize) { image, error in
            guard error == nil, let image = image else {
                completionHandler(nil)
                return
            }

            completionHandler(image)
        }
    }

    fileprivate func getTopSitesFaviconImage(forSite site: Site, completionHandler: (UIImage?) -> Void) {
        guard let url = URL(string: site.url) else {
            completionHandler(nil)
            return
        }

        func imageFor(icon: (color: UIColor, fileURL: URL), completionHandler: (UIImage?) -> Void) {
            guard let image = UIImage(contentsOfFile: icon.fileURL.path) else {
                completionHandler(nil)
                return
            }

            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            defer { UIGraphicsEndImageContext() }

            guard let context = UIGraphicsGetCurrentContext(),
                let cgImage = image.cgImage else {
                completionHandler(image)
                return
            }

            let rect = CGRect(origin: .zero, size: image.size)
            context.setFillColor(icon.color.cgColor)
            context.fill(rect)
            context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: rect.height))
            context.draw(cgImage, in: rect)

            guard let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext() else {
                completionHandler(image)
                return
            }

            completionHandler(imageWithBackground)
        }

        let domain = url.shortDisplayString
        if multiRegionTopSitesDomains.contains(domain), let icon = topSitesIcons[domain] {
            imageFor(icon: icon, completionHandler: completionHandler)
            return
        }

        let urlWithoutScheme = url.absoluteDisplayString.remove("\(url.scheme ?? "")://")
        if let baseDomain = url.baseDomain, let icon = topSitesIcons[baseDomain] ?? topSitesIcons[urlWithoutScheme] {
            imageFor(icon: icon, completionHandler: completionHandler)
            return
        }

        completionHandler(nil)
    }

    // Retrieve's a site's favicon URL from the web.
    fileprivate func lookupFaviconURLFromWebPage(forSite site: Site, completionHandler: @escaping (URL?) -> Void) {
        guard let url = URL(string: site.url) else {
            completionHandler(nil)
            return
        }

        getFaviconURLsFromWebPage(url: url) { result in
            guard let faviconURLs = result,
                let faviconURL = faviconURLs.first else {
                completionHandler(nil)
                return
            }

            completionHandler(faviconURL)
        }
    }

    // Scrapes an HTMLDocument DOM from a web page URL.
    fileprivate func getHTMLDocumentFromWebPage(url: URL, completionHandler: @escaping (HTMLDocument?) -> Void) {
        // getHTMLDocumentFromWebPage can be called from getFaviconURLsFromWebPage, and that function is off-main.
        DispatchQueue.main.async {
            urlSession.dataTask(with: url) { (data, response, error) in
                guard error == nil,
                      let data = data,
                      let document = try? HTMLDocument(data: data) else {
                    completionHandler(nil)
                    return
                }
                completionHandler(document)
            }.resume()
        }
    }

    // Scrapes the web page at the specified URL for its favicon URLs.
    fileprivate func getFaviconURLsFromWebPage(url: URL, completionHandler: @escaping ([URL]?) -> Void) {
        return getHTMLDocumentFromWebPage(url: url) { result in
            guard let document = result else {
                completionHandler(nil)
                return
            }

            // If we were redirected via a <meta> tag on the page to a different
            // URL, go to the redirected page for the favicon instead.
            for meta in document.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let reloadURL = URL(string: String(content[index.upperBound...])),
                    reloadURL != url {
                    self.getFaviconURLsFromWebPage(url: reloadURL, completionHandler: completionHandler)
                    return
                }
            }

            var icons = [URL]()

            // Iterate over each <link rel="icon"> tag on the page.
            for link in document.xpath("//head//link[contains(@rel, 'icon')]") {
                // Only consider <link rel="icon"> tags with an [href] attribute.
                if let href = link["href"], let faviconURL = URL(string: href, relativeTo: url) {
                    icons.append(faviconURL)
                }
            }

            // Also, consider a "/favicon.ico" icon at the root of the domain.
            if let faviconURL = URL(string: "/favicon.ico", relativeTo: url) {
                icons.append(faviconURL)
            }

            completionHandler(icons)
        }
    }

    // Generates a "default" favicon based on the first character in the
    // site's domain name or gets an already-generated icon from the cache.
    fileprivate func generateDefaultFaviconImage(forSite site: Site, completionHandler: @escaping (UIImage) -> Void) {
        DispatchQueue.main.async {
            guard let url = URL(string: site.url), let character = url.baseDomain?.first else {
                completionHandler(defaultFavicon)
                return
            }

            let faviconLetter = String(character).uppercased()

            if let cachedFavicon = defaultFaviconImageCache[faviconLetter] {
                completionHandler(cachedFavicon)
                return
            }

            func generateBackgroundColor(forURL url: URL) -> UIColor {
                guard let hash = url.baseDomain?.hashValue else {
                    return UIColor.Photon.Grey50
                }
                let index = abs(hash) % (DefaultFaviconBackgroundColors.count - 1)
                let colorHex = DefaultFaviconBackgroundColors[index]
                return UIColor(colorString: colorHex)
            }

            var image = UIImage()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            label.text = faviconLetter
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
            label.textColor = UIColor.Photon.White100
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
            let rect = CGRect(origin: .zero, size: label.bounds.size)
            let context = UIGraphicsGetCurrentContext()!
            context.setFillColor(generateBackgroundColor(forURL: url).cgColor)
            context.fill(rect)
            label.layer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            defaultFaviconImageCache[faviconLetter] = image
            completionHandler(image)
        }
    }
}
