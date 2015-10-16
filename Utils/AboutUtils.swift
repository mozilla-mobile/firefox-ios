/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct AboutUtils {
    private static let AboutPath = "/about/"

    static func buildAboutHomeURLForIndex(index: Int) -> NSURL? {
        return NSURL(string: "http://localhost:1234/about/home/#panel=\(index)")
    }

    static func isAboutHomeURL(url: NSURL?) -> Bool {
        return getAboutComponent(url) == "home"
    }

    static func isAboutURL(url: NSURL?) -> Bool {
        return getAboutComponent(url) != nil
    }

    /// If the URI is an about: URI, return the path after "about/" in the URI.
    /// For example, return "home" for "http://localhost:1234/about/home/#panel=0".
    static func getAboutComponent(url: NSURL?) -> String? {
        if let scheme = url?.scheme, host = url?.host, path = url?.path {
            if scheme == "http" && host == "localhost" && path.startsWith(AboutPath) {
                return path.substringFromIndex(AboutPath.endIndex)
            }
        }
        return nil
    }

    static func getHomePanel(fragment: String?) -> Int {
        guard let fragment = fragment else { return 0 }
        let fragmentParts = fragment.componentsSeparatedByString("&")
        if !fragmentParts.isEmpty {
            if let panelParts = fragmentParts.first?.componentsSeparatedByString("=") {
                if let last = panelParts.last, lastInt = Int(last) {
                    return lastInt
                }
            }
        }

        return 0
    }

    static func getBookmarkFolders(fragment: String?) -> [String]? {
        guard let fragment = fragment else { return nil }
        let fragmentParts = fragment.componentsSeparatedByString("&")
        if fragmentParts.count == 2 {
            let folderParts = fragmentParts[1].componentsSeparatedByString("=")
            if let last = folderParts.last {
                return last.componentsSeparatedByString(",")
            }
        }

        return nil
    }

    static func getNavigationFragment(url: NSURL?) -> (panel: Int, bookmarkFolders: [String]?) {
        var panel = 0
        var folder: [String]? = nil
        
        guard let url = url, let fragment = url.fragment else { return (panel, folder) }
        panel = AboutUtils.getHomePanel(fragment)
        folder = AboutUtils.getBookmarkFolders(fragment)
        return (panel, folder)
    }
}
