// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

protocol SearchEngineDelegate: AnyObject {
    func searchEnginesDidUpdate()
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
class SearchEnginesManager {
    private let prefs: Prefs
    private let fileAccessor: FileAccessor
    private let orderedEngineNames = "search.orderedEngineNames"
    private let disabledEngineNames = "search.disabledEngineNames"
    private let customSearchEnginesFileName = "customEngines.plist"
    private var engineProvider: SearchEngineProvider

    weak var delegate: SearchEngineDelegate?
    private var logger: Logger = DefaultLogger.shared

    init(prefs: Prefs, files: FileAccessor, engineProvider: SearchEngineProvider = DefaultSearchEngineProvider()) {
        self.prefs = prefs
        self.fileAccessor = files
        self.engineProvider = engineProvider
        self.orderedEngines = []
        self.disabledEngines = getDisabledEngines()
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
    private var disabledEngines: [String: Bool]! {
        didSet {
            self.prefs.setObject(Array(self.disabledEngines.keys), forKey: disabledEngineNames)
        }
    }

    var orderedEngines: [OpenSearchEngine]! {
        didSet {
            self.prefs.setObject(self.orderedEngines.map { $0.shortName }, forKey: orderedEngineNames)
        }
    }

    /// The subset of search engines that are enabled and not the default search engine.
    ///
    /// The results can be empty if the user disables all search engines besides the default (which can't be disabled).
    var quickSearchEngines: [OpenSearchEngine]! {
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
        return disabledEngines.index(forKey: engine.shortName) == nil
    }

    func enableEngine(_ engine: OpenSearchEngine) {
        disabledEngines.removeValue(forKey: engine.shortName)
    }

    func disableEngine(_ engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        disabledEngines[engine.shortName] = true
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
        if let disabledEngines = prefs.stringArrayForKey(disabledEngineNames) {
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
        engineProvider.getOrderedEngines(customEngines: customEngines,
                                         orderedEngineNames: prefs.stringArrayForKey(self.orderedEngineNames),
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
