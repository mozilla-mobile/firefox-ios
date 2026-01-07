// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

protocol SearchEnginesManagerProvider: AnyObject, Sendable {
    @MainActor
    var defaultEngine: OpenSearchEngine? { get }
    @MainActor
    var orderedEngines: [OpenSearchEngine] { get }
    @MainActor
    var delegate: SearchEngineDelegate? { get set }
    @MainActor
    func getOrderedEngines(completion: @escaping SearchEngineCompletion)
}

protocol SearchEngineDelegate: AnyObject {
    func searchEnginesDidUpdate()
}

struct SearchEngineProviderFactory {
    static let defaultSearchEngineProvider: SearchEngineProvider = ASSearchEngineProvider()
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
@MainActor
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

    init(prefs: Prefs,
         files: FileAccessor,
         engineProvider: SearchEngineProvider = SearchEngineProviderFactory.defaultSearchEngineProvider) {
        self.prefs = prefs
        self.fileAccessor = files
        self.engineProvider = engineProvider
        self.orderedEngines = []
        initPrefBasedSuggestions()

        logger.log("[SEC] Search engine provider: \(String(describing: type(of: engineProvider)))",
                   level: .info,
                   category: .remoteSettings)

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
        shouldShowTrendingSearches = prefs.boolForKey(
            PrefsKeys.SearchSettings.showTrendingSearches
        ) ?? true
        shouldShowRecentSearches = prefs.boolForKey(
            PrefsKeys.SearchSettings.showRecentSearches
        ) ?? true
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
            prefs.setObject(Array(disabledEngines), forKey: disabledEngineIDsPrefsKey)
        }
    }

    var orderedEngines: [OpenSearchEngine] {
        didSet {
            prefs.setObject(orderedEngines.map { $0.engineID }, forKey: orderedEngineIDsPrefsKey)
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

    var shouldShowTrendingSearches = true {
        didSet {
            prefs.setBool(
                shouldShowTrendingSearches,
                forKey: PrefsKeys.SearchSettings.showTrendingSearches
            )
        }
    }

    var shouldShowRecentSearches = true {
        didSet {
            prefs.setBool(
                shouldShowRecentSearches,
                forKey: PrefsKeys.SearchSettings.showRecentSearches
            )
        }
    }

    func isEngineEnabled(_ engine: OpenSearchEngine) -> Bool {
        return !disabledEngines.contains(engine.engineID)
    }

    func enableEngine(_ engine: OpenSearchEngine) {
        disabledEngines.removeAll { $0 == engine.engineID }
    }

    func disableEngine(_ engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        let engineKey = engine.engineID
        if !disabledEngines.contains(engineKey) {
            disabledEngines.append(engineKey)
        }
    }

    func deleteCustomEngine(_ engine: OpenSearchEngine, completion: @MainActor @escaping () -> Void) {
        // We can't delete a preinstalled engine or an engine that is currently the default.
        guard engine.isCustomEngine && !isEngineDefault(engine) else { return }

        customEngines.remove(at: customEngines.firstIndex(of: engine)!)
        saveCustomEngines()

        orderedEngines.removeAll(where: { $0.engineID == engine.engineID })
        delegate?.searchEnginesDidUpdate()

        completion()
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

    func resetPrefs() {
        let keys = [orderedEngineIDsPrefsKey,
                    legacy_orderedEngineNamesPrefsKey,
                    disabledEngineIDsPrefsKey,
                    legacy_disabledEngineNamesPrefsKey]
        keys.forEach { prefs.removeObjectForKey($0) }
        resetCustomEngines()
    }

    // MARK: - Private

    private func getDisabledEngines() -> [String] {
        let prefsKey = disabledEngineIDsPrefsKey
        return prefs.stringArrayForKey(prefsKey) ?? []
    }

    func getOrderedEngines(completion: @escaping SearchEngineCompletion) {
        let enginePrefs = getSearchPrefs()
        engineProvider.getOrderedEngines(customEngines: customEngines,
                                         engineOrderingPrefs: enginePrefs,
                                         prefsMigrator: DefaultSearchEnginePrefsMigrator(),
                                         completion: completion)
        // After decoding our engines, ensure we save them back to disk, to ensure any
        // defaults generated during decoding (e.g. UUIDs for custom engines) are re-saved
        saveCustomEngines()
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

    private func resetCustomEngines() {
        guard let customEngineFilePath = try? customEngineFilePath else { return }
        let url = URL(fileURLWithPath: customEngineFilePath)
        try? FileManager.default.removeItem(at: url)
    }

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
