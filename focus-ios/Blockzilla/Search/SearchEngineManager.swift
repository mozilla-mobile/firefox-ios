/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngineManager {
    public static let prefKeyEngine = "prefKeyEngine"
    public static let prefKeyDisabledEngines = "prefKeyDisabledEngines"
    public static let prefKeyCustomEngines = "prefKeyCustomEngines"
    public static let prefKeyV98AndAboveResetSearchEngine = "prefKeyAboveV98ResetSearchEngine" // Ref Bug: #1653822

    private let prefs: UserDefaults
    var engines = [SearchEngine]()

    init(prefs: UserDefaults) {
        self.prefs = prefs

        loadEngines()
    }

    var activeEngine: SearchEngine {
        get {
            let selectName = prefs.string(forKey: SearchEngineManager.prefKeyEngine)
            return engines.first { $0.name == selectName } ?? engines.first!
        }

        set {
            prefs.set(newValue.name, forKey: SearchEngineManager.prefKeyEngine)
            sortEnginesAlphabetically()
            setActiveEngineAsFirstElement()
        }
    }

    func addEngine(name: String, template: String) -> SearchEngine {
        let correctedTemplate = template.replacingOccurrences(of: "%s", with: "{searchTerms}")
        let engine = SearchEngine(name: name, image: nil, searchTemplate: correctedTemplate, suggestionsTemplate: nil, isCustom: true)

        // Persist
        var customEngines = readCustomEngines()
        customEngines.append(engine)
        saveCustomEngines(customEngines: customEngines)

        // Update inmemory list
        engines.append(engine)
        sortEnginesAlphabetically()

        // Set as default search engine
        activeEngine = engine
        return engine
    }

    func hasDisabledDefaultEngine() -> Bool {
        return !getDisabledDefaultEngineNames().isEmpty
    }

    func restoreDisabledDefaultEngines() {
        prefs.removeObject(forKey: SearchEngineManager.prefKeyDisabledEngines)
        loadEngines()
    }

    func removeEngine(engine: SearchEngine) {
        // If this is a custom engine then it should be removed from the custom engine array
        // otherwise this is a default engine and so it should be added to the disabled engines array

        if activeEngine.name == engine.name {
            // Can not remove active engine
            return
        }

        let customEngines = readCustomEngines()
        let filteredEngines = customEngines.filter { (a: SearchEngine) -> Bool in
            return a.name != engine.name
        }

        if customEngines.count != filteredEngines.count {
            saveCustomEngines(customEngines: filteredEngines)
        } else {
            var disabledEngines = getDisabledDefaultEngineNames()
            disabledEngines.append(engine.name)
            saveDisabledDefaultEngineNames(engines: disabledEngines)
        }

        loadEngines()
    }

    func isValidSearchEngineName(_ name: String) -> Bool {
        if name.isEmpty {
            return false
        }

        var names = engines.map { (engine) -> String in
            return engine.name
        }

        names = names + getDisabledDefaultEngineNames()

        return !names.contains(where: { (n) -> Bool in
            return n == name
        })
    }

    private func loadEngines() {
        // Get the directories to look for engines, from most to least specific.
        var components = Locale.preferredLanguages.first!.components(separatedBy: "-")
        if components.count == 3 {
            components.remove(at: 1)
        }
        let searchPaths = [components.joined(separator: "-"), components[0], "default"]

        let parser = OpenSearchParser(pluginMode: true)
        let pluginsPath = Bundle.main.url(forResource: "SearchPlugins", withExtension: nil)!
        let enginesPath = Bundle.main.path(forResource: "SearchEngines", ofType: "plist")!
        let engineMap = NSDictionary(contentsOfFile: enginesPath) as! [String: [String]]
        let engines = searchPaths.compactMap { engineMap[$0] }.first!

        // Find and parse the engines for this locale.
        self.engines = engines.compactMap { name in
            let path = searchPaths
                .map({ pluginsPath.appendingPathComponent($0).appendingPathComponent(name + ".xml") })
                .first { FileManager.default.fileExists(atPath: $0.path) }!
            return parser.parse(file: path)
        }

        // Filter out disabled engines
        let disabledEngines = getDisabledDefaultEngineNames()
        self.engines = self.engines.filter { engine in
            return !disabledEngines.contains(engine.name)
        }

        // Add in custom engines
        let customEngines = readCustomEngines()
        self.engines.append(contentsOf: customEngines)

        let searchEnginePrefV98 = prefs.string(forKey: SearchEngineManager.prefKeyV98AndAboveResetSearchEngine)
        let hasDefaultSearchEngine = prefs.string(forKey: SearchEngineManager.prefKeyEngine)
        let versionNumberList = AppInfo.shortVersion.components(separatedBy: ".")
        let versionNum = Int(versionNumberList[0]) ?? 0

        // Ref Bug: #1653822
        // Set default search engine pref
        if hasDefaultSearchEngine == nil || (searchEnginePrefV98 == nil && versionNum >= 98) {
            prefs.set(self.engines.first?.name, forKey: SearchEngineManager.prefKeyEngine)
            prefs.set(true, forKey: SearchEngineManager.prefKeyV98AndAboveResetSearchEngine)
        }

        sortEnginesAlphabetically()
        setActiveEngineAsFirstElement()
    }

    private func sortEnginesAlphabetically() {
        engines.sort { (aEngine, bEngine) -> Bool in
            return aEngine.name < bEngine.name
        }
    }

    private func setActiveEngineAsFirstElement() {
        let activeEngineIndex = engines.firstIndex(of: activeEngine)!
        engines.insert(activeEngine, at: 0)
        engines.remove(at: activeEngineIndex.advanced(by: 1))
    }

    private func readCustomEngines() -> [SearchEngine] {
        do {
            if let archiveData = prefs.value(forKey: SearchEngineManager.prefKeyCustomEngines) as? NSData {
                let archivedCustomEngines = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archiveData as Data)
                let customEngines = archivedCustomEngines as? [SearchEngine] ?? [SearchEngine]()
                return customEngines.map { engine in
                    engine.isCustom = true
                    return engine
                }
            }
        } catch {
            print(error)
        }
        return [SearchEngine]()
    }

    private func saveCustomEngines(customEngines: [SearchEngine]) {
        do {
            try prefs.set(NSKeyedArchiver.archivedData(withRootObject: customEngines, requiringSecureCoding: false), forKey: SearchEngineManager.prefKeyCustomEngines)
        } catch {
            print(error)
        }
    }

    private func getDisabledDefaultEngineNames() -> [String] {
        return prefs.stringArray(forKey: SearchEngineManager.prefKeyDisabledEngines) ?? [String]()
    }

    private func saveDisabledDefaultEngineNames(engines: [String]) {
        prefs.set(engines, forKey: SearchEngineManager.prefKeyDisabledEngines)
    }

    func queryForSearchURL(_ url: URL) -> String? {
        for engine in engines {
            guard let searchTerm = engine.queryForSearchURL(url) else { continue }
            return searchTerm
        }
        return nil
    }
}
