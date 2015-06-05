/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct AboutUtils {
    static func isAboutHomeURL(url: NSURL?) -> Bool {
        if let scheme = url?.scheme, host = url?.host, path = url?.path {
            return scheme == "http" && host == "localhost" && path == "/about/home"
        }
        return false
    }
}
