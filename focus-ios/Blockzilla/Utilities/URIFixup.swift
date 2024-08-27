/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URIFixup {
    static func getURL(entry: String) -> URL? {
        let trimmed = entry.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let escaped = trimmed.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlAllowed) else {
            return nil
        }

        guard !trimmed.lowercased().hasPrefix("javascript:") else {
            return nil
        }

        // Check if the URL string does not start with "file://". 
        // If it starts with "file://", return nil, indicating that this function
        // does not handle local file URLs, resulting in a search

        guard !trimmed.lowercased().hasPrefix("file:") else {
            return nil
        }

        // Check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // Also check with a regular expression if there is a port in the url
        // this will be handle later in this function adding http prefix
        if let url = URL(string: trimmed, invalidCharacters: false),
            url.scheme != nil,
            trimmed.range(of: "\\b:[0-9]{1,5}", options: .regularExpression) == nil {
            // check for top-level domain if scheme is "http://" or "https://"
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                if trimmed.contains(".") == false {
                    return nil
                }
            }
            return url
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.contains(".") == false {
            return nil
        }

        if trimmed.contains(" ") == true {
            return nil
        }

        // If the input url has a prefix http or https, don't append again
        let finalurl = escaped.hasPrefix("http://") || escaped.hasPrefix("https://") ? escaped : "http://\(escaped)"

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = URL(string: finalurl, invalidCharacters: false), url.host != nil {
            return url
        }

        return nil
    }
}
