/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.browserLogger

private let OrderedEngineNames = "search.orderedEngineNames"
private let DisabledEngineNames = "search.disabledEngineNames"
private let ShowSearchSuggestionsOptIn = "search.suggestions.showOptIn"
private let ShowSearchSuggestions = "search.suggestions.show"
private let customSearchEnginesFileName = "customEngines.plist"

/**
 * Manage a set of Open Search engines.
 *
 * The search engines are ordered.  Individual search engines can be enabled and disabled.  The
 * first search engine is distinguished and labeled the "default" search engine; it can never be
 * disabled.  Search suggestions should always be sourced from the default search engine.
 *
 * Two additional bits of information are maintained: whether the user should be shown "opt-in to
 * search suggestions" UI, and whether search suggestions are enabled.
 *
 * Consumers will almost always use `defaultEngine` if they want a single search engine, and
 * `quickSearchEngines()` if they want a list of enabled quick search engines (possibly empty,
 * since the default engine is never included in the list of enabled quick search engines, and
 * it is possible to disable every non-default quick search engine).
 *
 * The search engines are backed by a write-through cache into a ProfilePrefs instance.  This class
 * is not thread-safe -- you should only access it on a single thread (usually, the main thread)!
 */
class SearchEngines {
    fileprivate let prefs: Prefs
    fileprivate let fileAccessor: FileAccessor

