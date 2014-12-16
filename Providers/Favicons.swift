/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import CoreData

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
    static let DefaultFaviconName : String = "leaf.png"
    static let DefaultFavicon : String = "resource:" + DefaultFaviconName
    static let DefaultFaviconUrl : NSURL = NSURL(string: DefaultFavicon)!
}

protocol Favicons {
    func clearFavicons(siteUrl: String, callback: () -> Void)
    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage?, callback: () -> Void)
    func getForUrls(urls: [String], options: FaviconOptions?, callback: ([String: [Favicon]]) -> Void)
    func getForUrl(url: String, options: FaviconOptions?, callback: ([Favicon]) -> Void)
}

/*
 * Options opbject to allow specifying a preferred size or type of favicon to request
 */
struct FaviconOptions {
    let type: FaviconType
    let desiredSize: Int

    init(type: FaviconType, desiredSize: Int) {
        self.type = type;
        self.desiredSize = desiredSize;
    }
}

class BasicFavicons : Favicons {
    private let faviconCache: GenericCache<String, [Favicon]>

    init() {
        let f = Favicon.MR_createEntity()
        f.url = FaviconConsts.DefaultFavicon
        f.updatedDate = NSDate()

        faviconCache = OrderedCache<String, [Favicon]>(caches: [
            LRUCache(cacheSize: 10), // An in memory cache of recent favicons
            CoreDataFaviconCache(),  // A CoreData cache of favicons
            DefaultCache(def: [f])   // Always returns the default icon
        ])

    }

    func clearFavicons(siteUrl: String, callback: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { _ in
            self.faviconCache[siteUrl] = nil

            dispatch_async(dispatch_get_main_queue()) { _ in
                callback()
            }
        }
    }

    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage? = nil, callback: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { _ in

            var f = Favicon.MR_createEntity()
            f.url = iconUrl
            if let i = image {
                f.image = i
            }

            if var favicons = self.faviconCache[siteUrl] {
                // If the only favicon we found was the default, don't use it!
                // XXX - This is dumb of me...
                if (favicons.count == 1 && favicons[0].url == FaviconConsts.DefaultFavicon) {
                    self.faviconCache[siteUrl] = [f]
                } else {
                    favicons.append(f)
                    self.faviconCache[siteUrl] = favicons
                }
            } else {
                self.faviconCache[siteUrl] = [f]
            }

            dispatch_async(dispatch_get_main_queue(), { _ in
                callback()
            })
        })
    }

    func getForUrls(urls: [String], options: FaviconOptions?, callback: ([String: [Favicon]]) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () in
            var data = [String: [Favicon]]()
            for url in urls {
                if let icons = self.faviconCache[url] {
                    data[url] = icons
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () in
                callback(data)
            })
        }
    }
    
    func getForUrl(url: String, options: FaviconOptions?, callback: ([Favicon]) -> Void) {
        let urls = [url];
        getForUrls(urls, options: options, callback: { data in
            var icons = data[url]
            callback(icons!)
        })
    }
}


public func createSizedFavicon(icon: UIImage) -> UIImage {
    let size = CGSize(width: 30, height: 30)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    var context = UIGraphicsGetCurrentContext()
    icon.drawInRect(CGRectInset(CGRect(origin: CGPointZero, size: size), 1.0, 1.0))
    CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
    CGContextSetLineWidth(context, 0.5);
    CGContextStrokeEllipseInRect(context, CGRectInset(CGRect(origin: CGPointZero, size: size), 1.0, 1.0))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
