/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Photos
import UIKit
import WebKit
import Shared
import Storage
import SnapKit
import XCGLogger
import Alamofire
import Account
import ReadingList
import MobileCoreServices
import WebImage

class BrowserActions {
    var profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    func addBookmark(site: Site) {
            let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
            profile.bookmarks.shareItem(shareItem)
            if #available(iOS 9, *) {
                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.OpenLastBookmark,
                                                                                    withUserData: userData,
                                                                                    toApplication: UIApplication.sharedApplication())
            }
    }

    func removeBookmark(site: Site) {
            profile.bookmarks.modelFactory >>== {
                $0.removeByURL(site.url)
                    .uponQueue(dispatch_get_main_queue()) { _ in
                }
        }
    }
}