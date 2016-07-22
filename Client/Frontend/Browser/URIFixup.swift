/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URIFixup {
    static func getURL(entry: String) -> NSURL? {
        let allowedCharacters = NSMutableCharacterSet(charactersInString: "%")
        allowedCharacters.formUnionWithCharacterSet(NSCharacterSet.URLFragmentAllowedCharacterSet())
        guard let trimmed = entry.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters) else {
            return nil
        }

        // Then check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        // However, we ensure that the scheme is one that is listed in
        // the official URI scheme list, so that other such search phrases
        // like "filetype:" are recognised as searches rather than URLs.
        if let url = NSURL(string: trimmed) where url.schemeIsValid {
            return url
        }

        // If there's no scheme, we're going to prepend "http://". First,
        // make sure there's at least one "." in the host. This means
        // we'll allow single-word searches (e.g., "foo") at the expense
        // of breaking single-word hosts without a scheme (e.g., "localhost").
        if trimmed.rangeOfString(".") == nil {
            return nil
        }

        // If there is a ".", prepend "http://" and try again. Since this
        // is strictly an "http://" URL, we also require a host.
        if let url = NSURL(string: "http://\(trimmed)") where url.host != nil {
            return url
        }

        return nil
    }
}