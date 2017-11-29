/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

private let URLBeforePathRegex = try! NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

// TODO: Swift currently requires that classes extending generic classes must also be generic.
// This is a workaround until that requirement is fixed.
typealias SearchLoader = _SearchLoader<AnyObject, AnyObject>

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class _SearchLoader<UnusedA, UnusedB>: Loader<Cursor<Site>, SearchViewController> {
    fileprivate let profile: Profile
    fileprivate let urlBar: URLBarView
    fileprivate var inProgress: Cancellable?

    init(profile: Profile, urlBar: URLBarView) {
        self.profile = profile
        self.urlBar = urlBar
        super.init()
    }

    fileprivate lazy var topDomains: [String] = {
        let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt")
        do {
            return try String(contentsOfFile: filePath!).components(separatedBy: "\n")
        } catch {
            Sentry.shared.send(message: "SearchLoader topDomains failed", tag: .general, severity: .error)
            return []
        }
    }()

    private weak var currentDbQuery: Cancellable?

    var query: String = "" {
        didSet {
            guard let profile = self.profile as? BrowserProfile else {
                assert(false)
                return
            }

            if query.isEmpty {
                self.load(Cursor(status: .success, msg: "Empty query"))
                return
            }

            if let deferred = currentDbQuery {
                profile.db.cancel(deferred)
            }

            let deferred = self.profile.history.getSitesByFrecencyWithHistoryLimit(100, bookmarksLimit: 5, whereURLContains: query)
            currentDbQuery = deferred as? Cancellable

            deferred.upon() { result in
                guard let deferred = deferred as? Cancellable, !deferred.cancelled else {
                    return
                }

                // Failed cursors are excluded in .get().
                guard let cursor = result.successValue else {
                    return
                }

                // First, see if the query matches any URLs from the user's search history.
                self.load(cursor)
                for site in cursor {
                    if deferred.cancelled {
                        return
                    }

                    if let url = site?.url, let completion = self.completionForURL(url) {
                        DispatchQueue.main.async {
                            self.urlBar.setAutocompleteSuggestion(completion)
                        }
                        return
                    }
                }

                DispatchQueue.main.async {
                    if deferred.cancelled {
                        return
                    }

                    // If there are no search history matches, try matching one of the Alexa top domains.
                    for domain in self.topDomains {
                        if let completion = self.completionForDomain(domain) {
                            self.urlBar.setAutocompleteSuggestion(completion)
                            return
                        }
                    }
                }
            }
        }
    }

    fileprivate func completionForURL(_ url: String) -> String? {
        // Extract the pre-path substring from the URL. This should be more efficient than parsing via
        // NSURL since we need to only look at the beginning of the string.
        // Note that we won't match non-HTTP(S) URLs.
        guard let match = URLBeforePathRegex.firstMatch(in: url, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: url.characters.count)) else {
            return nil
        }

        // If the pre-path component (including the scheme) starts with the query, just use it as is.
        var prePathURL = (url as NSString).substring(with: match.rangeAt(0))
        if prePathURL.startsWith(query) {
            // Trailing slashes in the autocompleteTextField cause issues with Swype keyboard. Bug 1194714
            if prePathURL.endsWith("/") {
                prePathURL.remove(at: prePathURL.index(before: prePathURL.endIndex))
            }
            return prePathURL
        }

        // Otherwise, find and use any matching domain.
        // To simplify the search, prepend a ".", and search the string for ".query".
        // For example, for http://en.m.wikipedia.org, domainWithDotPrefix will be ".en.m.wikipedia.org".
        // This allows us to use the "." as a separator, so we can match "en", "m", "wikipedia", and "org",
        let domain = (url as NSString).substring(with: match.rangeAt(1))
        return completionForDomain(domain)
    }

    fileprivate func completionForDomain(_ domain: String) -> String? {
        let domainWithDotPrefix: String = ".\(domain)"
        if let range = domainWithDotPrefix.range(of: ".\(query)", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) {
            // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
            // so make sure the result includes at least one ".".
            let matchedDomain: String = domainWithDotPrefix.substring(from: domainWithDotPrefix.index(range.lowerBound, offsetBy: 1))
            if matchedDomain.contains(".") {
                return matchedDomain
            }
        }

        return nil
    }
}
