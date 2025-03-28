// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

protocol SearchEnginePreferencesMigrator {
    func migratePrefsIfNeeded(_ prefs: SearchEnginePrefs,
                              to expectedVersion: SearchEngineOrderingPrefsVersion,
                              availableEngines: [OpenSearchEngine]) -> SearchEnginePrefs
}

struct DefaultSearchEnginePrefsMigrator: SearchEnginePreferencesMigrator {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    // MARK: - SearchEnginePreferencesMigrator

    func migratePrefsIfNeeded(_ prefs: SearchEnginePrefs,
                              to expectedVersion: SearchEngineOrderingPrefsVersion,
                              availableEngines: [OpenSearchEngine]) -> SearchEnginePrefs {
        guard prefs.version != expectedVersion else {
            logInfo("[SEC] No migration needed for search prefs (already \(expectedVersion)).")
            return prefs
        }
        logInfo("[SEC] Will migrate \(prefs.version) to \(expectedVersion)")

        guard let inputIdentifiers = prefs.engineIdentifiers, !inputIdentifiers.isEmpty else {
            logWarning("[SEC] Migration input engine list was empty or nil.")
            return SearchEnginePrefs(engineIdentifiers: nil,
                                     disabledEngines: prefs.disabledEngines,
                                     version: expectedVersion)
        }
        let inputDisabledEngines = prefs.disabledEngines ?? []

        // Keeping the ordering intact, iterate over the name or ID of each engine and try to convert
        // that to the name or ID of the available engine. v1 prefs utilize the engine shortName while
        // v2 preferences will use the engine identifier.
        let engineIdentifiers: [String]
        let disabledEngines: [String]
        switch expectedVersion {
        case .v2:
            // Map existing short names of XML engines to the AS-based engines
            engineIdentifiers = inputIdentifiers.compactMap { mapV1ShortNameToV2EngineID($0, availableEngines) }
            disabledEngines = inputDisabledEngines.compactMap { mapV1ShortNameToV2EngineID($0, availableEngines) }
        case .v1:
            // Moving backwards. This should be rare but we should support it anyway.
            // A user may move out of the SEC experiment group and back to the XML engines.
            // Map existing identifiers of AS-based engines to our XML engines
            engineIdentifiers = inputIdentifiers.compactMap { mapV2EngineIDToV1ShortName($0, availableEngines) }
            disabledEngines = inputDisabledEngines.compactMap { mapV2EngineIDToV1ShortName($0, availableEngines) }
        }

        let newPrefs = SearchEnginePrefs(engineIdentifiers: engineIdentifiers,
                                         disabledEngines: disabledEngines,
                                         version: expectedVersion)
        return newPrefs
    }

    // MARK: - Internal

    private func mapV1ShortNameToV2EngineID(_ input: String, _ availableEngines: [OpenSearchEngine]) -> String? {
        let shortName = input.lowercased()
        // Performs several O(N) loops but data sets are very small (typically 4-5 elements)
        let engine = availableEngines.first { return $0.engineID.lowercased() == shortName }
        ?? availableEngines.first { return $0.shortName.lowercased() == shortName }
        ?? availableEngines.first {
            return $0.engineID.lowercased().hasPrefix(shortName) || $0.shortName.lowercased().hasPrefix(shortName)
        }
        if let engine { logInfo("[SEC] Mapped v1 '\(shortName)' to v2 '\(engine.engineID)'") }
        return engine?.engineID
    }

    private func mapV2EngineIDToV1ShortName(_ input: String, _ availableEngines: [OpenSearchEngine]) -> String? {
        let identifier = input.lowercased()
        let engine = availableEngines.first { return $0.shortName.lowercased() == identifier }
        ?? availableEngines.first { return $0.engineID.lowercased() == identifier }
        ?? availableEngines.first {
            return $0.engineID.lowercased().hasPrefix(identifier) || $0.shortName.lowercased().hasPrefix(identifier)
        }
        if let engine { logInfo("[SEC] Mapped v2 '\(identifier)' to v1 '\(engine.shortName)'") }
        return engine?.shortName
    }

    // MARK: - Utility

    private func logInfo(_ msg: String) {
        logger.log(msg, level: .info, category: .remoteSettings)
    }

    private func logWarning(_ msg: String) {
        logger.log(msg, level: .warning, category: .remoteSettings)
    }
}
