// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Accounts
import Common
import Shared

/// Provides a Remote-Settings-based substitute for our DefaultSearchEngineProvider
/// This is unused unless SEC (Search Engine Consolidation) experiment is enabled.
final class ASSearchEngineProvider: SearchEngineProvider, Sendable {
    private let logger: Logger
    private let iconDataFetcher: ASSearchEngineIconDataFetcherProtocol?
    private let selector: ASSearchEngineSelectorProtocol?

    init(logger: Logger = DefaultLogger.shared,
         selector: ASSearchEngineSelectorProtocol? = nil,
         iconDataFetcher: ASSearchEngineIconDataFetcherProtocol? = ASSearchEngineIconDataFetcher()) {
        self.logger = logger
        self.iconDataFetcher = iconDataFetcher
        let profile = (AppContainer.shared.resolve() as Profile)
        if selector == nil {
            self.selector = ASSearchEngineSelector(service: profile.remoteSettingsService )
        } else {
            self.selector = selector
        }
    }

    // MARK: - SearchEngineProvider

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v2

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        DispatchQueue.global().async { [weak self] in
            // Note: this currently duplicates the logic from DefaultSearchEngineProvider.
            // Eventually that class will be removed once we switch fully to consolidated search.
            self?.fetchUnorderedEnginesAndApplyOrdering(
                customEngines: customEngines,
                engineOrderingPrefs: engineOrderingPrefs,
                prefsMigrator: prefsMigrator,
                completion: completion
            )
        }
    }

    // MARK: - Private Utilities

    private func fetchUnorderedEnginesAndApplyOrdering(customEngines: [OpenSearchEngine],
                                                       engineOrderingPrefs: SearchEnginePrefs,
                                                       prefsMigrator: SearchEnginePreferencesMigrator,
                                                       completion: @escaping SearchEngineCompletion) {
        let locale = SystemLocaleProvider()
        let prefsVersion = preferencesVersion
        let closureLogger = logger

        // First load the unordered engines, based on the current locale and language
        // swiftlint:disable closure_body_length
        getUnorderedBundledEnginesFor(locale: locale,
                                      completion: { engineResults in
            let unorderedEngines = customEngines + engineResults
            let finalEngineOrderingPrefs = prefsMigrator.migratePrefsIfNeeded(engineOrderingPrefs,
                                                                              to: prefsVersion,
                                                                              availableEngines: unorderedEngines)

            guard let orderedEngineNames = finalEngineOrderingPrefs.engineIdentifiers,
                  !orderedEngineNames.isEmpty else {
                // We haven't persisted the engine order, so use the default engine ordering.
                // For AS-based engines we are guaranteed the preferred default to be at index 0
                // (this happens in `fetchSearchEngines()`).
                closureLogger.log("[SEC] Search order prefs: NO. (Unavailable, or empty.)",
                                  level: .info,
                                  category: .remoteSettings)
                ensureMainThread { completion(finalEngineOrderingPrefs, unorderedEngines) }
                return
            }

            // We have a persisted order of engines, so try to use that order.
            // We may have found engines that weren't persisted in the ordered list
            // (if the user changed locales or added a new engine); these engines
            // will be appended to the end of the list.
            closureLogger.log("[SEC] Search order prefs: YES. Will apply (identifiers): \(orderedEngineNames)",
                              level: .info,
                              category: .remoteSettings)
            let unorderedDbgInfo = unorderedEngines.map { $0.shortName + "(\($0.engineID))" }
            closureLogger.log("[SEC] Unordered engines: \(unorderedDbgInfo)",
                              level: .info,
                              category: .remoteSettings)

            var orderedEngines: [OpenSearchEngine] = []
            var availableEngines = unorderedEngines

            // Map the user's engine prefs in-order to the available engines we have from AS
            for prefsEngineID in orderedEngineNames {
                guard let idx = availableEngines.firstIndex(where: { $0.engineID == prefsEngineID }) else {
                    closureLogger.log("[SEC] Engine ID in prefs, but no available engine. (Removed in RS?) \(prefsEngineID)",
                                      level: .warning,
                                      category: .remoteSettings)
                    continue
                }
                orderedEngines.append(availableEngines[idx])
                availableEngines.remove(at: idx)
            }

            // It's possible there are engines remaining that were not in the input preferences list.
            // This can happen for example if a new engine is added to Remote Settings.
            // Append these engines to the end of the list.
            if !availableEngines.isEmpty {
                closureLogger.log("[SEC] Appending remaining engines \(availableEngines)", level: .info, category: .remoteSettings)
                orderedEngines = orderedEngines + availableEngines
            }

            let before = unorderedEngines.map { $0.shortName }
            let after = orderedEngines.map { $0.shortName }
            closureLogger.log("[SEC] Search order prefs result. Before: \(before) After: \(after).",
                              level: .info,
                              category: .remoteSettings)

            let finalEngineOutput = orderedEngines
            ensureMainThread { completion(finalEngineOrderingPrefs, finalEngineOutput) }
        })
        // swiftlint:enable closure_body_length
    }

    private func getUnorderedBundledEnginesFor(locale: LocaleProvider,
                                               completion: @escaping ([OpenSearchEngine]) -> Void ) {
        let localeCode = ASSearchEngineUtilities.localeCode(from: locale)
        let region = locale.regionCode(fallback: "US")
        let logger = self.logger
        guard let iconPopulator = iconDataFetcher, let selector else {
            let logExtra1 = iconDataFetcher == nil ? "nil" : "ok"
            let logExtra2 = selector == nil ? "nil" : "ok"
            logger.log("[SEC] Icon fetcher and/or selector are nil. (\(logExtra1), \(logExtra2))",
                       level: .fatal,
                       category: .remoteSettings)
            completion([])
            return
        }

        selector.fetchSearchEngines(locale: localeCode, region: region) { (result, error) in
            if let error {
                logger.log("[SEC] Error fetching search engines via App Services: \(error)",
                           level: .warning,
                           category: .remoteSettings)
            }

            guard let result, !result.engines.isEmpty else {
                logger.log("[SEC] AS search engine fetch returned empty results",
                           level: .fatal,
                           category: .remoteSettings)
                completion([])
                return
            }

            // Per AS team, optional engines can be ignored. Currently only used on Android.
            let filteredEngines = result.engines.filter { $0.optional == false }

            iconPopulator.populateEngineIconData(filteredEngines) { enginesAndIcons in
                var openSearchEngines: [OpenSearchEngine] = []
                for (engine, iconImage) in enginesAndIcons {
                    openSearchEngines.append(ASSearchEngineUtilities.convertASToOpenSearch(engine, image: iconImage))
                }
                completion(openSearchEngines)
            }
        }
    }
}
