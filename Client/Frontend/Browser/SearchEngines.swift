/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

let DefaultSearchEngineName = "Yahoo"

private let OrderedEngineNames = "search.orderedEngineNames"
private let DisabledEngineNames = "search.disabledEngineNames"

/**
 * Manage a set of Open Search engines.
 *
 * The search engines are ordered.  Individual search engines can be enabled and disabled.  The
 * first search engine is distinguished and labeled the "default" search engine; it can never be
 * disabled.  Search suggestions should always be sourced from the default search engine.
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
    let prefs: ProfilePrefs
    init(prefs: ProfilePrefs) {
        self.prefs = prefs
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
            var orderedEngines = self.orderedEngines.filter({ engine in engine.shortName != defaultEngine.shortName })
            orderedEngines.insert(defaultEngine, atIndex: 0)
            self.orderedEngines = orderedEngines
        }
    }

    func isEngineDefault(engine: OpenSearchEngine) -> Bool {
        return defaultEngine.shortName == engine.shortName
    }

    // The keys of this dictionary are used as a set.
    private var disabledEngineNames: [String: Bool]! {
        didSet {
            self.prefs.setObject(self.disabledEngineNames.keys.array, forKey: DisabledEngineNames)
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
        var error: NSError?
        let path = NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("Locales/en-US/searchplugins")

        if path == nil {
            println("Error: Could not find search engine directory")
            return []
        }

        let directory = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path!, error: &error)

        if error != nil {
            println("Could not fetch search engines")
            return []
        }

        var engines = [OpenSearchEngine]()
        let parser = OpenSearchParser(pluginMode: true)
        for file in directory! {
            let fullPath = path!.stringByAppendingPathComponent(file as String)
            let engine = parser.parse(fullPath)
            engines.append(engine!)
        }

        return engines.sorted({ e, _ in e.shortName == DefaultSearchEngineName })
    }

    // Get all known search engines, possibly as ordered by the user.
    private func getOrderedEngines() -> [OpenSearchEngine] {
        let unorderedEngines = SearchEngines.getUnorderedEngines()
        if let orderedEngineNames = prefs.stringArrayForKey(OrderedEngineNames) {
            var orderedEngines = [OpenSearchEngine]()
            for engineName in orderedEngineNames {
                for engine in unorderedEngines {
                    if engine.shortName == engineName {
                        orderedEngines.append(engine)
                    }
                }
            }
            return orderedEngines
        } else {
            // We haven't persisted the engine order, so return whatever order we got from disk.
            return unorderedEngines
        }
    }
}
