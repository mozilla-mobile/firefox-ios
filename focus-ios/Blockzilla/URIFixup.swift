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

        // Check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        if let url = URL(string: entry), url.scheme != nil {
            return url
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.range(of: ".") == nil {
            return nil
        }

        if trimmed.range(of: " ") != nil {
            return nil
        }

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = URL(string: "http://\(escaped)"), url.host != nil {
            return url
        }

        return nil
    }
}
