// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

typealias SearchEngineCompletion = @MainActor (SearchEnginePrefs, [OpenSearchEngine]) -> Void

protocol SearchEngineProvider: Sendable {
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
