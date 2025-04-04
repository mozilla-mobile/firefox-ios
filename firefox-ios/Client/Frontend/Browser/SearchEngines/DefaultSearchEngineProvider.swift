// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

typealias SearchEngineCompletion = (SearchEnginePrefs, [OpenSearchEngine]) -> Void

protocol SearchEngineProvider {
    /// Takes a list of custom search engines (added by the user) along with an ordered
    /// engine name list (to provide sorting) which is stored in Prefs, and returns a
    /// a final list of search engines.
    /// - Parameters:
    ///   - customEngines: custom engines added by the local user
    ///   - orderedEngineNames: ordered engine names for sorting
    ///   - completion: the completion block called with the final results
    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion)

    /// Returns the search ordering preference format that this provider utilizes.
    var preferencesVersion: SearchEngineOrderingPrefsVersion { get }
}

enum SearchEngineOrderingPrefsVersion {
    case v1 // Pre-bundled XML search engines, before Search Consolidation
    case v2 // Consolidated search (engines are fetched from Remote Settings)
}

struct SearchEnginePrefs {
    /// The ordered list of engines (first engine is the default)
    let engineIdentifiers: [String]?
    /// A list of engines that are disabled
    let disabledEngines: [String]?
    /// Identifies the schema of how the ordering values are saved to disk
    let version: SearchEngineOrderingPrefsVersion
}

class DefaultSearchEngineProvider: SearchEngineProvider {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    let preferencesVersion: SearchEngineOrderingPrefsVersion = .v1

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           engineOrderingPrefs: SearchEnginePrefs,
                           prefsMigrator: SearchEnginePreferencesMigrator,
                           completion: @escaping SearchEngineCompletion) {
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        let prefsVersion = preferencesVersion

        // First load the unordered engines, based on the current locale and language
        getUnorderedBundledEnginesFor(locale: locale,
                                      possibleLanguageIdentifier: locale.possibilitiesForLanguageIdentifier(),
                                      completion: { engineResults in
            let unorderedEngines = customEngines + engineResults
            let finalEngineOrderingPrefs = prefsMigrator.migratePrefsIfNeeded(engineOrderingPrefs,
                                                                              to: prefsVersion,
                                                                              availableEngines: unorderedEngines)

            guard let orderedEngineNames = finalEngineOrderingPrefs.engineIdentifiers,
                  !orderedEngineNames.isEmpty else {
                // We haven't persisted the engine order, so return whatever order we got from disk.
                DispatchQueue.main.async {
                    completion(finalEngineOrderingPrefs, unorderedEngines)
                }

                return
            }

            // We have a persisted order of engines, so try to use that order.
            // We may have found engines that weren't persisted in the ordered list
            // (if the user changed locales or added a new engine); these engines
            // will be appended to the end of the list.
            let orderedEngines = unorderedEngines.sorted { engine1, engine2 in
                let index1 = orderedEngineNames.firstIndex(of: engine1.shortName)
                let index2 = orderedEngineNames.firstIndex(of: engine2.shortName)

                if index1 == nil && index2 == nil {
                    return engine1.shortName < engine2.shortName
                }

                // nil < N for all non-nil values of N.
                if index1 == nil || index2 == nil {
                    return index1 ?? -1 > index2 ?? -1
                }

                return index1! < index2!
            }

            DispatchQueue.main.async {
                completion(finalEngineOrderingPrefs, orderedEngines)
            }
        })
    }

    private func getUnorderedBundledEnginesFor(locale: Locale,
                                               possibleLanguageIdentifier: [String],
                                               completion: @escaping ([OpenSearchEngine]) -> Void ) {
        let region = locale.regionCode ?? "US"
        let parser = OpenSearchParser(pluginMode: true)

        guard let pluginDirectory = Bundle.main.resourceURL?.appendingPathComponent("SearchPlugins") else {
            logger.log("Search plugins not found. Check bundle", level: .fatal, category: .setup)
            fatalError("We are unable to populate search engines for this locale because SearchPlugins is missing.")
        }
        guard let defaultSearchPrefs = DefaultSearchPrefs(
            with: pluginDirectory.appendingPathComponent("list.json")
        ) else {
            logger.log("Failed to parse List.json", level: .fatal, category: .setup)
            fatalError("We are unable to populate search engines for this locale because list.json could not be parsed.")
        }

        // Load the engines which are available for the user's language and region settings
        let engineNames = defaultSearchPrefs.visibleDefaultEngines(for: possibleLanguageIdentifier, and: region)
        let defaultEngineName = defaultSearchPrefs.searchDefault(for: possibleLanguageIdentifier, and: region)

        guard !engineNames.isEmpty else {
            logger.log("No search engines.", level: .fatal, category: .setup)
            fatalError("Unable to populate search engines for locale because possibilities is blank.")
        }

        // Map the engine identifiers in `engineNames` to the matching XML file bundled in our SearchPlugins
        DispatchQueue.global().async {
            let result = engineNames.map({ (name: $0, path: pluginDirectory.appendingPathComponent("\($0).xml").path) })
                .filter({
                    FileManager.default.fileExists(atPath: $0.path)
                }).compactMap({
                    parser.parse($0.path, engineID: $0.name)
                }).sorted { e, _ in
                    e.shortName == defaultEngineName
                }

            completion(result)
        }
    }
}
