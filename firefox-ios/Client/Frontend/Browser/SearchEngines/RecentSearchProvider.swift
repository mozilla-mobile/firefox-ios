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

/// A provider that manages recent search terms from a user's history storage.
struct DefaultRecentSearchProvider: RecentSearchProvider {
    private let historyStorage: HistoryHandler
    private let logger: Logger
    private let nimbus: FxNimbus

    private var maxNumberOfSuggestions: Int {
        return nimbus.features.recentSearchesFeature.value().maxSuggestions
    }

    init(
        historyStorage: HistoryHandler,
        logger: Logger = DefaultLogger.shared,
        nimbus: FxNimbus = FxNimbus.shared
    ) {
        self.historyStorage = historyStorage
        self.logger = logger
        self.nimbus = nimbus
    }

    /// Adds a search term to our history storage, `Rust Places` and saved in `places.db` locally.
    ///
    /// - Parameter term: The search term to store.
    func addRecentSearch(_ term: String, url: String?) {
        guard let url else {
            logger.log("Url is needed to store recent search in history, but was nil.",
                       level: .debug,
                       category: .searchEngines)
            return
        }
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        historyStorage.noteHistoryMetadata(
            for: trimmed.lowercased(),
            and: url,
            completion: { _ in }
        )
    }

    /// Retrieves list of search terms from our history storage, `Rust Places` and saved in `places.db` locally.
    ///
    /// Only care about returning the `maxNumberOfSuggestions`.
    /// We don't have an interface to fetch only a certain amount, so we follow what Android does for now.
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
}
