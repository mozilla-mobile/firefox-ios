// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Those extensions are kept public at the moment to avoid breaking any existing code, but ideally
/// in the future we should keep the usage of those extensions internal to the WebEngine only,
/// as the goal is that we only have URL extensions that relates to webview in this file. If they
/// cannot be internal then we should move the ones that needs to be public to the Common package.
/// This will be done with FXIOS-7960
public extension URL {
    var isReaderModeURL: Bool {
        let scheme = self.scheme, host = self.host, path = self.path
        return scheme == "http" && host == "localhost" && path == "/reader-mode/page"
    }

    var isSyncedReaderModeURL: Bool {
        return absoluteString.hasPrefix("about:reader?url=")
    }

    var decodeReaderModeURL: URL? {
        if self.isReaderModeURL || self.isSyncedReaderModeURL {
            if let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems {
                if let queryItem = queryItems.first(where: { $0.name == "url" }),
                   let value = queryItem.value {
                    return URL(string: value, invalidCharacters: false)?.safeEncodedUrl
                }
            }
        }
        return nil
    }

    func encodeReaderModeURL(_ baseReaderModeURL: String) -> URL? {
        if let encodedURL = absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            if let aboutReaderURL = URL(string: "\(baseReaderModeURL)?url=\(encodedURL)", invalidCharacters: false) {
                return aboutReaderURL
            }
        }
        return nil
    }

    var safeEncodedUrl: URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)

        // HTML-encode scheme, host, and path
        guard let host = components?.host?.htmlEntityEncodedString,
              let scheme = components?.scheme?.htmlEntityEncodedString,
              let path = components?.path.htmlEntityEncodedString else {
            return nil
        }

        components?.path = path
        components?.scheme = scheme
        components?.host = host

        // sanitize query items
        if let queryItems = components?.queryItems {
            var safeQueryItems: [URLQueryItem] = []

            for item in queryItems {
                // percent-encoded characters
                guard let decodedValue = item.value?.removingPercentEncoding else {
                    return nil
                }

                // HTML special characters
                let htmlEncodedValue = decodedValue.htmlEntityEncodedString

                // New query item with the HTML-encoded value
                let safeItem = URLQueryItem(name: item.name, value: htmlEncodedValue)
                safeQueryItems.append(safeItem)
            }

            // Replace the original query items with the "safe" ones
            components?.queryItems = safeQueryItems
        }

        return components?.url
    }
}
