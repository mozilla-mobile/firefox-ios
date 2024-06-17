// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct InternalURL {
    public static let uuid = UUID().uuidString
    public static let scheme = "internal"
    public static let baseUrl = "\(scheme)://local"
    public enum Path: String {
        case errorpage
        case sessionrestore
        func matches(_ string: String) -> Bool {
            return string.range(of: "/?\(self.rawValue)", options: .regularExpression, range: nil, locale: nil) != nil
        }
    }

    public enum Param: String {
        case uuidkey
        case url
        func matches(_ string: String) -> Bool { return string == self.rawValue }
    }

    public static func isValid(url: URL) -> Bool {
        let isWebServerUrl = url.absoluteString.hasPrefix("http://localhost:\(AppInfo.webserverPort)/")
        if isWebServerUrl, url.path.hasPrefix("/test-fixture/") {
            // internal test pages need to be treated as external pages
            return false
        }

        // TODO: (reader-mode-custom-scheme) remove isWebServerUrl when updating code.
        return isWebServerUrl || InternalURL.scheme == url.scheme
    }
}
