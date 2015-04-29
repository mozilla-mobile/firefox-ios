/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

private let URLBeforePathRegex = NSRegularExpression(pattern: "^https?://([^/]+/)", options: nil, error: nil)!

// TODO: Swift currently requires that classes extending generic classes must also be generic.
// This is a workaround until that requirement is fixed.
typealias SearchLoader = _SearchLoader<AnyObject, AnyObject>

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class _SearchLoader<UnusedA, UnusedB>: Loader<Cursor, SearchViewController> {
    private let history: BrowserHistory
    private let urlBar: URLBarView

    init(history: BrowserHistory, urlBar: URLBarView) {
        self.history = history
        self.urlBar = urlBar
        super.init()
    }

    var query: String = "" {
        didSet {
            if query.isEmpty {
                self.load(Cursor(status: .Success, msg: "Empty query"))
                return
            }

            let options = QueryOptions(filter: query, filterType: FilterType.Url, sort: QuerySort.Frecency)
            self.history.get(options).uponQueue(dispatch_get_main_queue()) { result in
                // Failed cursors are excluded in .get().
                if let cursor = result.successValue {
                    self.load(cursor)
                    self.urlBar.setAutocompleteSuggestion(self.getAutocompleteSuggestion(cursor))
                }
            }
        }
    }

    private func getAutocompleteSuggestion(cursor: Cursor) -> String? {
        for result in cursor {
            let url = (result as! Site).url

            // Extract the pre-path substring from the URL. This should be more efficient than parsing via
            // NSURL since we need to only look at the beginning of the string.
            // Note that we won't match non-HTTP(S) URLs.
            if let match = URLBeforePathRegex.firstMatchInString(url, options: nil, range: NSRange(location: 0, length: count(url))) {
                // If the pre-path component starts with the filter, just use it as is.
                let prePathURL = (url as NSString).substringWithRange(match.rangeAtIndex(0))
                if prePathURL.startsWith(query) {
                    return prePathURL
                }

                // Otherwise, find and use any matching domain.
                // To simplify the search, prepend a ".", and search the string for ".query".
                // For example, for http://en.m.wikipedia.org, domainWithDotPrefix will be ".en.m.wikipedia.org".
                // This allows us to use the "." as a separator, so we can match "en", "m", "wikipedia", and "org",
                let domain = (url as NSString).substringWithRange(match.rangeAtIndex(1))
                let domainWithDotPrefix: String = ".\(domain)"
                if let range = domainWithDotPrefix.rangeOfString(".\(query)", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) {
                    // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
                    // so make sure the result includes at least one ".".
                    let matchedDomain: String = domainWithDotPrefix.substringFromIndex(advance(range.startIndex, 1))
                    if matchedDomain.contains(".") {
                        return matchedDomain
                    }
                }
            }
        }

        return nil
    }
}
