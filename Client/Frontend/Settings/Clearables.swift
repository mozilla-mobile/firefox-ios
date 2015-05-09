/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// A base protocol for something that can be cleared.
protocol Clearable {
    func clear() -> Deferred<Result<()>>
}

class ClearableError : ErrorType {
    private let msg: String
    init(msg: String) {
        self.msg = msg
    }

    var description: String { return msg }
}

// Clears our browsing history, including favicons and thumbnails.
class HistoryClearable : Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    // TODO: This can be cleaned up!
    func clear() -> Success {
        let deferred = Success()
        profile.history.clearHistory().upon { success in
            self.profile.thumbnails.clear({ success in
                SDImageCache.sharedImageCache().clearDisk()
                SDImageCache.sharedImageCache().clearMemory()
                self.profile.favicons.clearFavicons().upon {
                    deferred.fill($0)
                }
            })
        }
        return deferred
    }
}

// Clear all stored passwords. This will clear both Firefox's SQLite storage and the system shared
// Credential storage.
class PasswordsClearable : Clearable {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    func clear() -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>()
        // Clear our storage
        profile.passwords.removeAll() { success in
            let storage = NSURLCredentialStorage.sharedCredentialStorage()
            let credentials = storage.allCredentials
            for (space, credentials) in credentials {
                for (username, credential) in credentials as! [String: NSURLCredential] {
                    storage.removeCredential(credential, forProtectionSpace: space as! NSURLProtectionSpace)
                }
            }
            deferred.fill(success ? Result<()>(success: ()) :
                                    Result<()>(failure: ClearableError(msg: "Could not clear passwords")))
        }
        return deferred
    }
}

// Clear the web cache. Note, this has to close all open tabs in order to ensure the data
// cached in them isn't flushed to disk.
class CacheClearable : Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    func clear() -> Deferred<Result<()>> {
        // First ensure we close all open tabs first.
        tabManager.removeAll()

        // Remove the basic cache.
        NSURLCache.sharedURLCache().removeAllCachedResponses()

        // Now lets finish up by destroying our Cache directory.
        let manager = NSFileManager.defaultManager()
        var url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        var file = url.path!.stringByAppendingPathComponent("Caches")
        var error: NSError? = nil
        if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(file, error: nil) {
            for content in contents {
                let filePath = file.stringByAppendingPathComponent(content as! String)
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
            }
        }
        return Deferred(value: Result<()>(success: ()))
    }
}

// Removes all site data stored for sites. This should include things like IndexedDB or websql storage.
class SiteDataClearable : Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    func clear() -> Deferred<Result<()>> {
        // First, close all tabs to make sure they don't hold any thing in memory.
        tabManager.removeAll()

        // Then we just wipe the WebKit directory from our Library.
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        let file = url.path!.stringByAppendingPathComponent("WebKit")
        var error: NSError? = nil
        NSFileManager.defaultManager().removeItemAtPath(file, error: &error)

        return Deferred(value: Result<()>(success: ()))
    }
}

// Remove all cookies stored by the site.
class CookiesClearable : Clearable {
    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    func clear() -> Deferred<Result<()>> {
        // First close all tabs to make sure they aren't holding anything in memory.
        tabManager.removeAll()

        // Now we wipe the system cookie store (for our app).
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie as! NSHTTPCookie)
            }
        }

        // And just to be safe, we also wipe the Cookies directory.
        let manager = NSFileManager.defaultManager()
        var url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        var file = url.path!.stringByAppendingPathComponent("Cookies")
        var error: NSError? = nil
        if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(file, error: nil) {
            for content in contents {
                let filePath = file.stringByAppendingPathComponent(content as! String)
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
            }
        }

        return Deferred(value: Result<()>(success: ()))
    }
}

// A Clearable designed to clear all of the locally stored data for our app.
class EverythingClearable: Clearable {
    private let clearables: [Clearable]

    init(profile: Profile, tabmanager: TabManager) {
        clearables = [
            HistoryClearable(profile: profile),
            CacheClearable(tabManager: tabmanager),
            CookiesClearable(tabManager: tabmanager),
            SiteDataClearable(tabManager: tabmanager),
            PasswordsClearable(profile: profile),
        ]
    }

    func clear() -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>()
        all(clearables.map({ clearable in
            clearable.clear()
        })).upon({ result in
            deferred.fill(Result(success: ()))
        })
        return deferred
    }
}
