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
    func getOrderedEngines(completion: @escaping ([OpenSearchEngine]) -> Void)
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
/// Default search engines are localized and given by the `SearchEngineProvider` (from list.json). The user may add
/// additional custom search engines. Custom search engines entered by the user are saved to a file.
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

        getOrderedEngines { orderedEngines in
            self.orderedEngines = orderedEngines
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
    private lazy var disabledEngines: [String: Bool] = getDisabledEngines() {
        didSet {
            if isSECEnabled {
                self.prefs.setObject(Array(self.disabledEngines.keys), forKey: disabledEngineIDsPrefsKey)
            } else {
                self.prefs.setObject(Array(self.disabledEngines.keys), forKey: legacy_disabledEngineNamesPrefsKey)
            }
        }
    }

    var orderedEngines: [OpenSearchEngine] {
        didSet {
            if isSECEnabled {
                self.prefs.setObject(self.orderedEngines.map { $0.engineID }, forKey: orderedEngineIDsPrefsKey)
            } else {
                self.prefs.setObject(self.orderedEngines.map { $0.shortName }, forKey: legacy_orderedEngineNamesPrefsKey)
            }
        }
    }

    /// The subset of search engines that are enabled and not the default search engine.
    ///
    /// The results can be empty if the user disables all search engines besides the default (which can't be disabled).
    var quickSearchEngines: [OpenSearchEngine] {
        return self.orderedEngines.filter({ (engine) in !self.isEngineDefault(engine) && self.isEngineEnabled(engine) })
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
            return disabledEngines.index(forKey: engine.engineID) == nil
        } else {
            return disabledEngines.index(forKey: engine.shortName) == nil
        }
    }

    func enableEngine(_ engine: OpenSearchEngine) {
        if isSECEnabled {
            disabledEngines.removeValue(forKey: engine.engineID)
        } else {
            disabledEngines.removeValue(forKey: engine.shortName)
        }
    }

    func disableEngine(_ engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        if isSECEnabled {
            disabledEngines[engine.engineID] = true
        } else {
            disabledEngines[engine.shortName] = true
        }
    }

    func deleteCustomEngine(_ engine: OpenSearchEngine, completion: @escaping () -> Void) {
        // We can't delete a preinstalled engine or an engine that is currently the default.
        guard engine.isCustomEngine || isEngineDefault(engine) else { return }

        customEngines.remove(at: customEngines.firstIndex(of: engine)!)
        saveCustomEngines()

        getOrderedEngines { orderedEngines in
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

    private func getDisabledEngines() -> [String: Bool] {
        let prefsKey = isSECEnabled ? disabledEngineIDsPrefsKey : legacy_disabledEngineNamesPrefsKey
        if let disabledEngines = prefs.stringArrayForKey(prefsKey) {
            var disabledEnginesDict = [String: Bool]()
            for engine in disabledEngines {
                disabledEnginesDict[engine] = true
            }
            return disabledEnginesDict
        } else {
            return [String: Bool]()
        }
    }

    func getOrderedEngines(completion: @escaping ([OpenSearchEngine]) -> Void) {
        let enginePrefs: [String]?
        if isSECEnabled {
            enginePrefs = prefs.stringArrayForKey(self.orderedEngineIDsPrefsKey)
        } else {
            enginePrefs = prefs.stringArrayForKey(self.legacy_orderedEngineNamesPrefsKey)
        }
        // TODO: [FXIOS-11502] Prefs handling needs further investigation for SEC.
        engineProvider.getOrderedEngines(customEngines: customEngines,
                                         orderedEngineNames: enginePrefs,
                                         completion: completion)
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
