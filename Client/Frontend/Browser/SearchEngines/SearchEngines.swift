// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

/// Manage a set of Open Search engines.
///
/// The search engines are ordered.
///
/// Individual search engines can be enabled and disabled.
///
/// The first search engine is distinguished and labeled the "default" search engine; it can never be
/// disabled.  Search suggestions should always be sourced from the default search engine.
/// 
/// Two additional bits of information are maintained: whether the user should be shown "opt-in to
/// search suggestions" UI, and whether search suggestions are enabled.
///
/// Consumers will almost always use `defaultEngine` if they want a single search engine, and
/// `quickSearchEngines()` if they want a list of enabled quick search engines (possibly empty,
/// since the default engine is never included in the list of enabled quick search engines, and
/// it is possible to disable every non-default quick search engine).
///
/// The search engines are backed by a write-through cache into a ProfilePrefs instance.  This class
/// is not thread-safe -- you should only access it on a single thread (usually, the main thread)!
class SearchEngines {
    private let prefs: Prefs
    private let fileAccessor: FileAccessor
    private let orderedEngineNames = "search.orderedEngineNames"
    private let disabledEngineNames = "search.disabledEngineNames"
    private let showSearchSuggestionsOptIn = "search.suggestions.showOptIn"
    private let showSearchSuggestions = "search.suggestions.show"
    private let customSearchEnginesFileName = "customEngines.plist"

    init(prefs: Prefs, files: FileAccessor) {
        self.prefs = prefs
        // By default, show search suggestions
        self.shouldShowSearchSuggestions = prefs.boolForKey(showSearchSuggestions) ?? true
        self.fileAccessor = files
        self.disabledEngines = getDisabledEngines()
        self.orderedEngines = getOrderedEngines()
    }

    var defaultEngine: OpenSearchEngine {
        get {
            return self.orderedEngines[0]
        }

        set(defaultEngine) {
            // The default engine is always enabled.
            self.enableEngine(defaultEngine)
            // The default engine is always first in the list.
            var orderedEngines = self.orderedEngines.filter { engine in engine.shortName != defaultEngine.shortName }
            orderedEngines.insert(defaultEngine, at: 0)
            self.orderedEngines = orderedEngines
        }
    }

    func isEngineDefault(_ engine: OpenSearchEngine) -> Bool {
        return defaultEngine.shortName == engine.shortName
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

    var quickSearchEngines: [OpenSearchEngine]! {
        return self.orderedEngines.filter({ (engine) in !self.isEngineDefault(engine) && self.isEngineEnabled(engine) })
    }

    var shouldShowSearchSuggestions: Bool {
        didSet {
            self.prefs.setObject(shouldShowSearchSuggestions, forKey: showSearchSuggestions)
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

    func deleteCustomEngine(_ engine: OpenSearchEngine) {
        // We can't delete a preinstalled engine or an engine that is currently the default.
        if !engine.isCustomEngine || isEngineDefault(engine) {
            return
        }

        customEngines.remove(at: customEngines.firstIndex(of: engine)!)
        saveCustomEngines()
        orderedEngines = getOrderedEngines()
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

    private var customEngineFilePath: String {
        let profilePath = try! self.fileAccessor.getAndEnsureDirectory() as NSString
        return profilePath.appendingPathComponent(customSearchEnginesFileName)
    }

    private lazy var customEngines: [OpenSearchEngine] = {
        return NSKeyedUnarchiver.unarchiveObject(withFile: customEngineFilePath) as? [OpenSearchEngine] ?? []
    }()

    private func saveCustomEngines() {
        NSKeyedArchiver.archiveRootObject(customEngines, toFile: customEngineFilePath)
    }

    /// Get all known search engines, possibly as ordered by the user.
    private func getOrderedEngines() -> [OpenSearchEngine] {
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        let unorderedEngines = customEngines + getUnorderedBundledEnginesFor(locale: locale)

        // might not work to change the default.
        guard let orderedEngineNames = prefs.stringArrayForKey(orderedEngineNames) else {
            // We haven't persisted the engine order, so return whatever order we got from disk.
            return unorderedEngines
        }

        // We have a persisted order of engines, so try to use that order.
        // We may have found engines that weren't persisted in the ordered list
        // (if the user changed locales or added a new engine); these engines
        // will be appended to the end of the list.
        return unorderedEngines.sorted { engine1, engine2 in
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
    }

    /// Get all bundled (not custom) search engines, with the default search engine first,
    /// but the others in no particular order.
    func getUnorderedBundledEnginesFor(locale: Locale) -> [OpenSearchEngine] {
        let languageIdentifier = locale.identifier
        let region = locale.regionCode ?? "US"
        let parser = OpenSearchParser(pluginMode: true)

        guard let pluginDirectory = Bundle.main.resourceURL?.appendingPathComponent("SearchPlugins") else {
            assertionFailure("Search plugins not found. Check bundle")
            return []
        }

        guard let defaultSearchPrefs = DefaultSearchPrefs(with: pluginDirectory.appendingPathComponent("list.json")) else {
            assertionFailure("Failed to parse List.json")
            return []
        }
        let possibilities = possibilitiesForLanguageIdentifier(languageIdentifier)
        let engineNames = defaultSearchPrefs.visibleDefaultEngines(for: possibilities, and: region)
        let defaultEngineName = defaultSearchPrefs.searchDefault(for: possibilities, and: region)
        assert(!engineNames.isEmpty, "No search engines")

        return engineNames.map({ (name: $0, path: pluginDirectory.appendingPathComponent("\($0).xml").path) })
            .filter({
                FileManager.default.fileExists(atPath: $0.path)
            }).compactMap({
                parser.parse($0.path, engineID: $0.name)
            }).sorted { e, _ in
                e.shortName == defaultEngineName
            }
    }

    /// Return all possible language identifiers in the order of most specific to least specific.
    /// For example, zh-Hans-CN will return [zh-Hans-CN, zh-CN, zh].
    private func possibilitiesForLanguageIdentifier(_ languageIdentifier: String) -> [String] {
        var possibilities: [String] = []
        let components = languageIdentifier.components(separatedBy: "-")
        possibilities.append(languageIdentifier)

        if components.count == 3, let first = components.first, let last = components.last {
            possibilities.append("\(first)-\(last)")
        }
        if components.count >= 2, let first = components.first {
            possibilities.append("\(first)")
        }
        return possibilities
    }
}
