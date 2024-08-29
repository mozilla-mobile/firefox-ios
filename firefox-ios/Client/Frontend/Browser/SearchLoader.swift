// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Glean
import Common

private let URLBeforePathRegex = try? NSRegularExpression(pattern: "^https?://([^/]+)/", options: [])

/**
 * Shared data source for the SearchViewController and the URLBar domain completion.
 * Since both of these use the same SQL query, we can perform the query once and dispatch the results.
 */
class SearchLoader: Loader<Cursor<Site>, SearchViewModel>, FeatureFlaggable {
    fileprivate let profile: Profile
    fileprivate let autocompleteView: Autocompletable
    private let logger: Logger

    private var skipNextAutocomplete: Bool

    init(profile: Profile, autocompleteView: Autocompletable, logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.autocompleteView = autocompleteView
        self.skipNextAutocomplete = false
        self.logger = logger

        super.init()
    }

    fileprivate lazy var topDomains: [String]? = {
        guard let filePath = Bundle.main.path(forResource: "topdomains", ofType: "txt")
        else { return nil }

        return try? String(contentsOfFile: filePath).components(separatedBy: "\n")
    }()

    fileprivate func getBookmarksAsSites(
        matchingSearchQuery query: String,
        limit: UInt,
        completionHandler: @escaping (([Site]) -> Void)
    ) {
        profile.places.searchBookmarks(query: query, limit: limit).upon { result in
            guard let bookmarkItems = result.successValue else {
                completionHandler([])
                return
            }

            let sites = bookmarkItems.map({ Site(url: $0.url, title: $0.title, bookmarked: true, guid: $0.guid) })
            completionHandler(sites)
        }
    }

    private func getHistoryAsSites(
        matchingSearchQuery query: String,
        limit: Int,
        completionHandler: @escaping (([Site]) -> Void)
    ) {
        profile.places.interruptReader()
        profile.places.queryAutocomplete(matchingSearchQuery: query, limit: limit).upon { result in
            guard let historyItems = result.successValue else {
                self.logger.log(
                    "Error searching history",
                    level: .warning,
                    category: .sync,
                    description: result.failureValue?.localizedDescription ?? "Unknown error searching history"
                )
                completionHandler([])
                return
            }
            let sites = historyItems.sorted {
                // Sort descending by frecency score
                $0.frecency > $1.frecency
            }.map({
                return Site(url: $0.url, title: $0.title )
            }).uniqued()
            completionHandler(sites)
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

            getBookmarksAsSites(matchingSearchQuery: query, limit: 5) { [weak self] bookmarks in
                guard let self = self else { return }

                var queries = [bookmarks]
                let historyHighlightsEnabled = self.featureFlags.isFeatureEnabled(
                    .searchHighlights,
                    checking: .buildOnly
                )
                if !historyHighlightsEnabled {
                    let group = DispatchGroup()
                    group.enter()
                    // Lets only add the history query if history highlights are not enabled
                    self.getHistoryAsSites(matchingSearchQuery: self.query, limit: 100) { history in
                        queries.append(history)
                        group.leave()
                    }
                    _ = group.wait(timeout: .distantFuture)
                }

                DispatchQueue.main.async {
                    self.updateUIWithBookmarksAsSitesResults(queries: queries,
                                                             timerid: timerid,
                                                             historyHighlightsEnabled: historyHighlightsEnabled,
                                                             oldValue: oldValue)
                }
            }
        }
    }

    private func updateUIWithBookmarksAsSitesResults(queries: [[Site]],
                                                     timerid: TimerId,
                                                     historyHighlightsEnabled: Bool,
                                                     oldValue: String) {
        let results = queries
        defer {
            GleanMetrics.Awesomebar.queryTime.stopAndAccumulate(timerid)
        }

        let bookmarksSites = results[safe: 0] ?? []
        var combinedSites = bookmarksSites
        if !historyHighlightsEnabled {
            let historySites = results[safe: 1] ?? []
            combinedSites += historySites
        }

        // Load the data in the table view.
        load(ArrayCursor(data: combinedSites))

        // If the new search string is not longer than the previous
        // we don't need to find an autocomplete suggestion.
        guard oldValue.count < query.count else { return }

        // If we should skip the next autocomplete, reset
        // the flag and bail out here.
        guard !skipNextAutocomplete else {
            skipNextAutocomplete = false
            return
        }

        // First, see if the query matches any URLs from the user's search history.
        for site in combinedSites {
            if let completion = completionForURL(site.url) {
                autocompleteView.setAutocompleteSuggestion(completion)
                return
            }
        }

        // If there are no search history matches, try matching one of the Alexa top domains.
        if let topDomains = topDomains {
            for domain in topDomains {
                if let completion = completionForDomain(domain) {
                    autocompleteView.setAutocompleteSuggestion(completion)
                    return
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
        guard let match = URLBeforePathRegex?.firstMatch(
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
