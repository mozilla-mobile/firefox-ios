/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared
import XCGLogger
import SDWebImage
import Fuzi
import SwiftyJSON

// Extension of FaviconFetcher that handles fetching non-bundled, non-letter favicons
extension FaviconFetcher {
    
    class func getForURL(_ url: URL, profile: Profile) -> Deferred<Maybe<[Favicon]>> {
        let favicon = FaviconFetcher()
        return favicon.loadFavicons(url, profile: profile)
    }

    fileprivate func loadFavicons(_ url: URL, profile: Profile, oldIcons: [Favicon] = [Favicon]()) -> Deferred<Maybe<[Favicon]>> {
        if isIgnoredURL(url) {
            return deferMaybe(FaviconFetcherErrorType(description: "Not fetching ignored URL to find favicons."))
        }

        let deferred = Deferred<Maybe<[Favicon]>>()

        var oldIcons: [Favicon] = oldIcons

        queue.async {
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
    
    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    fileprivate func parseHTMLForFavicons(_ url: URL) -> Deferred<Maybe<[Favicon]>> {
        return fetchDataForURL(url).bind({ result -> Deferred<Maybe<[Favicon]>> in
            var icons = [Favicon]()
            guard let data = result.successValue, result.isSuccess,
                let root = try? HTMLDocument(data: data as Data) else {
                    return deferMaybe([])
            }
            var reloadUrl: URL?
            for meta in root.xpath("//head/meta") {
                if let refresh = meta["http-equiv"], refresh == "Refresh",
                    let content = meta["content"],
                    let index = content.range(of: "URL="),
                    let url = NSURL(string: String(content[index.upperBound...])) {
                    reloadUrl = url as URL
                }
            }

            if let url = reloadUrl {
                return self.parseHTMLForFavicons(url)
            }

            for link in root.xpath("//head//link[contains(@rel, 'icon')]") {
                guard let href = link["href"] else {
                    continue //Skip the rest of the loop. But don't stop the loop
                }

                if let iconUrl = NSURL(string: href, relativeTo: url as URL), let absoluteString = iconUrl.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

                // If we haven't got any options icons, then use the default at the root of the domain.
                if let url = NSURL(string: "/favicon.ico", relativeTo: url as URL), icons.isEmpty, let absoluteString = url.absoluteString {
                    let icon = Favicon(url: absoluteString)
                    icons = [icon]
                }

            }
            return deferMaybe(icons)
        })
    }
    
    fileprivate func fetchDataForURL(_ url: URL) -> Deferred<Maybe<Data>> {
        let deferred = Deferred<Maybe<Data>>()
        urlSession.dataTask(with: url) { (data, _, error) in
            if let data = data {
                deferred.fill(Maybe(success: data))
                return
            }

            let errorDescription = (error as NSError?)?.description ?? "No content."
            deferred.fill(Maybe(failure: FaviconFetcherErrorType(description: errorDescription)))
        }.resume()

        return deferred
    }
    
    func getFavicon(_ siteUrl: URL, icon: Favicon, profile: Profile) -> Deferred<Maybe<Favicon>> {
        let deferred = Deferred<Maybe<Favicon>>()
        let url = icon.url
        let manager = SDWebImageManager.shared
        let site = Site(url: siteUrl.absoluteString, title: "")

        var fav = Favicon(url: url)
        if let url = url.asURL {
            var fetch: SDWebImageOperation?
            fetch = manager.loadImage(with: url,
                options: .lowPriority,
                progress: { (receivedSize, expectedSize, _) in
                    if receivedSize > FaviconFetcher.MaximumFaviconSize || expectedSize > FaviconFetcher.MaximumFaviconSize {
                        fetch?.cancel()
                    }
                },
                completed: { (img, _, _, _, _, url) in
                    guard let url = url else {
                        deferred.fill(Maybe(failure: FaviconError()))
                        return
                    }
                    fav = Favicon(url: url.absoluteString)

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

    // Returns the largest Favicon UIImage for a given URL
    class func fetchFavImageForURL(forURL url: URL, profile: Profile) -> Deferred<Maybe<UIImage>> {
        let deferred = Deferred<Maybe<UIImage>>()
        FaviconFetcher.getForURL(url.domainURL, profile: profile).uponQueue(.main) { result in
            var iconURL: URL?
            
            if let favicons = result.successValue, favicons.count > 0, let faviconImageURL =
                favicons.first?.url.asURL {
                iconURL = faviconImageURL
            } else {
                return deferred.fill(Maybe(failure: FaviconError()))
            }
            SDWebImageManager.shared.loadImage(with: iconURL, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                if let image = image {
                    deferred.fill(Maybe(success: image))
                } else {
                    deferred.fill(Maybe(failure: FaviconError()))
                }
            }
        }
        return deferred
    }
}
