// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import Glean

private let URLBeforePathRegex = try! NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class SearchLoader: Loader<Cursor<Site>, SearchViewController>, FeatureFlaggable {
    fileprivate let profile: Profile
    fileprivate let urlBar: URLBarView

    private var skipNextAutocomplete: Bool

    init(profile: Profile, urlBar: URLBarView) {
        self.profile = profile
        self.urlBar = urlBar
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

    private func getHistoryAsSites(matchingSearchQuery query: String, limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        profile.places.interruptReader()
        return self.profile.places.queryAutocomplete(matchingSearchQuery: query, limit: limit).bind { result in
            guard let historyItems = result.successValue else {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Error searching history",
                    tag: .rustPlaces,
                    severity: .error,
                    description: result.failureValue?.localizedDescription ?? "Unknown error searching history"
                )
                return deferMaybe(ArrayCursor(data: []))
            }
            let sites = historyItems.sorted {
                // Sort decending by frecency score
                $0.frecency > $1.frecency
            }.map({
                return Site(url: $0.url, title: $0.title )
            }).uniqued()
            return deferMaybe(ArrayCursor(data: sites))
        }
    }

    var query: String = "" {
        didSet {
            let timerid = GleanMetrics.Awesomebar.queryTime.start()
            guard profile is BrowserProfile else {
                assertionFailure("nil profile")
                GleanMetrics.Awesomebar.queryTime.cancel(timerid)
                return
            }

            if query.isEmpty {
                load(Cursor(status: .success, msg: "Empty query"))
                GleanMetrics.Awesomebar.queryTime.cancel(timerid)
                return
            }
            let deferredBookmarks = getBookmarksAsSites(matchingSearchQuery: query, limit: 5)

            var deferredQueries = [deferredBookmarks]
            let historyHighlightsEnabled = featureFlags.isFeatureEnabled(.searchHighlights, checking: .buildOnly)
            if !historyHighlightsEnabled {
                // Lets only add the history query if history highlights are not enabled
                deferredQueries.append(getHistoryAsSites(matchingSearchQuery: query, limit: 100))
            }

            all(deferredQueries).uponQueue(.main) { results in
                defer {
                    self.currentDeferredHistoryQuery = nil
                    GleanMetrics.Awesomebar.queryTime.stopAndAccumulate(timerid)
                }

                let deferredBookmarksSites = results[safe: 0]?.successValue?.asArray() ?? []
                var combinedSites = deferredBookmarksSites
                if !historyHighlightsEnabled {
                    let cancellableHistory = deferredQueries[safe: 1] as? CancellableDeferred
                    if let cancellableHistory = cancellableHistory, cancellableHistory.cancelled {
                        return
                    }
                    let deferredHistorySites = results[safe: 1]?.successValue?.asArray() ?? []
                    combinedSites += deferredHistorySites
                }

                // Load the data in the table view.
                self.load(ArrayCursor(data: combinedSites))

                // If the new search string is not longer than the previous
                // we don't need to find an autocomplete suggestion.
                guard oldValue.count < self.query.count else { return }

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
        guard let match = URLBeforePathRegex.firstMatch(
            in: url,
            options: [],
            range: NSRange(location: 0, length: url.count))
        else { return nil }

        // If the pre-path component (including the scheme) starts with the query, just use it as is.
        var prePathURL = (url as NSString).substring(with: match.range(at: 0))
        if prePathURL.hasPrefix(query) {
            // Trailing slashes in the autocompleteTextField cause issues with Swipe keyboard. Bug 1194714
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
