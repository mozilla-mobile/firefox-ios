// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol FirefoxURLBuilding {
    func buildFirefoxURL(for content: String, isSearch: Bool) -> URL?
}

struct FirefoxURLBuilder: FirefoxURLBuilding {
    func buildFirefoxURL(for content: String, isSearch: Bool) -> URL? {
        guard let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }

        let urlString = isSearch
            ? "\(mozInternalScheme)://open-text?text=\(encodedContent)&openWithFirefox=true"
            : "\(mozInternalScheme)://open-url?url=\(encodedContent)&openWithFirefox=true"

        return URL(string: urlString)
    }

    let mozInternalScheme: String = {
        guard let string = Bundle.main.object(
            forInfoDictionaryKey: "MozInternalURLScheme"
        ) as? String, !string.isEmpty else {
            // Something went wrong/weird, fallback to the public one.
            return "firefox"
        }
        return string
    }()
}
