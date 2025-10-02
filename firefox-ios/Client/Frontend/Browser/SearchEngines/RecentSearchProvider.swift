// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Abstraction for any search client that can return trending searches. Able to mock for testing.
protocol RecentSearchProvider {
    var recentSearches: [String] { get }
    func addRecentSearch(_ term: String)
    func clearRecentSearches()
}

/// A provider that manages recent search terms for a specific search engine.
struct DefaultRecentSearchProvider: RecentSearchProvider {
    private let searchEngineID: String
    private let prefs: Prefs
    private let nimbus: FxNimbus

    private let baseKey = PrefsKeys.Search.recentSearchesCache

    // Namespaced key = "recentSearchesCacheBaseKey.[engineID]"
    private var recentSearchesKey: String {
        "\(baseKey).\(searchEngineID)"
    }

    var recentSearches: [String] {
        prefs.objectForKey(recentSearchesKey) ?? []
    }

    private var maxNumberOfSuggestions: Int {
        return nimbus.features.recentSearchesFeature.value().maxSuggestions
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        searchEngineID: String,
        nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.searchEngineID = searchEngineID
        self.prefs = profile.prefs
        self.nimbus = nimbus
    }

    /// Adds a search term to the persisted recent searches list, ensuring it avoid duplicates,
    /// and does not exceed `maxNumberOfSuggestions`.
    ///
    /// - Parameter term: The search term to store.
    func addRecentSearch(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searches = recentSearches

        searches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        searches.insert(trimmed, at: 0)

        if searches.count > maxNumberOfSuggestions {
            searches = Array(searches.prefix(maxNumberOfSuggestions))
        }

        prefs.setObject(searches, forKey: recentSearchesKey)
    }

    func clearRecentSearches() {
        prefs.removeObjectForKey(recentSearchesKey)
    }
}
