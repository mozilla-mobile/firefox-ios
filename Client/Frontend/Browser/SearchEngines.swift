/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let OrderedEngineNames = "search.orderedEngineNames"
private let DisabledEngineNames = "search.disabledEngineNames"
private let ShowSearchSuggestionsOptIn = "search.suggestions.showOptIn"
private let ShowSearchSuggestions = "search.suggestions.show"

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
    let prefs: Prefs
    init(prefs: Prefs) {
        self.prefs = prefs
        // By default, show search suggestions opt-in and don't show search suggestions automatically.
        self.shouldShowSearchSuggestionsOptIn = prefs.boolForKey(ShowSearchSuggestionsOptIn) ?? true
        self.shouldShowSearchSuggestions = prefs.boolForKey(ShowSearchSuggestions) ?? false
        self.disabledEngineNames = getDisabledEngineNames()
        self.orderedEngines = getOrderedEngines()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELdidResetPrompt:", name: "SearchEnginesPromptReset", object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    var defaultEngine: OpenSearchEngine {
        get {
            return self.orderedEngines[0]
        }

        set(defaultEngine) {
            // The default engine is always enabled.
            self.enableEngine(defaultEngine)
            // The default engine is always first in the list.
            var orderedEngines = self.orderedEngines.filter({ engine in engine.shortName != defaultEngine.shortName })
            orderedEngines.insert(defaultEngine, atIndex: 0)
            self.orderedEngines = orderedEngines
        }
    }

    @objc
    func SELdidResetPrompt(notification: NSNotification) {
        self.shouldShowSearchSuggestionsOptIn = true
        self.shouldShowSearchSuggestions = false
    }

    func isEngineDefault(engine: OpenSearchEngine) -> Bool {
        return defaultEngine.shortName == engine.shortName
    }

    // The keys of this dictionary are used as a set.
    private var disabledEngineNames: [String: Bool]! {
        didSet {
            self.prefs.setObject(Array(self.disabledEngineNames.keys), forKey: DisabledEngineNames)
        }
    }

    var orderedEngines: [OpenSearchEngine]! {
        didSet {
            self.prefs.setObject(self.orderedEngines.map({ (engine) in engine.shortName }), forKey: OrderedEngineNames)
        }
    }

    var quickSearchEngines: [OpenSearchEngine]! {
        get {
            return self.orderedEngines.filter({ (engine) in
                !self.isEngineDefault(engine) && self.isEngineEnabled(engine) })
        }
    }

    var shouldShowSearchSuggestionsOptIn: Bool {
        didSet {
            self.prefs.setObject(shouldShowSearchSuggestionsOptIn, forKey: ShowSearchSuggestionsOptIn)
        }
    }

    var shouldShowSearchSuggestions: Bool {
        didSet {
            self.prefs.setObject(shouldShowSearchSuggestions, forKey: ShowSearchSuggestions)
        }
    }

    func isEngineEnabled(engine: OpenSearchEngine) -> Bool {
        return disabledEngineNames.indexForKey(engine.shortName) == nil
    }

    func enableEngine(engine: OpenSearchEngine) {
        disabledEngineNames.removeValueForKey(engine.shortName)
    }

    func disableEngine(engine: OpenSearchEngine) {
        if isEngineDefault(engine) {
            // Can't disable default engine.
            return
        }
        disabledEngineNames[engine.shortName] = true
    }


    func queryForSearchURL(url: NSURL?) -> String? {
        for engine in orderedEngines {
            guard let searchTerm = engine.queryForSearchURL(url) else { continue }
            return searchTerm
        }

        return nil
    }

    private func getDisabledEngineNames() -> [String: Bool] {
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

    // Get all known search engines, with the default search engine first, but the others in no
    // particular order.
    class func getUnorderedEngines() -> [OpenSearchEngine] {
        let pluginBasePath: NSString = (NSBundle.mainBundle().resourcePath! as NSString).stringByAppendingPathComponent("SearchPlugins")
        let language = NSLocale.preferredLanguages().first!
        let fallbackDirectory: NSString = pluginBasePath.stringByAppendingPathComponent("en")

        // Look for search plugins in the following order:
        //   1) the full language ID
        //   2) the language ID without the dialect
        //   3) the fallback language (English)
        // For example, "fr-CA" would look for plugins in this order: 1) fr-CA, 2) fr, 3) en.
        var searchDirectory = pluginBasePath.stringByAppendingPathComponent(language)
        if !NSFileManager.defaultManager().fileExistsAtPath(searchDirectory) {
            let languageWithoutDialect = language.componentsSeparatedByString("-").first!
            searchDirectory = pluginBasePath.stringByAppendingPathComponent(languageWithoutDialect)
            if language == languageWithoutDialect || !NSFileManager.defaultManager().fileExistsAtPath(searchDirectory) {
                searchDirectory = fallbackDirectory as String
            }
        }

        let index = (searchDirectory as NSString).stringByAppendingPathComponent("list.txt")
        let listFile = try? String(contentsOfFile: index, encoding: NSUTF8StringEncoding)
        assert(listFile != nil, "Read the list of search engines")

        let engineNames = listFile!
            .stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

        var engines = [OpenSearchEngine]()
        let parser = OpenSearchParser(pluginMode: true)
        for engineName in engineNames {
            // Search the current localized search plugins directory for the search engine.
            // If it doesn't exist, fall back to English.
            var fullPath = (searchDirectory as NSString).stringByAppendingPathComponent("\(engineName).xml")
            if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                fullPath = fallbackDirectory.stringByAppendingPathComponent("\(engineName).xml")
            }
            assert(NSFileManager.defaultManager().fileExistsAtPath(fullPath), "\(fullPath) exists")

            let engine = parser.parse(fullPath)
            assert(engine != nil, "Engine at \(fullPath) successfully parsed")

            engines.append(engine!)
        }

        let defaultEngineFile = (searchDirectory as NSString).stringByAppendingPathComponent("default.txt")
        let defaultEngineName = try? String(contentsOfFile: defaultEngineFile, encoding: NSUTF8StringEncoding).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

        return engines.sort({ e, _ in e.shortName == defaultEngineName })
    }

    // Get all known search engines, possibly as ordered by the user.
    private func getOrderedEngines() -> [OpenSearchEngine] {
        let unorderedEngines = SearchEngines.getUnorderedEngines()
        if let orderedEngineNames = prefs.stringArrayForKey(OrderedEngineNames) {
            // We have a persisted order of engines, so try to use that order.
            // We may have found engines that weren't persisted in the ordered list
            // (if the user changed locales or added a new engine); these engines
            // will be appended to the end of the list.
            return unorderedEngines.sort { engine1, engine2 in
                let index1 = orderedEngineNames.indexOf(engine1.shortName)
                let index2 = orderedEngineNames.indexOf(engine2.shortName)

                if index1 == nil && index2 == nil {
                    return engine1.shortName < engine2.shortName
                }

                // nil < N for all non-nil values of N.
                if index1 == nil || index2 == nil {
                    return index1 > index2
                }

                return index1 < index2
            }
        } else {
            // We haven't persisted the engine order, so return whatever order we got from disk.
            return unorderedEngines
        }
    }
}
