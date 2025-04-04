// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

struct SearchEngineFlagManager {
    /// Whether Search Engine Consolidation is enabled.
    /// If enabled, search engines are fetched from Remote Settings rather than our pre-bundled XML files.
    static var isSECEnabled: Bool {
        // return LegacyFeatureFlagsManager.shared.isFeatureEnabled(.searchEngineConsolidation, checking: .buildOnly)
        // SEC always disabled (for now)
        return false
    }

    /// Temporary. App Services framework does not yet have all dumps in place to provide
    /// cached results. To force a sync for testing purposes, you can enable this flag.
    static let temp_dbg_forceASSync = false
}

protocol SearchEnginesManagerProvider {
    var defaultEngine: OpenSearchEngine? { get }
    var orderedEngines: [OpenSearchEngine] { get }
    func getOrderedEngines(completion: @escaping SearchEngineCompletion)
}

protocol SearchEngineDelegate: AnyObject {
    func searchEnginesDidUpdate()
}

struct SearchEngineProviderFactory {
    static var defaultSearchEngineProvider: SearchEngineProvider = {
        let secEnabled = SearchEngineFlagManager.isSECEnabled
        return secEnabled ? ASSearchEngineProvider() : DefaultSearchEngineProvider()
    }()
}

/// Manages a set of `OpenSearchEngine`s.
///
/// The search engines are ordered and can be enabled and disabled by the user. Order and disabled state are backed by a
/// write-through cache into a Prefs instance (i.e. UserDefaults).
///
/// Originally, default search engines were localized and given by the `SearchEngineProvider` (from list.json). With the
/// forthcoming updates for Search Consolidation (FXIOS-8469) this will be changing, and the engines will be vended via
/// Application Services. The user may add additional custom search engines. Custom search engines entered by the user are
/// saved to a file.
///
/// The first search engine is distinguished and labeled the "default" search engine; it can never be disabled.
/// [FIXME FXIOS-10187 this will change soon ->] Search suggestions should always be sourced from the default search engine
///
/// Two additional bits of information are maintained: whether search suggestions are enabled and whether search suggestions
/// in private mode are disabled.
///
/// Consumers will almost always use `defaultEngine` if they want a single search engine, and `quickSearchEngines()` if they
/// want a list of enabled quick search engines (possibly empty, since the default engine is never included in the list of
/// enabled quick search engines, and it is possible to disable every non-default quick search engine).
///
/// This class is not thread-safe -- you should only access it on a single thread (usually, the main thread)!
class SearchEnginesManager: SearchEnginesManagerProvider {
    private let prefs: Prefs
    private let fileAccessor: FileAccessor

    // Preference keys for old (pre-bundled XML-based) search engines
    private let legacy_orderedEngineNamesPrefsKey = "search.orderedEngineNames"
    private let legacy_disabledEngineNamesPrefsKey = "search.disabledEngineNames"

    // Preference keys for new Application Services based search engines
    private let orderedEngineIDsPrefsKey = "search.sec.orderedEngineIDs"
    private let disabledEngineIDsPrefsKey = "search.sec.disabledEngineIDs"

    private let customSearchEnginesFileName = "customEngines.plist"
    private var engineProvider: SearchEngineProvider

    weak var delegate: SearchEngineDelegate?
    private var logger: Logger = DefaultLogger.shared

    private lazy var isSECEnabled: Bool = { SearchEngineFlagManager.isSECEnabled }()

    init(prefs: Prefs,
         files: FileAccessor,
         engineProvider: SearchEngineProvider = SearchEngineProviderFactory.defaultSearchEngineProvider) {
        self.prefs = prefs
        self.fileAccessor = files
        self.engineProvider = engineProvider
        self.orderedEngines = []
        initPrefBasedSuggestions()

        getOrderedEngines { preferences, orderedEngines in
            self.orderedEngines = orderedEngines

            // Our preferences may have been migrated as part of fetching our engines
            // Make sure we update our disabled engine list. We only need to do this
            // explicitly for disabled engines, the engine ordering will be updated
            // by the setter for the orderedEngines property.
            self.disabledEngines = preferences.disabledEngines ?? []

            self.delegate?.searchEnginesDidUpdate()
        }
    }

