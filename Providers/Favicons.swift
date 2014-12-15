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
    func clearFavicons(siteUrl: String, success: () -> Void, failure: (Any) -> Void)
    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage?, success: (Favicon) -> Void, failure: (Any) -> Void)
    func getForUrls(urls: [String], options: FaviconOptions?, success: ([String: [Favicon]]) -> Void)
    func getForUrl(url: String, options: FaviconOptions?, success: (Favicon) -> Void)
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

    func clearFavicons(siteUrl: String, success: () -> Void, failure: (Any) -> Void) {
        MagicalRecord.saveWithBlock({ context in
            var site = Site.MR_findFirstByAttribute("url", withValue: siteUrl)
            if site == nil {
                return
            }

            for favicon in site.favicons {
                if var f = favicon as? Favicon {
                    favicon.MR_deleteEntityInContext(context)
                }
            }
        }, { (s, error) in
            if error == nil {
                success()
            } else {
                failure(error)
            }
        })
    }

    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage? = nil, success: (Favicon) -> Void, failure: (Any) -> Void) {
        var icon: Favicon = Favicon()
        MagicalRecord.saveWithBlock({ context in
            var site = Site.MR_findFirstOrCreateByAttribute("url", withValue: siteUrl)
            icon = Favicon.MR_findFirstOrCreateByAttribute("url", withValue: iconUrl)
            if (site.favicons.containsObject(icon)) {
                return
            }

            icon.updatedDate = NSDate()
            if image != nil {
                icon.image = image!
            }

            site.addFavicon(icon)
        }, { (s, error) in
            if (error == nil) {
                success(icon)
            } else {
                failure(error)
            }
        })
    }

    func getForUrls(urls: [String], options: FaviconOptions?, success: ([String: [Favicon]]) -> Void) {
        // Do an async dispatch to ensure this behaves like an async api
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () in
            var data = [String: [Favicon]]()
            for url in urls {
                // XXX: Do we want to block here?
                var site = Site.MR_findFirstOrCreateByAttribute("url", withValue: url)
                if site.favicons.count > 0 {
                    data[url] = site!.favicons.allObjects as [Favicon]
                } else {
                    // If we didn't find a site or a favicon, create (and save) them
                    let icon = Favicon.MR_createEntity() as Favicon
                    icon.url = FaviconConsts.DefaultFavicon
                    icon.updatedDate = NSDate()
                    icon.image = self.DEFAULT_IMAGE;

                    site!.addFavicon(icon)
                    data[url] = [icon]
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () in
                success(data)
            })
        })
    }
    
    func getForUrl(url: String, options: FaviconOptions?, success: (Favicon) -> Void) {
        let urls = [url];
        getForUrls(urls, options: options, success: { data in
            var icons = data[url]
            success(icons![0])
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
