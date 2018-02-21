/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import CoreSpotlight
import MobileCoreServices
import WebKit

private let browsingActivityType: String = "org.mozilla.ios.firefox.browsing"

private let searchableIndex = CSSearchableIndex(name: "firefox")

class UserActivityHandler {
    private var tabObservers: TabObservers!

    init() {
        self.tabObservers = registerFor(
                                .didLoseFocus,
                                .didGainFocus,
                                .didChangeURL,
                                // .didLoadMetadata // TODO: Bug 1390294
                                // .didLoadFavicon, // TODO: Bug 1390294
                                .didClose,
                                queue: .main)
    }

    deinit {
        unregister(tabObservers)
    }

    class func clearSearchIndex(completionHandler: ((Error?) -> Void)? = nil) {
        searchableIndex.deleteAllSearchableItems(completionHandler: completionHandler)
    }
}

extension UserActivityHandler: TabEventHandler {
    func tabDidGainFocus(_ tab: Tab) {
        tab.userActivity?.becomeCurrent()
    }

    func tabDidLoseFocus(_ tab: Tab) {
        tab.userActivity?.resignCurrent()
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        guard url.isWebPage(includeDataURIs: false), !url.isLocal, !tab.isPrivate else {
            tab.userActivity?.resignCurrent()
            tab.userActivity = nil
            return
        }

        tab.userActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: browsingActivityType)
        userActivity.webpageURL = url
        userActivity.becomeCurrent()

        tab.userActivity = userActivity
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.userActivity else {
            return
        }
        tab.userActivity = nil
        userActivity.invalidate()
    }
}
