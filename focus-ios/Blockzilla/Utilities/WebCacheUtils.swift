/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class WebCacheUtils {
    static let FolderWhiteList = ["KSCrash", "io.sentry", "Snapshots"]

    static func reset() {
        clearCaches()
        clearCookies()
        clearWebKitDataStore()
        removeInMemoryHistory()
    }

    private static func clearCaches() {
        URLCache.shared.removeAllCachedResponses()

        // Delete other remnants in the cache directory, such as HSTS.plist.
        if let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: cachesPath)) ?? []
            for file in contents {
                if !FolderWhiteList.contains(file) {
                    FileManager.default.removeItemAndContents(path: "\(cachesPath)/\(file)")
                }
            }
        }
    }

    private static func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        // Delete other cookies, such as .binarycookies files.
        if let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first {
            let cookiesPath = (libraryPath as NSString).appendingPathComponent("Cookies")
            FileManager.default.removeItemAndContents(path: cookiesPath)
        }
    }

    private static func clearWebKitDataStore() {
        // Clear everything that WKWebView creates
        let dateFrom = Date(timeIntervalSince1970: 0)
        let dataTypes: Set<String> = [WKWebsiteDataTypeDiskCache,
                                      WKWebsiteDataTypeOfflineWebApplicationCache,
                                      WKWebsiteDataTypeMemoryCache,
                                      WKWebsiteDataTypeLocalStorage,
                                      WKWebsiteDataTypeCookies,
                                      WKWebsiteDataTypeSessionStorage,
                                      WKWebsiteDataTypeIndexedDBDatabases,
                                      WKWebsiteDataTypeWebSQLDatabases]

        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: dateFrom, completionHandler: {})
    }

    private static func removeInMemoryHistory() {
        // Remove the in-memory history that WebKit maintains.
        // With Swift 4 we have to cast it to AnyObject first
        // https://stackoverflow.com/questions/45957626/swift-4-objective-c-runtime-and-casting-to-nsobjectprotocol
        if let klazz = NSClassFromString("Web" + "History"),
            let clazz = klazz as AnyObject as? NSObjectProtocol {
            if clazz.responds(to: Selector(("optional" + "Shared" + "History"))) {
                if let webHistory = clazz.perform(Selector(("optional" + "Shared" + "History"))) {
                    let o = webHistory.takeUnretainedValue()
                    _ = o.perform(Selector(("remove" + "All" + "Items")))
                }
            }
        }
    }
}
