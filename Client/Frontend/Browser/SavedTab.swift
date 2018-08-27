/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

class SavedTab: NSObject, NSCoding {
    let isSelected: Bool
    let title: String?
    let isPrivate: Bool
    var sessionData: SessionData?
    var screenshotUUID: UUID?
    var faviconURL: String?
    
    var jsonDictionary: [String: AnyObject] {
        let title: String = self.title ?? "null"
        let faviconURL: String = self.faviconURL ?? "null"
        let uuid: String = self.screenshotUUID?.uuidString ?? "null"
        
        var json: [String: AnyObject] = [
            "title": title as AnyObject,
            "isPrivate": String(self.isPrivate) as AnyObject,
            "isSelected": String(self.isSelected) as AnyObject,
            "faviconURL": faviconURL as AnyObject,
            "screenshotUUID": uuid as AnyObject
        ]
        
        if let sessionDataInfo = self.sessionData?.jsonDictionary {
            json["sessionData"] = sessionDataInfo as AnyObject?
        }
        
        return json
    }
    
    init?(tab: Tab, isSelected: Bool) {
        assert(Thread.isMainThread)
        
        self.screenshotUUID = tab.screenshotUUID as UUID?
        self.isSelected = isSelected
        self.title = tab.displayTitle
        self.isPrivate = tab.isPrivate
        self.faviconURL = tab.displayFavicon?.url
        super.init()
        
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
    
    required init?(coder: NSCoder) {
        self.sessionData = coder.decodeObject(forKey: "sessionData") as? SessionData
        self.screenshotUUID = coder.decodeObject(forKey: "screenshotUUID") as? UUID
        self.isSelected = coder.decodeBool(forKey: "isSelected")
        self.title = coder.decodeObject(forKey: "title") as? String
        self.isPrivate = coder.decodeBool(forKey: "isPrivate")
        self.faviconURL = coder.decodeObject(forKey: "faviconURL") as? String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(sessionData, forKey: "sessionData")
        coder.encode(screenshotUUID, forKey: "screenshotUUID")
        coder.encode(isSelected, forKey: "isSelected")
        coder.encode(title, forKey: "title")
        coder.encode(isPrivate, forKey: "isPrivate")
        coder.encode(faviconURL, forKey: "faviconURL")
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
