/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
import WebImage
import ShimWK

private let log = Logger.browserLogger

// Removed Clearables as part of Bug 1226654, but keeping the string around.
private let removedSavedLoginsLabel = NSLocalizedString("Saved Logins", tableName: "ClearPrivateData", comment: "Settings item for clearing passwords and login data")

// A base protocol for something that can be cleared.
protocol Clearable {
    func clear() -> Success
    var label: String { get }
}

class ClearableError: MaybeErrorType {
    private let msg: String
    init(msg: String) {
        self.msg = msg
    }

    var description: String { return msg }
}

// Clears our browsing history, including favicons and thumbnails.
class HistoryClearable: Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    var label: String {
        return NSLocalizedString("Browsing History", tableName: "ClearPrivateData", comment: "Settings item for clearing browsing history")
    }

    func clear() -> Success {
        return profile.history.clearHistory().bind { success in
            SDImageCache.sharedImageCache().clearDisk()
            SDImageCache.sharedImageCache().clearMemory()
            self.profile.recentlyClosedTabs.clearTabs()
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationPrivateDataClearedHistory, object: nil)
            log.debug("HistoryClearable succeeded: \(success).")
            return Deferred(value: success)
        }
    }
}

struct ClearableErrorType: MaybeErrorType {
    let err: ErrorType

    init(err: ErrorType) {
        self.err = err
    }

    var description: String {
        return "Couldn't clear: \(err)."
    }
}

// Clear the web cache. Note, this has to close all open tabs in order to ensure the data
// cached in them isn't flushed to disk.
class CacheClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Cache", tableName: "ClearPrivateData", comment: "Settings item for clearing the cache")
    }

    func clear() -> Success {
        let dataTypes = Set([ShimWKWebsiteDataTypeDiskCache, ShimWKWebsiteDataTypeMemoryCache])
        ShimWKWebsiteDataStore.defaultDataStore().removeDataOfTypes(dataTypes, modifiedSince: NSDate.distantPast(), completionHandler: {})

        log.debug("CacheClearable succeeded.")
        return succeed()
    }
}

private func deleteLibraryFolderContents(folder: String) throws {
    let manager = NSFileManager.defaultManager()
    let library = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0]
    let dir = library.URLByAppendingPathComponent(folder)
    let contents = try manager.contentsOfDirectoryAtPath(dir!.path!)
    for content in contents {
        do {
            try manager.removeItemAtURL(dir!.URLByAppendingPathComponent(content)!)
        } catch where ((error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError)?.code == Int(EPERM) {
            // "Not permitted". We ignore this.
            log.debug("Couldn't delete some library contents.")
        }
    }
}

private func deleteLibraryFolder(folder: String) throws {
    let manager = NSFileManager.defaultManager()
    let library = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0]
    let dir = library.URLByAppendingPathComponent(folder)
    try manager.removeItemAtURL(dir!)
}

// Removes all app cache storage.
class SiteDataClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Offline Website Data", tableName: "ClearPrivateData", comment: "Settings item for clearing website data")
    }

    func clear() -> Success {
        let dataTypes = Set([ShimWKWebsiteDataTypeOfflineWebApplicationCache])
        ShimWKWebsiteDataStore.defaultDataStore().removeDataOfTypes(dataTypes, modifiedSince: NSDate.distantPast(), completionHandler: {})

        log.debug("SiteDataClearable succeeded.")
        return succeed()
    }
}

// Remove all cookies stored by the site. This includes localStorage, sessionStorage, and WebSQL/IndexedDB.
class CookiesClearable: Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    var label: String {
        return NSLocalizedString("Cookies", tableName: "ClearPrivateData", comment: "Settings item for clearing cookies")
    }

    func clear() -> Success {
        let dataTypes = Set([ShimWKWebsiteDataTypeCookies, ShimWKWebsiteDataTypeLocalStorage, ShimWKWebsiteDataTypeSessionStorage, ShimWKWebsiteDataTypeWebSQLDatabases, ShimWKWebsiteDataTypeIndexedDBDatabases])
        ShimWKWebsiteDataStore.defaultDataStore().removeDataOfTypes(dataTypes, modifiedSince: NSDate.distantPast(), completionHandler: {})

        log.debug("CookiesClearable succeeded.")
        return succeed()
    }
}
