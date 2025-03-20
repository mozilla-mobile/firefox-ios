// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Accounts
import Common
import Shared

/// Provides a Remote-Settings-based substitute for our DefaultSearchEngineProvider
/// This is unused unless SEC (Search Engine Consolidation) experiment is enabled.
final class ASSearchEngineProvider: SearchEngineProvider {
    private let logger: Logger
    private let iconDataFetcher: ASSearchEngineIconDataFetcherProtocol?
    private let selector: ASSearchEngineSelectorProtocol?

    init(logger: Logger = DefaultLogger.shared,
         selector: ASSearchEngineSelectorProtocol? = nil,
         iconDataFetcher: ASSearchEngineIconDataFetcherProtocol? = ASSearchEngineIconDataFetcher()) {
        self.logger = logger
        self.iconDataFetcher = iconDataFetcher
        let profile = (AppContainer.shared.resolve() as Profile)
        if selector == nil, let service = profile.remoteSettingsService {
            self.selector = ASSearchEngineSelector(service: service)
        } else {
            self.selector = selector
        }
    }

    // MARK: - SearchEngineProvider

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           orderedEngineNames: [String]?,
                           completion: @escaping ([OpenSearchEngine]) -> Void) {
        // Note: this currently duplicates the logic from DefaultSearchEngineProvider.
        // Eventually that class will be removed once we switch fully to consolidated search.

        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)

        // First load the unordered engines, based on the current locale and language
        getUnorderedBundledEnginesFor(locale: locale,
                                      possibleLanguageIdentifier: locale.possibilitiesForLanguageIdentifier(),
                                      completion: { engineResults in
            let unorderedEngines = customEngines + engineResults
            guard let orderedEngineNames = orderedEngineNames else {
                // We haven't persisted the engine order, so return whatever order we got from disk.
                ensureMainThread { completion(unorderedEngines) }
                return
            }

            // We have a persisted order of engines, so try to use that order.
            // We may have found engines that weren't persisted in the ordered list
            // (if the user changed locales or added a new engine); these engines
            // will be appended to the end of the list.
            let orderedEngines = unorderedEngines.sorted { engine1, engine2 in
                let index1 = orderedEngineNames.firstIndex(of: engine1.engineID)
                let index2 = orderedEngineNames.firstIndex(of: engine2.engineID)

                if index1 == nil && index2 == nil {
                    return engine1.shortName < engine2.shortName
                }

                if let index1, let index2 {
                    return index1 < index2
                } else {
                    // nil < N for all non-nil values of N.
                    return index1 ?? -1 > index2 ?? -1
                }
            }

            ensureMainThread { completion(orderedEngines) }
        })
    }

    // MARK: - Private Utilities

    private func getUnorderedBundledEnginesFor(locale: Locale,
                                               possibleLanguageIdentifier: [String],
                                               completion: @escaping ([OpenSearchEngine]) -> Void ) {
        let localeCode = localeCode(from: locale)
        let region = regionCode(from: locale)
        let logger = self.logger
        guard let iconPopulator = iconDataFetcher, let selector else { completion([]); return }

        selector.fetchSearchEngines(locale: localeCode, region: region) { (result, error) in
            if let error {
                logger.log("Error fetching search engines via App Services: \(error)",
                           level: .warning,
                           category: .remoteSettings)
            }

            guard let result, !result.engines.isEmpty else {
                logger.log("Search engine fetch returned empty results",
                           level: .warning,
                           category: .remoteSettings)
                completion([])
                return
            }

            // Per AS team, optional engines can be ignored. Currently only used on Android.
            let filteredEngines = result.engines.filter { $0.optional == false }

            // TODO: can we parallelize this? We need the search engines before we can use the icon data but the initial
            // icon fetch can be done concurrently with the search engine request

            iconPopulator.populateEngineIconData(filteredEngines) { enginesAndIcons in
                var openSearchEngines: [OpenSearchEngine] = []
                for (engine, iconImage) in enginesAndIcons {
                    openSearchEngines.append(ASSearchEngineUtilities.convertASToOpenSearch(engine, image: iconImage))
                }
                completion(openSearchEngines)
            }
        }
    }

    private func localeCode(from locale: Locale) -> String {
        // Per feedback from AS team, we want to pass in the 2-component BCP 47 code. In some
        // rare cases this may include a script with the region, if so we remove that.
        // See also: Locale+possibilitiesForLanguageIdentifier.swift

        let identifier = locale.identifier
        let components = identifier.components(separatedBy: "-")
        if components.count == 3, let first = components.first, let last = components.last {
            return "\(first)-\(last)"
        }
        return identifier
    }

    private func regionCode(from locale: Locale) -> String {
        let systemRegion: String?
        if #available(iOS 17, *) {
            systemRegion = (locale as NSLocale).regionCode
        } else {
            systemRegion = (locale as NSLocale).countryCode
        }
        return systemRegion ?? locale.identifier.components(separatedBy: "-").last ?? "US"
    }
}
