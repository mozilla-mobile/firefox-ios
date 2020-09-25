/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry
import Shared

// This extension is for WidgetKit to fetch top sites
extension SiteArchiver {
    static func fetchTopSitesForWidget(topSiteArchivePath: String?) -> [TopSite] {
        guard let topSiteArchivePath = topSiteArchivePath,
              FileManager.default.fileExists(atPath: topSiteArchivePath),
              let tabData = try? Data(contentsOf: URL(fileURLWithPath: topSiteArchivePath)) else {
            return [TopSite]()
        }
        
        let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.setClass(TopSite.self, forClassName: "Client.TopSite")
        
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "topSites") as? [TopSite] else {
            print("failed to restore topSites")
            Sentry.shared.send(
                message: "Failed to restore topSites",
                tag: SentryTag.tabManager,
                severity: .error,
                description: "\(unarchiver.error ??? "nil")")
            return [TopSite]()
        }
        return tabs
    }
}

// Helper class to fetch TopSite for widgetkit
class TopSite: NSObject, NSCoding {
    required init?(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: "url") as! String
        self.title = aDecoder.decodeObject(forKey: "title") as! String
        self.faviconUrl = aDecoder.decodeObject(forKey: "faviconUrl") as! String?
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: "url")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(faviconUrl, forKey: "faviconUrl")
    }

    internal init(url: String, title: String, faviconUrl: String?) {
        self.url = url
        self.title = title
        self.faviconUrl = faviconUrl
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let site = object as? TopSite else { return false }
        return self.url == site.url
    }
    
    let url: String
    let title: String
    let faviconUrl: String?
}
