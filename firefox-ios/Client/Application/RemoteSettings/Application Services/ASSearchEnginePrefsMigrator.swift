// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol SearchEnginePreferencesMigrator {
    func migratePrefsIfNeeded(_ prefs: SearchEngineOrderingPrefs,
                              to expectedVersion: SearchEngineOrderingPrefsVersion,
                              availableEngines: [OpenSearchEngine]) -> SearchEngineOrderingPrefs
}

struct DefaultSearchEnginePrefsMigrator: SearchEnginePreferencesMigrator {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    // MARK: - SearchEnginePreferencesMigrator

    func migratePrefsIfNeeded(_ prefs: SearchEngineOrderingPrefs,
                              to expectedVersion: SearchEngineOrderingPrefsVersion,
                              availableEngines: [OpenSearchEngine]) -> SearchEngineOrderingPrefs {
        guard prefs.version != expectedVersion else {
            logInfo("No migration needed for search prefs.")
            return prefs
        }

        guard let inputIdentifiers = prefs.engineIdentifiers, !inputIdentifiers.isEmpty else {
            logWarning("Migration input engine list was empty or nil.")
            return SearchEngineOrderingPrefs(engineIdentifiers: nil, version: expectedVersion)
        }

        // Keeping the ordering intact, iterate over the name or ID of each engine and try to convert
        // that to the name or ID of the available engine. v1 prefs utilize the engine shortName while
        // v2 preferences will use the engine identifier.
        let engineIdentifiers: [String]
        if expectedVersion == .v2 {
            // Map existing short names of XML engines to the AS-based engines
            engineIdentifiers = inputIdentifiers.compactMap {
                let shortName = $0.lowercased()
                // This may perform multiple O(N) loops but these are extremely small collections (typically 5-7 elements)
                let engine = availableEngines.first { return $0.engineID.lowercased() == shortName }
                ?? availableEngines.first { return $0.shortName.lowercased() == shortName }
                ?? availableEngines.first {
                    return $0.engineID.lowercased().hasPrefix(shortName) || $0.shortName.lowercased().hasPrefix(shortName)
                }
                if let engine { logInfo("[SEC] Mapped v1 '\(shortName)' to v2 '\(engine.engineID)'") }
                return engine?.engineID
            }
        } else {
            // Moving backwards. This should be rare but we should support it anyway.
            // A user may move out of the SEC experiment group and back to the XML engines.

            // Map existing identifiers of AS-based engines to our XML engines
            engineIdentifiers = inputIdentifiers.compactMap {
                let identifier = $0.lowercased()
                let engine = availableEngines.first { return $0.shortName.lowercased() == identifier }
                ?? availableEngines.first { return $0.engineID.lowercased() == identifier }
                ?? availableEngines.first {
                    return $0.engineID.lowercased().hasPrefix(identifier) || $0.shortName.lowercased().hasPrefix(identifier)
                }
                if let engine { logInfo("[SEC] Mapped v2 '\(identifier)' to v1 '\(engine.shortName)'") }
                return engine?.shortName
            }
        }

        let newPrefs = SearchEngineOrderingPrefs(engineIdentifiers: engineIdentifiers, version: expectedVersion)
        return newPrefs
    }

    // MARK: - Utility

    private func logInfo(_ msg: String) {
        logger.log(msg, level: .info, category: .remoteSettings)
    }

    private func logWarning(_ msg: String) {
        logger.log(msg, level: .warning, category: .remoteSettings)
    }
}
