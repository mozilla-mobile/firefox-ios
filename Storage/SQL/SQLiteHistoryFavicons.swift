/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Fuzi
import SDWebImage
import SwiftyJSON
import Shared
import XCGLogger

// Used as backgrounds for favicons
public let DefaultFaviconBackgroundColors = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

private let log = Logger.syncLogger

// Set up for downloading web content for parsing.
// NOTE: We use the desktop UA to try and get hi-res icons.
private var urlSession: URLSession = makeURLSession(userAgent: UserAgent.desktopUserAgent(), configuration: URLSessionConfiguration.default, timeout: 5)

// If all else fails, this is the default "default" icon.
private var defaultFavicon: UIImage = {
    return UIImage(named: "defaultFavicon")!
}()

// An in-memory cache of "default" favicons keyed by the
// first character of a site's domain name.
private var defaultFaviconImageCache = [String: UIImage]()

// Some of our top-sites domains exist in various
// region-specific TLDs. This helps us resolve them.
private let multiRegionTopSitesDomains = ["craigslist", "google", "amazon"]

private let topSitesIcons: [String : (color: UIColor, fileURL: URL)] = {
    var icons: [String : (color: UIColor, fileURL: URL)] = [:]

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
    func getFaviconsForURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = """
            SELECT iconID, iconURL, iconDate
            FROM (
                SELECT iconID, iconURL, iconDate
                FROM view_favicons_widest, history
                WHERE history.id = siteID AND history.url = ?
                UNION ALL
                SELECT favicons.id AS iconID, url as iconURL, date as iconDate
                FROM favicons, favicon_site_urls
                WHERE favicons.id = favicon_site_urls.faviconID AND favicon_site_urls.site_url = ?
            ) LIMIT 1
            """

        let args: Args = [url, url]
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    public func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        return self.favicons.insertOrUpdateFavicon(icon)
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        func doChange(_ query: String, args: Args?) -> Deferred<Maybe<Int>> {
            return db.withConnection { conn -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdateFaviconInTransaction(icon, conn: conn)

                // Now set up the mapping.
                try conn.executeChange(query, withArgs: args)

                guard let faviconID = id else {
                    let err = DatabaseError(description: "Error adding favicon. ID = 0")
                    log.error("addFavicon(_:, forSite:) encountered an error: \(err.localizedDescription)")
                    throw err
                }

                return faviconID
            }
        }

        let siteSubselect = "(SELECT id FROM history WHERE url = ?)"
        let iconSubselect = "(SELECT id FROM favicons WHERE url = ?)"
        let insertOrIgnore = "INSERT OR IGNORE INTO favicon_sites (siteID, faviconID) VALUES "
        if let iconID = icon.id {
            // Easy!
            if let siteID = site.id {
                // So easy!
                let args: Args? = [siteID, iconID]
                return doChange("\(insertOrIgnore) (?, ?)", args: args)
            }

            // Nearly easy.
            let args: Args? = [site.url, iconID]
            return doChange("\(insertOrIgnore) (\(siteSubselect), ?)", args: args)

        }

        // Sigh.
        if let siteID = site.id {
            let args: Args? = [siteID, icon.url]
            return doChange("\(insertOrIgnore) (?, \(iconSubselect))", args: args)
        }

        // The worst.
        let args: Args? = [site.url, icon.url]
        return doChange("\(insertOrIgnore) (\(siteSubselect), \(iconSubselect))", args: args)
    }

    public func getFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        // First, attempt to lookup the favicon from our bundled top sites.
        return getTopSitesFaviconImage(forSite: site).bind { result in
            guard let image = result.successValue else {
                // Second, attempt to lookup the favicon URL from the database.
                return self.lookupFaviconURLFromDatabase(forSite: site).bind { result in
                    guard let faviconURL = result.successValue else {
                        // If it isn't in the DB, attempt to scrape its URL from the web page.
                        return self.lookupFaviconURLFromWebPage(forSite: site).bind { result in
                            guard let faviconURL = result.successValue else {
                                // Otherwise, get the default favicon image.
                                return self.generateDefaultFaviconImage(forSite: site)
                            }
                            // Try to get the favicon from the URL scraped from the web page.
                            return self.downloadFaviconImage(faviconURL: faviconURL).bind { result in
                                // If the favicon could not be downloaded, use the generated "default" favicon.
                                guard let image = result.successValue else {
                                    return self.generateDefaultFaviconImage(forSite: site)
                                }

                                return deferMaybe(image)
                            }
                        }
                    }

                    // Attempt to download the favicon from the URL found in the database.
                    return self.downloadFaviconImage(faviconURL: faviconURL).bind { result in
                        // If the favicon could not be downloaded, use the generated "default" favicon.
                        guard let image = result.successValue else {
                            return self.generateDefaultFaviconImage(forSite: site)
                        }

                        return deferMaybe(image)
                    }
                }
            }

            return deferMaybe(image)
        }
    }

    // Downloads a favicon image from the web or retrieves it from the cache.
    fileprivate func downloadFaviconImage(faviconURL: URL) -> Deferred<Maybe<UIImage>> {
        let deferred = CancellableDeferred<Maybe<UIImage>>()

        SDWebImageManager.shared.loadImage(with: faviconURL, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
            if let image = image {
                deferred.fill(Maybe(success: image))
            } else {
                deferred.fill(Maybe(failure: FaviconDownloadError(faviconURL: faviconURL.absoluteString)))
            }
        }

        return deferred
    }

    fileprivate func getTopSitesFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        guard let url = URL(string: site.url) else {
            return deferMaybe(FaviconLookupError(siteURL: site.url))
        }

        func imageFor(icon: (color: UIColor, fileURL: URL)) -> Deferred<Maybe<UIImage>> {
            guard let image = UIImage(contentsOfFile: icon.fileURL.path) else {
                return deferMaybe(FaviconLookupError(siteURL: site.url))
            }

            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            defer { UIGraphicsEndImageContext() }

            guard let context = UIGraphicsGetCurrentContext(),
                let cgImage = image.cgImage else {
                return deferMaybe(image)
            }

            let rect = CGRect(origin: .zero, size: image.size)
            context.setFillColor(icon.color.cgColor)
            context.fill(rect)
            context.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: rect.height))
            context.draw(cgImage, in: rect)

            guard let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext() else {
                return deferMaybe(image)
            }

            return deferMaybe(imageWithBackground)
        }

        let domain = url.shortDisplayString
        if multiRegionTopSitesDomains.contains(domain), let icon = topSitesIcons[domain] {
            return imageFor(icon: icon)
        }

        let urlWithoutScheme = url.absoluteDisplayString.remove("\(url.scheme ?? "")://")
        if let baseDomain = url.baseDomain, let icon = topSitesIcons[baseDomain] ?? topSitesIcons[urlWithoutScheme] {
            return imageFor(icon: icon)
        }

        return deferMaybe(FaviconLookupError(siteURL: site.url))
    }

    // Retrieves a site's previously-known favicon URL from the database.
    fileprivate func lookupFaviconURLFromDatabase(forSite site: Site) -> Deferred<Maybe<URL>> {
        let deferred = CancellableDeferred<Maybe<URL>>()

        getFaviconsForURL(site.url).upon { result in
            guard let favicons = result.successValue,
                let favicon = favicons[0],
                let faviconURLString = favicon?.url,
                let faviconURL = URL(string: faviconURLString) else {
                deferred.fill(Maybe(failure: FaviconLookupError(siteURL: site.url)))
                return
            }

            deferred.fill(Maybe(success: faviconURL))
        }

        return deferred
    }

    // Retrieve's a site's favicon URL from the web.
    fileprivate func lookupFaviconURLFromWebPage(forSite site: Site) -> Deferred<Maybe<URL>> {
        guard let url = URL(string: site.url) else {
            return deferMaybe(FaviconLookupError(siteURL: site.url))
        }

        let deferred = CancellableDeferred<Maybe<URL>>()

        getFaviconURLsFromWebPage(url: url).upon { result in
            guard let faviconURLs = result.successValue,
                let faviconURL = faviconURLs.first else {
                deferred.fill(Maybe(failure: FaviconLookupError(siteURL: site.url)))
                return
            }

            // Since we were able to scrape a favicon URL off the web page,
            // insert it into the DB to avoid having to scrape again later.
            let favicon = Favicon(url: faviconURL.absoluteString)
            self.favicons.insertOrUpdateFavicon(favicon).upon { result in
                if let faviconID = result.successValue {

                    // Also, insert a row in `favicon_site_urls` so we can
                    // look up this favicon later without requiring history.
                    // This is primarily needed for bookmarks.
                    _ = self.db.run("INSERT OR IGNORE INTO favicon_site_urls(site_url, faviconID) VALUES (?, ?)", withArgs: [site.url, faviconID])
                }
            }

            deferred.fill(Maybe(success: faviconURL))
        }

        return deferred
    }

    // Scrapes an HTMLDocument DOM from a web page URL.
    fileprivate func getHTMLDocumentFromWebPage(url: URL) -> Deferred<Maybe<HTMLDocument>> {
        let deferred = CancellableDeferred<Maybe<HTMLDocument>>()

        // getHTMLDocumentFromWebPage can be called from getFaviconURLsFromWebPage, and that function is off-main. 
        DispatchQueue.main.async {
            urlSession.dataTask(with: url) { (data, response, error) in
                guard error == nil,
                    let data = data,
                    let document = try? HTMLDocument(data: data) else {
                        deferred.fill(Maybe(failure: FaviconLookupError(siteURL: url.absoluteString)))
                        return
                }
                deferred.fill(Maybe(success: document))
            }.resume()
        }

        return deferred
    }

    // Scrapes the web page at the specified URL for its favicon URLs.
    fileprivate func getFaviconURLsFromWebPage(url: URL) -> Deferred<Maybe<[URL]>> {
        return getHTMLDocumentFromWebPage(url: url).bind { result in
            guard let document = result.successValue else {
                return deferMaybe(FaviconLookupError(siteURL: url.absoluteString))
            }

            // If we were redirected via a <meta> tag on the page to a different
            // URL, go to the redirected page for the favicon instead.
            for meta in document.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let reloadURL = URL(string: String(content[index.upperBound...])),
                    reloadURL != url {
                    return self.getFaviconURLsFromWebPage(url: reloadURL)
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

            return deferMaybe(icons)
        }
    }

    // Generates a "default" favicon based on the first character in the
    // site's domain name or gets an already-generated icon from the cache.
    fileprivate func generateDefaultFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()

        DispatchQueue.main.async {
            guard let url = URL(string: site.url), let character = url.baseDomain?.first else {
                deferred.fill(Maybe(success: defaultFavicon))
                return
            }

            let faviconLetter = String(character).uppercased()

            if let cachedFavicon = defaultFaviconImageCache[faviconLetter] {
                deferred.fill(Maybe(success: cachedFavicon))
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
            deferred.fill(Maybe(success: image))
        }
        return deferred
    }
}
