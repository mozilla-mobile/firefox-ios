/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class WebCacheUtils {
    static func reset() {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first,
              let cacheFiles = try? FileManager.default.contentsOfDirectory(atPath: cachesPath) else { return }

        for file in cacheFiles where file != "Snapshots" {
            let path = (cachesPath as NSString).appendingPathComponent(file)
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                NSLog("Found \(path) but was unable to remove it: \(error)")
            }
        }
    }
}
