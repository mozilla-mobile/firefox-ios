/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

/*
 * Types of Favicons that pages might provide. Allows callers to differentiate between an article image
 * favicons, and other types of images provided by the site.
 */
enum FaviconType {
    case FAVICON;
    case ARTICLE_IMAGE;
}

/*
* Useful constants
*/
struct FaviconConsts {
    static let DEFAULT_FAVICON_NAME : String = "leaf.png";
    static let DEFAULT_FAVICON : String = "resource:" + DEFAULT_FAVICON_NAME;
    static let DEFAULT_FAVICON_URL : NSURL = NSURL(string: DEFAULT_FAVICON)!
}

/*
 * Basic favicon class. Since this may contain image data, we don't use a struct
 */
class Favicon {
    var img: UIImage?;
    var siteUrl: NSURL?;
    let sourceUrl: NSURL?;

    init(siteUrl: NSURL?, sourceUrl: NSURL?) {
        self.siteUrl = siteUrl;
        self.sourceUrl = sourceUrl;
    }

    func setSite(url: NSURL) -> Favicon {
        siteUrl = url;
        return self;
    }
}

protocol Favicons {
    func getForUrls(urls: [NSURL], options: FaviconOptions?, callback: (ArrayCursor<Favicon>) -> Void);
    func getForUrl(url: NSURL, options: FaviconOptions?, callback: (Favicon) -> Void);
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

/*
 * A Base favicon implementation, Always returns a default for now.
 */
class BasicFavicons : Favicons {
    lazy var DEFAULT_IMAGE : UIImage = {
        var img = UIImage(named: FaviconConsts.DEFAULT_FAVICON_NAME)!
        return img;
    }();

    init() {
    }

    func getForUrls(urls: [NSURL], options: FaviconOptions?, callback: (ArrayCursor<Favicon>) -> Void) {

        // Do an async dispatch to ensure this behaves like an async api
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () in
            var data : [Favicon] = [];
            for url in urls {
                let def = Favicon(siteUrl: url, sourceUrl: FaviconConsts.DEFAULT_FAVICON_URL);
                def.img = self.DEFAULT_IMAGE;
                data.append(def);
            }
            
            let ret = ArrayCursor<Favicon>(data: data);
            dispatch_async(dispatch_get_main_queue(), { () in
                callback(ret);
            });
        });
    }
    
    func getForUrl(url: NSURL, options: FaviconOptions?, callback: (Favicon) -> Void) {
        let urls: [NSURL] = [url];
        getForUrls(urls, options: options, callback: { (cursor: ArrayCursor<Favicon>) -> Void in
            if var group = cursor[0] {
                callback(group);
            } else {
                let def = Favicon(siteUrl: url, sourceUrl: FaviconConsts.DEFAULT_FAVICON_URL);
                def.img = self.DEFAULT_IMAGE;
                callback(def);
            }
            return;
        })
    }
}
