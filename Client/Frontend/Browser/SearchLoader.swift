/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

private let URLBeforePathRegex = try! NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class SearchLoader: Loader<Cursor<Site>, SearchViewController> {
    fileprivate let profile: Profile
    fileprivate let urlBar: URLBarView
    fileprivate let frecentHistory: FrecentHistory

    private var skipNextAutocomplete: Bool

    init(profile: Profile, urlBar: URLBarView) {
        self.profile = profile
        self.urlBar = urlBar
        self.frecentHistory = profile.history.getFrecentHistory()

        self.skipNextAutocomplete = false

        super.init()
    }

    fileprivate lazy var topDomains: [String] = {
        let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt")
        return try! String(contentsOfFile: filePath!).components(separatedBy: "\n")
    }()

    // `weak` usage here allows deferred queue to be the owner. The deferred is always filled and this set to nil,
    // this is defensive against any changes to queue (or cancellation) behaviour in future.
    private weak var currentDeferredHistoryQuery: CancellableDeferred<Maybe<Cursor<Site>>>?

    fileprivate func getBookmarksAsSites(matchingSearchQuery query: String, limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return profile.places.searchBookmarks(query: query, limit: 5).bind { result in
            guard let bookmarkItems = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let sites = bookmarkItems.map({ Site(url: $0.url, title: $0.title, bookmarked: true, guid: $0.guid) })
            return deferMaybe(ArrayCursor(data: sites))
        }
    }

    var query: String = "" {
        didSet {
            guard self.profile is BrowserProfile else {
                assertionFailure("nil profile")
                return
            }

            currentDeferredHistoryQuery?.cancel()

            if query.isEmpty {
                load(Cursor(status: .success, msg: "Empty query"))
                return
            }

            guard let deferredHistory = frecentHistory.getSites(matchingSearchQuery: query, limit: 100) as? CancellableDeferred else {
                assertionFailure("FrecentHistory query should be cancellable")
                return
            }

            currentDeferredHistoryQuery = deferredHistory

            let deferredBookmarks = getBookmarksAsSites(matchingSearchQuery: query, limit: 5)

            all([deferredHistory, deferredBookmarks]).uponQueue(.main) { results in
                defer {
                    self.currentDeferredHistoryQuery = nil
                }

                guard !deferredHistory.cancelled else {
                    return
                }

                let deferredHistorySites = results[0].successValue?.asArray() ?? []
                let deferredBookmarksSites = results[1].successValue?.asArray() ?? []
                let combinedSites = deferredBookmarksSites + deferredHistorySites

                // Load the data in the table view.
                self.load(ArrayCursor(data: combinedSites))

                // If the new search string is not longer than the previous
                // we don't need to find an autocomplete suggestion.
                guard oldValue.count < self.query.count else {
                    return
                }

                // If we should skip the next autocomplete, reset
                // the flag and bail out here.
                guard !self.skipNextAutocomplete else {
                    self.skipNextAutocomplete = false
                    return
                }

                // First, see if the query matches any URLs from the user's search history.
                for site in combinedSites {
                    if let completion = self.completionForURL(site.url) {
                        self.urlBar.setAutocompleteSuggestion(completion)
                        return
                    }
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

    func setQueryWithoutAutocomplete(_ query: String) {
        skipNextAutocomplete = true
        self.query = query
    }

    fileprivate func completionForURL(_ url: String) -> String? {
        // Extract the pre-path substring from the URL. This should be more efficient than parsing via
        // NSURL since we need to only look at the beginning of the string.
        // Note that we won't match non-HTTP(S) URLs.
        guard let match = URLBeforePathRegex.firstMatch(in: url, options: [], range: NSRange(location: 0, length: url.count)) else {
            return nil
        }

        // If the pre-path component (including the scheme) starts with the query, just use it as is.
        var prePathURL = (url as NSString).substring(with: match.range(at: 0))
        if prePathURL.hasPrefix(query) {
            // Trailing slashes in the autocompleteTextField cause issues with Swype keyboard. Bug 1194714
            if prePathURL.hasSuffix("/") {
                prePathURL.remove(at: prePathURL.index(before: prePathURL.endIndex))
            }
            return prePathURL
        }

        // Otherwise, find and use any matching domain.
        // To simplify the search, prepend a ".", and search the string for ".query".
        // For example, for http://en.m.wikipedia.org, domainWithDotPrefix will be ".en.m.wikipedia.org".
        // This allows us to use the "." as a separator, so we can match "en", "m", "wikipedia", and "org",
        let domain = (url as NSString).substring(with: match.range(at: 1))
        return completionForDomain(domain)
    }

    fileprivate func completionForDomain(_ domain: String) -> String? {
        let domainWithDotPrefix: String = ".\(domain)"
        if let range = domainWithDotPrefix.range(of: ".\(query)", options: .caseInsensitive, range: nil, locale: nil) {
            // We don't actually want to match the top-level domain ("com", "org", etc.) by itself, so
            // so make sure the result includes at least one ".".
            let matchedDomain = String(domainWithDotPrefix[domainWithDotPrefix.index(range.lowerBound, offsetBy: 1)...])
            if matchedDomain.contains(".") {
                return matchedDomain
            }
        }

        return nil
    }
}
