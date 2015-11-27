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
    init(data: SuggestedSiteData) {
        self.backgroundColor = UIColor(colorString: data.bgColor)
        self.trackingId = data.trackingId
        self.wordmark = Favicon(url: data.imageUrl, date: NSDate(), type: .Icon)
        super.init(url: data.url, title: data.title)
        self.icon = Favicon(url: data.faviconUrl, date: NSDate(), type: .Icon)
    }
}

public let SuggestedSites: SuggestedSitesCursor = SuggestedSitesCursor()

public class SuggestedSitesCursor: ArrayCursor<SuggestedSite> {
    private init() {
        let locale = NSLocale.currentLocale()
        let sites = DefaultSuggestedSites.sites[locale.localeIdentifier] ??
                    DefaultSuggestedSites.sites["default"]! as Array<SuggestedSiteData>
        let tiles = sites.map({data in SuggestedSite(data: data)})
        super.init(data: tiles, status: .Success, statusMessage: "Loaded")
    }
}

public struct SuggestedSiteData {
    var url: String
    var bgColor: String
    var imageUrl: String
    var faviconUrl: String
    var trackingId: Int
    var title: String
}
