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
                                .didLoadPageMetadata,
                                // .didLoadFavicon, // only useful when we fix Bug 1390200.
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

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        guard let url = tab.canonicalURL else {
            tabDidLoseFocus(tab)
            tab.userActivity = nil
            return
        }

        tab.userActivity?.invalidate()

        let userActivity = NSUserActivity(activityType: browsingActivityType)
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeHTML as String)

        userActivity.title = metadata.title
        userActivity.webpageURL = url
        userActivity.keywords = metadata.keywords
        userActivity.isEligibleForSearch = false
        userActivity.isEligibleForHandoff = true

        attributeSet.contentURL = url
        attributeSet.title = metadata.title
        attributeSet.contentDescription = metadata.description

        userActivity.contentAttributeSet = attributeSet

        tab.userActivity = userActivity

        userActivity.becomeCurrent()
    }

    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with data: Data?) {
        guard let url = tab.canonicalURL,
            let userActivity = tab.userActivity,
            let attributeSet = userActivity.contentAttributeSet,
            !tab.isPrivate else {
                return
        }

        attributeSet.thumbnailData = data
        let searchableItem = CSSearchableItem(uniqueIdentifier: url.absoluteString, domainIdentifier: "webpages", attributeSet: attributeSet)
        searchableIndex.indexSearchableItems([searchableItem])

        userActivity.needsSave = true
    }

    func tabDidClose(_ tab: Tab) {
        guard let userActivity = tab.userActivity else {
            return
        }
        tab.userActivity = nil
        userActivity.invalidate()
    }
}