    init(prefs: Prefs, files: FileAccessor) {
        self.prefs = prefs
        // By default, show search suggestions
        self.shouldShowSearchSuggestions = prefs.boolForKey(ShowSearchSuggestions) ?? true
        self.fileAccessor = files
        self.disabledEngineNames = getDisabledEngineNames()
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
    fileprivate var disabledEngineNames: [String: Bool]! {
        didSet {
            self.prefs.setObject(Array(self.disabledEngineNames.keys), forKey: DisabledEngineNames)
        }
    }

    var orderedEngines: [OpenSearchEngine]! {
        didSet {
            self.prefs.setObject(self.orderedEngines.map { $0.shortName }, forKey: OrderedEngineNames)
        }
    }

    var quickSearchEngines: [OpenSearchEngine]! {
        get {
            return self.orderedEngines.filter({ (engine) in !self.isEngineDefault(engine) && self.isEngineEnabled(engine) })
        }
    }

    var shouldShowSearchSuggestions: Bool {
        didSet {
            self.prefs.setObject(shouldShowSearchSuggestions, forKey: ShowSearchSuggestions)
        }
    }

    func isEngineEnabled(_ engine: OpenSearchEngine) -> Bool {
        return disabledEngineNames.index(forKey: engine.shortName) == nil
    }

    func enableEngine(_ engine: OpenSearchEngine) {
        disabledEngineNames.removeValue(forKey: engine.shortName)
    }

    func disableEngine(_ engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        disabledEngineNames[engine.shortName] = true
    }

    func deleteCustomEngine(_ engine: OpenSearchEngine) {
        // We can't delete a preinstalled engine or an engine that is currently the default.
        if !engine.isCustomEngine || isEngineDefault(engine) {
            return
        }

        customEngines.remove(at: customEngines.index(of: engine)!)
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

    fileprivate func getDisabledEngineNames() -> [String: Bool] {
        if let disabledEngineNames = self.prefs.stringArrayForKey(DisabledEngineNames) {
            var disabledEngineDict = [String: Bool]()
            for engineName in disabledEngineNames {
                disabledEngineDict[engineName] = true
            }
            return disabledEngineDict
        } else {
            return [String: Bool]()
        }
    }

    fileprivate func customEngineFilePath() -> String {
        let profilePath = try! self.fileAccessor.getAndEnsureDirectory() as NSString
        return profilePath.appendingPathComponent(customSearchEnginesFileName)
    }

    fileprivate lazy var customEngines: [OpenSearchEngine] = {
        return NSKeyedUnarchiver.unarchiveObject(withFile: self.customEngineFilePath()) as? [OpenSearchEngine] ?? []
    }()

    fileprivate func saveCustomEngines() {
        NSKeyedArchiver.archiveRootObject(customEngines, toFile: self.customEngineFilePath())
    }

    /// Return all possible language identifiers in the order of most specific to least specific.
    /// For example, zh-Hans-CN will return [zh-Hans-CN, zh-CN, zh].
    class func possibilitiesForLanguageIdentifier(_ languageIdentifier: String) -> [String] {
        var possibilities = [String]()
         let components = languageIdentifier.components(separatedBy: "-")
         if components.count == 1 {
             // zh
            possibilities.append(languageIdentifier)
         } else if components.count == 2 {
             // zh-CN
            possibilities.append(languageIdentifier)
            possibilities.append(components[0])
         } else if components.count == 3 {
            possibilities.append(languageIdentifier)
            possibilities.append(components[0] + "-" + components[2])
            possibilities.append(components[0])
         }
        return possibilities;
    }

    /// Return all possible paths for a language identifier in the order of most specific to least specific.
    /// For example, zh-Hans-CN with a default of en will return [zh-Hans-CN, zh-CN, zh, en]. The fallback
    /// identifier must be a known one that is guaranteed to exist in the SearchPlugins directory.
    class func directoriesForLanguageIdentifier(_ languageIdentifier: String, basePath: NSString, fallbackIdentifier: String) -> [String] {
        var directories = possibilitiesForLanguageIdentifier(languageIdentifier)
        let components = languageIdentifier.components(separatedBy: "-")
        if components.count == 1 {
            // zh
            directories.append(languageIdentifier)
        } else if components.count == 2 {
            // zh-CN
            directories.append(languageIdentifier)
            directories.append(components[0])
        } else if components.count == 3 {
            directories.append(languageIdentifier)
            directories.append(components[0] + "-" + components[2])
            directories.append(components[0])
        }
        if !directories.contains(fallbackIdentifier) {
            directories.append(fallbackIdentifier)
        }
        
        return directories.map { (path) -> String in
            return basePath.appendingPathComponent(path)
        }
    }

    // Return the language identifier to be used for the search engine selection. This returns the first
    // identifier from preferredLanguages and takes into account that on iOS 8, zh-Hans-CN is returned as
    // zh-Hans. In that case it returns the longer form zh-Hans-CN. Same for traditional Chinese.
    //
    // These exceptions can go away when we drop iOS 8 or when we start using a better mechanism for search
    // engine selection that is not based on language identifier.
    class func languageIdentifierForSearchEngines() -> String {
        let languageIdentifier = Locale.preferredLanguages.first!
        switch languageIdentifier {
            case "zh-Hans":
                return "zh-Hans-CN"
            case "zh-Hant":
                return "zh-Hant-TW"
            default:
                return languageIdentifier
        }
    }

    // Return the region identifier to be used for the search engine selection.
    class func regionIdentifierForSearchEngines(_ languageIdentifier: String) -> String {
        let components = languageIdentifier.components(separatedBy: "-")
        if components.count == 2 {
            return components[1]
        } else if components.count == 3 {
            return components[2]
        }
        // This shouldn't happen
        return languageIdentifier
    }

    /// Get all bundled (not custom) search engines, with the default search engine first,
    /// but the others in no particular order.
    class func getUnorderedBundledEngines() -> [OpenSearchEngine] {
        let pluginBasePath: NSString = (Bundle.main.resourcePath! as NSString).appendingPathComponent("SearchPlugins") as NSString
        let languageIdentifier = languageIdentifierForSearchEngines()

        let index = (pluginBasePath as NSString).appendingPathComponent("list.json")
        let listFile = try! String(contentsOfFile: index, encoding: String.Encoding.utf8)
        let engineJSON = SearchEnginesJSON(listFile)

        let possibilities = possibilitiesForLanguageIdentifier(languageIdentifier)
        let region = regionIdentifierForSearchEngines(languageIdentifier)
        let engineNames = engineJSON.visibleDefaultEngines(possibilities: possibilities, region: region)
        let searchDefault = engineJSON.searchDefault(possibilities: possibilities, region: region)

        assert(engineNames.count > 0, "No search engines")

        var engines = [OpenSearchEngine]()
        let parser = OpenSearchParser(pluginMode: true)
         for engineName in engineNames {
             // Search the current localized search plugins directory for the search engine.
             // If it doesn't exist, fall back to English.
            let fullPath = (pluginBasePath as NSString).appendingPathComponent("\(engineName).xml")
            // If a search engine doesn't exist, just ignore it. We might have entries in
            // list.json where the files don't exist yet.
            if (!FileManager.default.fileExists(atPath: fullPath)) {
                continue
             }

            guard let engine = parser.parse(fullPath, engineID: engineName) else {
                log.error("Failed to parse search engine ID \(engineName) at \(fullPath)")
                continue
            }
            engines.append(engine)
        }

        let defaultEngineName = searchDefault;

        return engines.sorted { e, _ in e.shortName == defaultEngineName }
    }

    /// Get all known search engines, possibly as ordered by the user.
    fileprivate func getOrderedEngines() -> [OpenSearchEngine] {
        let unorderedEngines = customEngines + SearchEngines.getUnorderedBundledEngines()

        guard let orderedEngineNames = prefs.stringArrayForKey(OrderedEngineNames) else {
            // We haven't persisted the engine order, so return whatever order we got from disk.
            return unorderedEngines
        }

        // We have a persisted order of engines, so try to use that order.
        // We may have found engines that weren't persisted in the ordered list
        // (if the user changed locales or added a new engine); these engines
        // will be appended to the end of the list.
        return unorderedEngines.sorted { engine1, engine2 in
            let index1 = orderedEngineNames.index(of: engine1.shortName)
            let index2 = orderedEngineNames.index(of: engine2.shortName)

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
}
