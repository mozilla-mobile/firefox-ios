/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

// An in memory cache of urls -> [faviconUrls]
private var urlCache = LRUCache<String, [Favicon]>(cacheSize: 100)

/*
* Types of Favicons that pages might provide. Allows callers to differentiate between an article image
* favicons, and other types of images provided by the site.
*/
enum FaviconType {
    case Favicon;
    case ArticleImage;
}

/*
* Useful constants
*/
struct FaviconConsts {
    static let DefaultFaviconName : String = "defaultFavicon.png";
    static let DefaultFavicon : String = "resource://" + DefaultFaviconName;
    static let DefaultFaviconUrl : NSURL = NSURL(string: DefaultFavicon)!
}

/*
* Basic favicon class. Since this may contain image data, we don't use a struct
*/
func == (a: Favicon, b: Favicon) -> Bool {
    return a.url.absoluteString! == b.url.absoluteString!
}

class Favicon : Equatable {
    let url: NSURL

    init(url sourceUrl: NSURL) {
        self.url = sourceUrl
    }
}

/*
* Options opbject to allow specifying a preferred size or type of favicon to request
*/
struct FaviconOptions {
    let type: FaviconType;
    let desiredSize: Int;

    init(type: FaviconType, desiredSize: Int) {
        self.type = type;
        self.desiredSize = desiredSize;
    }
}

// Resizes icons to the size most of our views are using
private func createMockFavicon(icon: UIImage?) -> UIImage? {
    let size = CGSize(width: 30, height: 30)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

    var context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context);

    if (icon != nil) {
        icon!.drawInRect(CGRectInset(CGRect(origin: CGPointZero, size: size), 1.0, 1.0))
    }

    // restore state
    CGContextRestoreGState(context);

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
}

protocol Favicons {
    func getForUrls(urls: [NSURL], options: FaviconOptions?, callback: (ArrayCursor<[Favicon]>) -> Void)
    func getForUrl(url: NSURL, options: FaviconOptions?, callback: ([Favicon]) -> Void)
    func getForUrlSync(url: NSURL, options: FaviconOptions?) -> [Favicon]
    func loadIntoCell(url: String, view: UITableViewCell)
}

/*
* A Base favicon implementation, Always returns a default for now.
*/
class BasicFavicons : Favicons {
    lazy var DEFAULT_IMAGE : UIImage = {
        var img = UIImage(named: FaviconConsts.DefaultFaviconName)!
        return img;
    }();

    init() {
    }

    private func addToCache(url: NSURL, favicons: [Favicon]) {
        urlCache[url.absoluteString!] = favicons
    }

    // Convenience function for async loading into tableViewCells
    func loadIntoCell(url: String, view: UITableViewCell) {
        ImageLoader(siteUrlCallback: { () -> NSURL in
            var favicons = self.getForUrlSync(NSURL(string: url)!, options: nil)
            return favicons[0].url
        })
            .placeholder(FaviconConsts.DefaultFaviconUrl)
            .then(createMockFavicon) // Size the icon to the correct size for our lists
            .into(view.imageView)
            .then({ img -> UIImage? in
                view.setNeedsLayout()
                return img
        })
    }

    // Synchronously gets the favicon for a url
    func getForUrlSync(url: NSURL, options: FaviconOptions?) -> [Favicon] {
        // Load from the cache if we can
        if var favicons = urlCache[url.absoluteString!] {
            return favicons as [Favicon]
        }

        // Otherwise fetch the page
        var favicons = FaviconFetcher(url: url).favicons
        if (favicons.count > 0) {
            addToCache(url, favicons: favicons)
            return favicons
        }

        // If that failed, just use the default
        let favicon = Favicon(url: FaviconConsts.DefaultFaviconUrl)
        addToCache(url, favicons: [favicon])
        return [favicon]
    }

    // Asynchronously finds the favicons associated with an array of urls
    func getForUrls(urls: [NSURL], options: FaviconOptions?, callback: (ArrayCursor<[Favicon]>) -> Void) {
        // Do an async dispatch to ensure this behaves like an async api
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () in
            var data : [[Favicon]] = [];
            for url in urls {
                data.append(self.getForUrlSync(url, options: options));
            }

            let ret = ArrayCursor<[Favicon]>(data: data);
            dispatch_async(dispatch_get_main_queue(), { () in
                callback(ret);
            });
        });
    }

    // Asynchronously finds the favicons associated with a url
    func getForUrl(url: NSURL, options: FaviconOptions?, callback: ([Favicon]) -> Void) {
        let urls: [NSURL] = [url];
        getForUrls(urls, options: options, callback: { (cursor: ArrayCursor<[Favicon]>) -> Void in
            if var group = cursor[0] {
                callback(group);
            } else {
                callback(self.getForUrlSync(url, options: options));
            }
        })
    }
}

/* A helper class to find the favicon associated with a url. This will load the page and parse any icons it finds out of it
 * If that fails, it will attempt to find a favicon.ico in the root host domain
 */
class FaviconFetcher : NSObject {
    private let siteUrl: NSURL // The url we're looking for favicons for
    private var _favicons :[Favicon]? = nil // An internal cache of favicons found for this url

    init(url: NSURL) {
        siteUrl = url
    }

    // Gets a list of favicons at this url. This will initialize a synchronous http request. The results are cached in this object
    // so if you want to repeat the lookup you must create a new FaviconFetcher object.
    var favicons : [Favicon] {
        get {
            if _favicons != nil {
                return _favicons!;
            }

            _favicons = [Favicon]();
            // Initially look for tags in the page
            loadFromDoc()

            // If that didn't find anything, look for a favicon.ico for this host
            if _favicons!.count == 0 {
                loadFromHost()
            }

            return _favicons!
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
                _favicons!.append(Favicon(url: url!))
            }
        }
    }

    // Loads and parses an html document and tries to find any known favicon-type tags for the page
    private func loadFromDoc() {
        var err: NSError?
        if var doc = HTMLDocument(contentsOfURL: siteUrl, error: &err) {
            if var head = doc.head {
                for node in head.childrenOfTag("link") {
                    if var rel = node.attributes!["rel"] {
                        if (rel == "shortcut icon" || rel == "icon" || rel == "apple-touch-icon") {
                            if var href = node.attributes!["href"] {
                                if var url = NSURL(string: href, relativeToURL: siteUrl) {
                                    _favicons!.append(Favicon(url: url))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
