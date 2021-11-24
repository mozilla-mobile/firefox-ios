// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
import Storage
import Shared

// This cannot be easily imported into extension targets, so we break it out here.
extension SavedTab {
    convenience init?(tab: Tab, isSelected: Bool) {
        assert(Thread.isMainThread)
        
        var sessionData = tab.sessionData
        if sessionData == nil {
            let currentItem: WKBackForwardListItem! = tab.webView?.backForwardList.currentItem

            // Freshly created web views won't have any history entries at all.
            // If we have no history, abort.
            if currentItem != nil {
                // The back & forward list keep track of the users history within the session
                let backList = tab.webView?.backForwardList.backList ?? []
                let forwardList = tab.webView?.backForwardList.forwardList ?? []
                let urls = (backList + [currentItem] + forwardList).map { $0.url }
                let currentPage = -forwardList.count
                sessionData = SessionData(currentPage: currentPage, urls: urls, lastUsedTime: tab.lastExecutedTime ?? Date.now())
            }
        }
        
        self.init(screenshotUUID: tab.screenshotUUID, isSelected: isSelected, title: tab.title ?? tab.lastTitle, isPrivate: tab.isPrivate, faviconURL: tab.displayFavicon?.url, url: tab.url, sessionData: sessionData, uuid: tab.tabUUID, tabGroupData: tab.tabGroupData, createdAt: tab.firstCreatedTime, hasHomeScreenshot: tab.hasHomeScreenshot)
    }
    
    func configureSavedTabUsing(_ tab: Tab, imageStore: DiskImageStore? = nil) -> Tab {
        // Since this is a restored tab, reset the URL to be loaded as that will be handled by the SessionRestoreHandler
        tab.url = nil

        if let faviconURL = faviconURL {
            let icon = Favicon(url: faviconURL, date: Date())
            icon.width = 1
            tab.favicons.append(icon)
        }

        if let screenshotUUID = screenshotUUID, let imageStore = imageStore {
            tab.screenshotUUID = screenshotUUID
            if let uuidString = tab.screenshotUUID?.uuidString {
                imageStore.get(uuidString) >>== { screenshot in
                    if tab.screenshotUUID == screenshotUUID {
                        tab.setScreenshot(screenshot)
                    }
                }
            }
        }

        tab.sessionData = sessionData
        tab.lastTitle = title
        tab.tabUUID = UUID ?? ""
        tab.tabGroupData = tabGroupData ?? tab.tabGroupData
        tab.screenshotUUID = screenshotUUID
        tab.firstCreatedTime = createdAt ?? sessionData?.lastUsedTime ?? Date.now()
        tab.hasHomeScreenshot = hasHomeScreenshot
        return tab
    }
}
