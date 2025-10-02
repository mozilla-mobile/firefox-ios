// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

/// Abstraction for any search client that can return trending searches. Able to mock for testing.
protocol RecentSearchProvider {
    func addRecentSearch(_ term: String, url: String?)
    func loadRecentSearches(completion: @escaping ([String]) -> Void)
}

/// A provider that manages recent search terms for a specific search engine.
struct DefaultRecentSearchProvider: RecentSearchProvider {
    private let historyStorage: HistoryHandler
    private let nimbus: FxNimbus

    private var maxNumberOfSuggestions: Int {
        return nimbus.features.recentSearchesFeature.value().maxSuggestions
    }

    func loadRecentSearches(completion: @escaping ([String]) -> Void) {
      historyStorage.getHistoryMetadataSince(since: Int64.min) { result in
          if case .success(let historyMetadata) = result {
              let searches = historyMetadata.compactMap { $0.searchTerm }
              let recentSearches = Array(searches.prefix(maxNumberOfSuggestions))
              completion(recentSearches)
          } else {
              completion([])
          }
      }
    }

    init(
        historyStorage: HistoryHandler,
        nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.historyStorage = historyStorage
        self.nimbus = nimbus
    }

    // Adds a search term to the persisted recent searches list, ensuring it avoid duplicates,
    /// and does not exceed `maxNumberOfSuggestions`.
    ///
    /// - Parameter term: The search term to store.
    func addRecentSearch(_ term: String, url: String?) {
        guard let url else {
            // logg error
            return
        }
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        historyStorage.noteHistoryMetadata(for: term, and: url, completion: { _ in })
    }
}