    private func initPrefBasedSuggestions() {
        shouldShowSearchSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showSearchSuggestions
        ) ?? true
        shouldShowBrowsingHistorySuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showFirefoxBrowsingHistorySuggestions
        ) ?? true
        shouldShowBookmarksSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showFirefoxBookmarksSuggestions
        ) ?? true
        shouldShowSyncedTabsSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showFirefoxSyncedTabsSuggestions
        ) ?? true
        shouldShowFirefoxSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showFirefoxNonSponsoredSuggestions
        ) ?? true
        shouldShowSponsoredSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showFirefoxSponsoredSuggestions
        ) ?? true
        shouldShowPrivateModeFirefoxSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showPrivateModeFirefoxSuggestions
        ) ?? false
        shouldShowPrivateModeSearchSuggestions = prefs.boolForKey(
            PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions
        ) ?? false
    }

    var defaultEngine: OpenSearchEngine? {
        get {
            return self.orderedEngines[safe: 0]
        }

        set(defaultEngine) {
            // The default engine is always enabled.
            guard let defaultEngine = defaultEngine else { return }

            self.enableEngine(defaultEngine)
            // The default engine is always first in the list.
            var orderedEngines = self.orderedEngines.filter { engine in engine.shortName != defaultEngine.shortName }
            orderedEngines.insert(defaultEngine, at: 0)
            self.orderedEngines = orderedEngines
        }
    }

    func isEngineDefault(_ engine: OpenSearchEngine) -> Bool {
        return defaultEngine?.shortName == engine.shortName
    }

    // The keys of this dictionary are used as a set.
    private lazy var disabledEngines: [String] = getDisabledEngines() {
        didSet {
            if isSECEnabled {
                prefs.setObject(Array(disabledEngines), forKey: disabledEngineIDsPrefsKey)
            } else {
                prefs.setObject(Array(disabledEngines), forKey: legacy_disabledEngineNamesPrefsKey)
            }
        }
    }

    var orderedEngines: [OpenSearchEngine] {
        didSet {
            if isSECEnabled {
                prefs.setObject(orderedEngines.map { $0.engineID }, forKey: orderedEngineIDsPrefsKey)
            } else {
                prefs.setObject(orderedEngines.map { $0.shortName }, forKey: legacy_orderedEngineNamesPrefsKey)
            }
        }
    }

    /// The subset of search engines that are enabled and not the default search engine.
    ///
    /// The results can be empty if the user disables all search engines besides the default (which can't be disabled).
    var quickSearchEngines: [OpenSearchEngine] {
        return orderedEngines.filter({ (engine) in !self.isEngineDefault(engine) && self.isEngineEnabled(engine) })
    }

    var shouldShowSearchSuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowSearchSuggestions,
                forKey: PrefsKeys.SearchSettings.showSearchSuggestions
            )
        }
    }

    var shouldShowBrowsingHistorySuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowBrowsingHistorySuggestions,
                forKey: PrefsKeys.SearchSettings.showFirefoxBrowsingHistorySuggestions
            )
        }
    }

    var shouldShowBookmarksSuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowBookmarksSuggestions,
                forKey: PrefsKeys.SearchSettings.showFirefoxBookmarksSuggestions
            )
        }
    }

    var shouldShowSyncedTabsSuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowSyncedTabsSuggestions,
                forKey: PrefsKeys.SearchSettings.showFirefoxSyncedTabsSuggestions
            )
        }
    }

    var shouldShowFirefoxSuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowFirefoxSuggestions,
                forKey: PrefsKeys.SearchSettings.showFirefoxNonSponsoredSuggestions
            )
        }
    }

    var shouldShowSponsoredSuggestions = true {
        didSet {
            prefs.setBool(
                shouldShowSponsoredSuggestions,
                forKey: PrefsKeys.SearchSettings.showFirefoxSponsoredSuggestions
            )
        }
    }

    var shouldShowPrivateModeFirefoxSuggestions = false {
        didSet {
            prefs.setBool(
                shouldShowPrivateModeFirefoxSuggestions,
                forKey: PrefsKeys.SearchSettings.showPrivateModeFirefoxSuggestions
            )
        }
    }

    var shouldShowPrivateModeSearchSuggestions = false {
        didSet {
            prefs.setBool(
                shouldShowPrivateModeSearchSuggestions,
                forKey: PrefsKeys.SearchSettings.showPrivateModeSearchSuggestions
            )
        }
    }

    func isEngineEnabled(_ engine: OpenSearchEngine) -> Bool {
        if isSECEnabled {
            return !disabledEngines.contains(engine.engineID)
        } else {
            return !disabledEngines.contains(engine.shortName)
        }
    }

    func enableEngine(_ engine: OpenSearchEngine) {
        if isSECEnabled {
            disabledEngines.removeAll { $0 == engine.engineID }
        } else {
            disabledEngines.removeAll { $0 == engine.shortName }
        }
    }

    func disableEngine(_ engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        let engineKey = isSECEnabled ? engine.engineID : engine.shortName
        if !disabledEngines.contains(engineKey) {
            disabledEngines.append(engineKey)
        }
    }

    func deleteCustomEngine(_ engine: OpenSearchEngine, completion: @escaping () -> Void) {
        // We can't delete a preinstalled engine or an engine that is currently the default.
        guard engine.isCustomEngine || isEngineDefault(engine) else { return }

        customEngines.remove(at: customEngines.firstIndex(of: engine)!)
        saveCustomEngines()

        getOrderedEngines { enginePreferences, orderedEngines in
            self.orderedEngines = orderedEngines
            self.delegate?.searchEnginesDidUpdate()

            completion()
        }
    }

    /// Adds an engine to the front of the search engines list.
    func addSearchEngine(_ engine: OpenSearchEngine) {
        customEngines.append(engine)
        orderedEngines.insert(engine, at: 1)
        saveCustomEngines()
    }

    func queryForSearchURL(_ url: URL?) -> String? {
        for engine in orderedEngines {
            guard let searchTerm = engine.queryForSearchURL(url) else { continue }
            return searchTerm
        }
        return nil
    }

    // MARK: - Private

    private func getDisabledEngines() -> [String] {
        let prefsKey = isSECEnabled ? disabledEngineIDsPrefsKey : legacy_disabledEngineNamesPrefsKey
        return prefs.stringArrayForKey(prefsKey) ?? []
    }

    func getOrderedEngines(completion: @escaping SearchEngineCompletion) {
        let enginePrefs = getSearchPrefs()
        engineProvider.getOrderedEngines(customEngines: customEngines,
                                         engineOrderingPrefs: enginePrefs,
                                         prefsMigrator: DefaultSearchEnginePrefsMigrator(),
                                         completion: completion)
    }

    private func getSearchPrefs() -> SearchEnginePrefs {
        let enginePrefs: SearchEnginePrefs

        // TODO: [FXIOS-11403] This code can be cleaned up significantly once we have fully enabled SEC for all users.
        let v2PrefsKey = orderedEngineIDsPrefsKey
        let v1PrefsKey = legacy_orderedEngineNamesPrefsKey
        let v2DisabledKey = disabledEngineIDsPrefsKey
        let v1DisabledKey = legacy_disabledEngineNamesPrefsKey

        func fetchPrefs(_ version: SearchEngineOrderingPrefsVersion) -> SearchEnginePrefs {
            switch version {
            case .v2:
                let engineStrings = prefs.stringArrayForKey(v2PrefsKey)
                let disabled = prefs.stringArrayForKey(v2DisabledKey)
                return SearchEnginePrefs(engineIdentifiers: engineStrings, disabledEngines: disabled, version: .v2)
            case .v1:
                let engineStrings = prefs.stringArrayForKey(v1PrefsKey)
                let disabled = prefs.stringArrayForKey(v1DisabledKey)
                return SearchEnginePrefs(engineIdentifiers: engineStrings, disabledEngines: disabled, version: .v1)
            }
        }

        if isSECEnabled {
            if prefs.hasObjectForKey(v2PrefsKey) {
                // v2 (SEC) preferences are available on-disk
                enginePrefs = fetchPrefs(.v2)
            } else if prefs.hasObjectForKey(v1PrefsKey) {
                // We're running for the first time with SEC enabled but haven't yet saved ordering
                // prefs for those engines. We send the v1 preferences which will be migrated.
                enginePrefs = fetchPrefs(.v1)
            } else {
                // Fresh install. No v2 or v1 preferences.
                enginePrefs = SearchEnginePrefs(engineIdentifiers: nil, disabledEngines: nil, version: .v2)
            }
        } else {
            if prefs.hasObjectForKey(v1PrefsKey) {
                enginePrefs = fetchPrefs(.v1)
            } else if prefs.hasObjectForKey(v2PrefsKey) {
                // Unlikely, but it's possible a new user installed during SEC experiment, and then was
                // moved out of the SEC experiment.
                enginePrefs = fetchPrefs(.v2)
            } else {
                enginePrefs = SearchEnginePrefs(engineIdentifiers: nil, disabledEngines: nil, version: .v1)
            }
        }
        return enginePrefs
    }

    private var customEngineFilePath: String {
        get throws {
            let profilePath = try self.fileAccessor.getAndEnsureDirectory() as NSString
            return profilePath.appendingPathComponent(customSearchEnginesFileName)
        }
    }

    private lazy var customEngines: [OpenSearchEngine] = {
        if let customEngineFilePath = try? customEngineFilePath,
           let data = try? Data(contentsOf: URL(fileURLWithPath: customEngineFilePath)) {
            do {
                let unarchiveClasses = [NSArray.self, OpenSearchEngine.self, NSString.self, UIImage.self]
                let customEngines = try NSKeyedUnarchiver.unarchivedObject(ofClasses: unarchiveClasses,
                                                                           from: data) as? [OpenSearchEngine]
                return customEngines ?? []
            } catch {
                logger.log("Error unarchiving engines from data: \(error.localizedDescription)",
                           level: .debug,
                           category: .storage)
                return []
            }
        } else {
            return []
        }
    }()

    private func saveCustomEngines() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: customEngines, requiringSecureCoding: true)

            do {
                try data.write(to: URL(fileURLWithPath: try customEngineFilePath))
            } catch {
                logger.log("Error writing data to file: \(error.localizedDescription)",
                           level: .debug,
                           category: .storage)
            }
        } catch {
            logger.log("Error archiving custom engines: \(error.localizedDescription)",
                       level: .debug,
                       category: .storage)
        }
    }
}
