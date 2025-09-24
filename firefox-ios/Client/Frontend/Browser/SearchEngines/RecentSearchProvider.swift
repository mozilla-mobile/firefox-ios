// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// A provider that manages recent search terms for a specific search engine.
struct RecentSearchProvider {
    private let searchEngineID: String
    private let prefs: Prefs

    private let baseKey = PrefsKeys.Search.recentSearchesCache
    private let maxNumberOfSuggestions = 5

    // Namespaced key = "recentSearchesCacheBaseKey.[engineID]"
    private var recentSearchesKey: String {
        "\(baseKey).\(searchEngineID)"
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         searchEngineID: String) {
        self.searchEngineID = searchEngineID
        self.prefs = profile.prefs
    }

    /// Adds a search term to the persisted recent searches list, ensuring it avoid duplicates,
    /// and does not exceed `maxNumberOfSuggestions`.
    ///
    /// - Parameter term: The search term to store.
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
