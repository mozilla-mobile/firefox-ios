/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCGLogger
import UIKit
import Shared

private let log = XCGLogger.defaultInstance()

public class SuggestedSite: Site {
    public let wordmark: Favicon
    public let backgroundColor: UIColor

    let trackingId: Int
    init(json: JSON) {
        self.backgroundColor = UIColor(colorString: json["bgcolor"].asString!)
        self.trackingId = json["trackingid"].asInt ?? 0
        self.wordmark = Favicon(url: json["imageurl"].asString!, date: NSDate(), type: .Icon)

        super.init(url: json["url"].asString!, title: json["title"].asString!)

        self.icon = Favicon(url: json["faviconUrl"].asString!, date: NSDate(), type: .Icon)
    }
}

public let SuggestedSites: SuggestedSitesData<SuggestedSite> = SuggestedSitesData<SuggestedSite>()

public class SuggestedSitesData<T>: ArrayCursor<SuggestedSite> {
    private init() {
        // TODO: Make this list localized. That should be as simple as making sure it's in the lproj directory.
        let path = NSBundle.mainBundle().pathForResource("suggestedsites", ofType: "json")
        let data = try? NSString(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        let json = JSON.parse(data as! String)

        var tiles = [SuggestedSite]()
        for i in 0..<json.length {
            let t = SuggestedSite(json: json[i])
            tiles.append(t)
        }

        super.init(data: tiles, status: .Success, statusMessage: "Loaded")
    }
}
