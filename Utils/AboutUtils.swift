/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct AboutUtils {
    private static let AboutPath = "/about/"

    static func isAboutHomeURL(_ url: URL?) -> Bool {
        return getAboutComponent(url) == "home"
    }

    static func isAboutURL(_ url: URL?) -> Bool {
        return getAboutComponent(url) != nil
    }

    /// If the URI is an about: URI, return the path after "about/" in the URI.
    /// For example, return "home" for "http://localhost:1234/about/home/#panel=0".
    static func getAboutComponent(_ url: URL?) -> String? {
        if let scheme = url?.scheme, host = url?.host, path = url?.path {
            if scheme == "http" && host == "localhost" && path.startsWith(AboutPath) {
                return path.substring(from: AboutPath.endIndex)
            }
        }
        return nil
    }
}
