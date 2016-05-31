/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class URIFixup {
    static func getURL(entry: String) -> NSURL? {
        let trimmed = entry.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var url = NSURL(string: trimmed)

        if !isURL(trimmed) && !trimmed.contains("localhost") {
            return nil
        }

        // First check if the URL includes a scheme. This will handle
        // all valid requests starting with "http://", "about:", etc.
        if !(url?.scheme.isEmpty ?? true) {
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
        url = NSURL(string: "http://\(trimmed)")
        if url?.host != nil {
            return url
        }

        return nil
    }

    static func isURL(string: String?) -> Bool {
        let regEx = "[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[-a-zA-Z0-9@:%._\\+~#=]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return predicate.evaluateWithObject(string)
    }
}