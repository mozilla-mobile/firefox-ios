// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Internal URLs helps with error pages, session restore and about pages
struct WKInternalURL {
    static let uuid = UUID().uuidString
    static let scheme = "internal"
    static let baseUrl = "\(scheme)://local"
    enum Path: String {
        case errorpage
        case sessionrestore
        func matches(_ string: String) -> Bool {
            return string.range(of: "/?\(self.rawValue)", options: .regularExpression, range: nil, locale: nil) != nil
        }
    }

    enum Param: String {
        case uuidkey
        case url
        func matches(_ string: String) -> Bool { return string == self.rawValue }
    }

    let url: URL

    static func isValid(url: URL) -> Bool {
        let isWebServerUrl = url.absoluteString.hasPrefix("http://localhost:\(AppInfo.webserverPort)/")
        if isWebServerUrl, url.path.hasPrefix("/test-fixture/") {
            // internal test pages need to be treated as external pages
            return false
        }

        return isWebServerUrl || WKInternalURL.scheme == url.scheme
    }

    init?(_ url: URL) {
        guard WKInternalURL.isValid(url: url) else { return nil }

        self.url = url
    }

    var isAuthorized: Bool {
        let query = url.getQuery()
        return query[WKInternalURL.Param.uuidkey.rawValue] == WKInternalURL.uuid
    }
}
