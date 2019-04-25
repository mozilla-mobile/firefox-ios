/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Fuzi
import SDWebImage
import Shared
import XCGLogger

private let log = Logger.syncLogger

// Set up Alamofire for downloading web content for parsing.
// NOTE: We use the desktop UA to try and get hi-res icons.
private var alamofire: SessionManager = {
    var sessionManager: SessionManager!
    DispatchQueue.main.sync {
        let configuration = URLSessionConfiguration.default
        var defaultHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = UserAgent.desktopUserAgent()
        configuration.httpAdditionalHeaders = defaultHeaders
        configuration.timeoutIntervalForRequest = 5
        sessionManager = SessionManager(configuration: configuration)
    }
    return sessionManager
}()

// If all else fails, this is the default "default" icon.
private var defaultFavicon: UIImage = {
    return UIImage(named: "defaultFavicon")!
}()

// An in-memory cache of "default" favicons keyed by the
// first character of a site's domain name.
private var defaultFaviconImageCache = [String : UIImage]()

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
    // These two getter functions are only exposed for testing purposes (and aren't part of the public interface).
    func getFaviconsForURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = """
            SELECT iconID AS id, iconURL AS url, iconDate AS date, iconType AS type, iconWidth AS width
            FROM view_favicons_widest, history
            WHERE history.id = siteID AND history.url = ?
            """

        let args: Args = [url]
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    func getFaviconsForBookmarkedURL(_ url: String) -> Deferred<Maybe<Cursor<Favicon?>>> {
        let sql = """
            SELECT
                favicons.id AS id,
                favicons.url AS url,
                favicons.date AS date,
                favicons.type AS type,
                favicons.width AS width
            FROM favicons, view_bookmarksLocal_on_mirror AS bm
            WHERE bm.faviconID = favicons.id AND bm.bmkUri IS ?
            """

        let args: Args = [url]
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconColumnFactory)
    }

    public func getSitesForURLs(_ urls: [String]) -> Deferred<Maybe<Cursor<Site?>>> {
        let inExpression = urls.joined(separator: "\",\"")
        let sql = """
        SELECT history.id AS historyID, history.url AS url, title, guid, iconID, iconURL, iconDate, iconType, iconWidth
        FROM view_favicons_widest, history
        WHERE history.id = siteID AND history.url IN (\"\(inExpression)\")
        """

        let args: Args = []
        return db.runQueryConcurrently(sql, args: args, factory: SQLiteHistory.iconHistoryColumnFactory)
    }

    public func clearAllFavicons() -> Success {
        return db.transaction { conn -> Void in
            try conn.executeChange("DELETE FROM favicon_sites")
            try conn.executeChange("DELETE FROM favicons")
        }
    }

    public func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>> {
        return self.favicons.insertOrUpdateFavicon(icon)
    }

    /**
     * This method assumes that the site has already been recorded
     * in the history table.
     */
    public func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>> {
        if Logger.logPII {
            log.verbose("Adding favicon \(icon.url) for site \(site.url).")
        }
        func doChange(_ query: String, args: Args?) -> Deferred<Maybe<Int>> {
            return db.withConnection { conn -> Int in
                // Blind! We don't see failure here.
                let id = self.favicons.insertOrUpdateFaviconInTransaction(icon, conn: conn)

                // Now set up the mapping.
                try conn.executeChange(query, withArgs: args)

                // Try to update the favicon ID column in each bookmarks table. There can be
                // multiple bookmarks with a particular URI, and a mirror bookmark can be
                // locally changed, so either or both of these statements can update multiple rows.
                if let id = id {
                    icon.id = id

                    try? conn.executeChange("UPDATE bookmarksLocal SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])
                    try? conn.executeChange("UPDATE bookmarksMirror SET faviconID = ? WHERE bmkUri = ?", withArgs: [id, site.url])

                    return id
                }

                let err = DatabaseError(description: "Error adding favicon. ID = 0")
                log.error("addFavicon(_:, forSite:) encountered an error: \(err.localizedDescription)")
                throw err
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
        // First, attempt to lookup the favicon URL from the database.
        return lookupFaviconURLFromDatabase(forSite: site).bind { result in
            guard let faviconURL = result.successValue else {

                // If it isn't in the database, attempt to scrape its
                // URL from the web page.
                return self.lookupFaviconURLFromWebPage(forSite: site).bind { result in
                    guard let faviconURL = result.successValue else {

                        // Otherwise, get the default favicon image.
                        return self.getDefaultFaviconImage(forSite: site)
                    }

                    // Attempt to download the favicon from the URL scraped from
                    // the web page.
                    return self.downloadFaviconImage(faviconURL: faviconURL).bind { result in

                        // If the favicon could not be downloaded, use the generated
                        // "default" favicon.
                        guard let image = result.successValue else {
                            return self.getDefaultFaviconImage(forSite: site)
                        }

                        return deferMaybe(image)
                    }
                }
            }

            // Attempt to download the favicon from the URL found in the database.
            return self.downloadFaviconImage(faviconURL: faviconURL).bind { result in

                // If the favicon could not be downloaded, use the generated
                // "default" favicon.
                guard let image = result.successValue else {
                    return self.getDefaultFaviconImage(forSite: site)
                }

                return deferMaybe(image)
            }
        }
    }

    // Downloads a favicon image from the web or retrieves it from the cache.
    fileprivate func downloadFaviconImage(faviconURL: URL) -> Deferred<Maybe<UIImage>> {
        let deferred = CancellableDeferred<Maybe<UIImage>>()

        SDWebImageManager.shared().loadImage(with: faviconURL, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
            if let image = image {
                deferred.fill(Maybe(success: image))
            } else {
                deferred.fill(Maybe(failure: FaviconDownloadError(faviconURL: faviconURL.absoluteString)))
            }
        }

        return deferred
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

            deferred.fill(Maybe(success: faviconURL))
        }

        return deferred
    }

    // Scrapes an HTMLDocument DOM from a web page URL.
    fileprivate func getHTMLDocumentFromWebPage(url: URL) -> Deferred<Maybe<HTMLDocument>> {
        let deferred = CancellableDeferred<Maybe<HTMLDocument>>()

        alamofire.request(url).response { response in
            guard response.error == nil,
                let data = response.data,
                let document = try? HTMLDocument(data: data) else {
                deferred.fill(Maybe(failure: FaviconLookupError(siteURL: url.absoluteString)))
                return
            }

            deferred.fill(Maybe(success: document))
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
    fileprivate func getDefaultFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>> {
        guard let url = URL(string: site.url),
            let character = url.baseDomain?.first else {
            return deferMaybe(defaultFavicon)
        }

        let faviconLetter = String(character).uppercased()

        if let cachedFavicon = defaultFaviconImageCache[faviconLetter] {
            return deferMaybe(cachedFavicon)
        }

        let deferred = Deferred<Maybe<UIImage>>()

        DispatchQueue.main.async {
            var image = UIImage()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
            label.text = faviconLetter
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 40, weight: UIFont.Weight.medium)
            label.textColor = UIColor.Photon.White100
            UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
            label.layer.render(in: UIGraphicsGetCurrentContext()!)
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            defaultFaviconImageCache[faviconLetter] = image
            deferred.fill(Maybe(success: image))
        }

        return deferred
    }
}

public class DeferredFaviconOperation: CancellableDeferred<Maybe<UIImage>> {
    fileprivate var httpRequest: URLRequest?

    override open func cancel() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if running {
            // kill DB request?
            // kill HTTP request
            //            httpRequest?.cancel()
        }

        super.cancel()
    }
}
