/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct AboutUtils {
    private static let AboutPath = "/about/"

    static func isAboutHomeURL(url: NSURL?) -> Bool {
        guard var url = url else {
            return false
        }
        if let urlString = url.getQuery()["url"]?.unescape() where isErrorPageURL(url) {
            url = NSURL(string: urlString) ?? url
        }
        return getAboutComponent(url) == "home"
    }

    static func isAboutURL(url: NSURL?) -> Bool {
        guard let url = url else {
            return false
        }
        return getAboutComponent(url) != nil
    }

    static func isErrorPageURL(url: NSURL) -> Bool {
        if let host = url.host, path = url.path {
            return url.scheme == "http" && host == "localhost" && path == "/errors/error.html"
        }
        return false
    }

    /// If the URI is an about: URI, return the path after "about/" in the URI.
    /// For example, return "home" for "http://localhost:1234/about/home/#panel=0".
    static func getAboutComponent(url: NSURL?) -> String? {
        guard let scheme = url?.scheme, host = url?.host, path = url?.path else {
            return nil
        }
        if scheme == "http" && host == "localhost" && path.startsWith(AboutPath) {
            return path.substringFromIndex(AboutPath.endIndex)
        }
        return nil
    }
}
