// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

enum RecentSearchClientError: Error {
    case invalidHTTPResponse
    case unableToRetrieveResponse
}

struct RecentSearchProvider {
    private let historyStorage: RustPlaces
    private let searchEngineID: String
    private let logger: Logger
    private let maxNumberOfSuggestions = 10
    private let prefs: Prefs
    private let baseKey = PrefsKeys.Search.recentSearchesCache
    // Namespaced key = "recentSearches.engineID"
     private var recentSearchesKey: String {
         "\(baseKey).\(searchEngineID)"
     }

    init(profile: Profile = AppContainer.shared.resolve(),
         searchEngineID: String,
         logger: Logger = DefaultLogger.shared) {
        self.historyStorage = profile.places
        self.searchEngineID = searchEngineID
        self.logger = logger
        self.prefs = profile.prefs
    }

    // MARK: - Recent Searches
    func addRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searches = recentSearches()

        searches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        searches.insert(trimmed, at: 0)

        if searches.count > maxNumberOfSuggestions {
            searches = Array(searches.prefix(maxNumberOfSuggestions))
        }

        prefs.setObject(searches, forKey: recentSearchesKey)
    }

    func recentSearches() -> [String] {
        prefs.objectForKey(recentSearchesKey) ?? []
    }

    func clearRecentSearches() {
        prefs.removeObjectForKey(recentSearchesKey)
    }
}
