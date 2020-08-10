//
//  SavedTab+ConfigureExtension.swift
//  Client
//
//  Created by Sawyer Blatz on 8/19/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import WebKit
import Storage
import Shared

// This cannot be easily imported into extension targets, so we break it out here.
extension SavedTab {
    // TODO: Just directly pass properties in 😬
    convenience init?(tab: Tab, isSelected: Bool) {
        assert(Thread.isMainThread)
        self.init()
        
        self.screenshotUUID = tab.screenshotUUID as UUID?
        self.isSelected = isSelected
        self.title = tab.displayTitle
        self.isPrivate = tab.isPrivate
        self.faviconURL = tab.displayFavicon?.url
        self.url = tab.url
        
        if tab.sessionData == nil {
            let currentItem: WKBackForwardListItem! = tab.webView?.backForwardList.currentItem
            
            // Freshly created web views won't have any history entries at all.
            // If we have no history, abort.
            if currentItem == nil {
                return nil
            }
            
            let backList = tab.webView?.backForwardList.backList ?? []
            let forwardList = tab.webView?.backForwardList.forwardList ?? []
            let urls = (backList + [currentItem] + forwardList).map { $0.url }
            let currentPage = -forwardList.count
            self.sessionData = SessionData(currentPage: currentPage, urls: urls, lastUsedTime: tab.lastExecutedTime ?? Date.now())
        } else {
            self.sessionData = tab.sessionData
        }
    }
    
    func configureSavedTabUsing(_ tab: Tab, imageStore: DiskImageStore? = nil) -> Tab {
        // Since this is a restored tab, reset the URL to be loaded as that will be handled by the SessionRestoreHandler
        tab.url = nil

        if let faviconURL = faviconURL {
            let icon = Favicon(url: faviconURL, date: Date())
            icon.width = 1
            tab.favicons.append(icon)
        }

        if let screenshotUUID = screenshotUUID,
            let imageStore = imageStore {
            tab.screenshotUUID = screenshotUUID
            imageStore.get(screenshotUUID.uuidString) >>== { screenshot in
                if tab.screenshotUUID == screenshotUUID {
                    tab.setScreenshot(screenshot, revUUID: false)
                }
            }
        }

        tab.sessionData = sessionData
        tab.lastTitle = title

        return tab
    }
}
