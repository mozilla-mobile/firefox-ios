/* This Source Code Form is subject to the terms of the Mozilla Public
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
}

/*
 * Useful constants
 */
struct FaviconConsts {
    static let DefaultFaviconName : String = "leaf.png"
    static let DefaultFavicon : String = "resource:" + DefaultFaviconName
    static let DefaultFaviconUrl : NSURL = NSURL(string: DefaultFavicon)!
}

/*
 * Options opbject to allow specifying a preferred size or type of favicon to request
 */
struct FaviconOptions {
    let type: FaviconType
    let desiredSize: Int
}

protocol Favicons {
    func clearFavicons(siteUrl: String, success: () -> Void, failure: (Any) -> Void)
    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage?, success: (Favicon) -> Void, failure: (Any) -> Void)
    func getForUrls(urls: [String], options: FaviconOptions?, success: ([String: [Favicon]]) -> Void)
    func getForUrl(url: String, options: FaviconOptions?, success: (Favicon) -> Void)
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
        failure("Not implemented")
    }

    func saveFavicon(siteUrl: String, iconUrl: String, image: UIImage? = nil, success: (Favicon) -> Void, failure: (Any) -> Void) {
        failure("Not implemented")
    }

    func getForUrls(urls: [String], options: FaviconOptions?, success: ([String: [Favicon]]) -> Void) {
        let result = [String:[Favicon]]()
        success(result)
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
