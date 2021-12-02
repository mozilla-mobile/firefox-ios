// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

/*
 This only makes sense if you look at the structure of List.json
*/
final class DefaultSearchPrefs {
    fileprivate let defaultSearchList: [String]
    fileprivate let locales: [String: Any]?
    fileprivate let regionOverrides: [String: Any]?
    fileprivate let globalDefaultEngine: String

    public init?(with filePath: URL) {
        guard let searchManifest = try? String(contentsOf: filePath) else {
            assertionFailure("Search list not found. Check bundle")
            return nil
        }
        guard let data = searchManifest.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
            assertionFailure("Could not serialised")
            return nil
        }

        // Split up the JSON into useful parts
        locales = json["locales"] as? [String : Any]
        regionOverrides = json["regionOverrides"] as? [String : Any]
        // These are the fallback defaults
        guard let defaultDict = json["default"] as? [String: Any],
              let searchList = defaultDict["visibleDefaultEngines"] as? [String],
              let engine = defaultDict["searchDefault"] as? String else {
                assertionFailure("Defaults are not set up correctly in List.json")
                return nil
        }
        defaultSearchList = searchList
        globalDefaultEngine = engine
    }

    /*
     Returns an array of the visibile engines. It overrides any of the returned engines from the regionOverrides list
     Each language in the locales list has a default list of engines and then a region override list.
     */
    public func visibleDefaultEngines(for possibleLocales: [String], and region: String) -> [String] {
        let engineList = possibleLocales
            .compactMap {
                locales?[$0] as? [String: Any]
            }
            .compactMap { localDict -> [String]? in
                let visibleDefaultEngines = "visibleDefaultEngines"
                
                if let inner = localDict[region] as? [String: Any],
                   let array = inner[visibleDefaultEngines] as? [String] {
                    return array
                } else {
                    let inner = localDict["default"] as? [String: Any]
                    let array = inner?[visibleDefaultEngines] as? [String]
                    return array
                }
            }
            .last

        // If the engineList is empty then go ahead and use the default
        var usersEngineList = engineList ?? defaultSearchList

        // Overrides for specific regions.
        if let overrides = regionOverrides?[region] as? [String: Any] {
            usersEngineList = usersEngineList.map({ overrides[$0] as? String ?? $0 })
        }
        return usersEngineList
    }

    /*
     Returns the default search given the possible locales and region
     The list.json locales list contains searchDefaults for a few locales.
     Create a list of these and return the last one. The globalDefault acts as the fallback in case the list is empty.
     */
    public func searchDefault(for possibleLocales: [String], and region: String) -> String {
        return possibleLocales
            .compactMap {
                locales?[$0] as? [String: Any]
            }
            .reduce(globalDefaultEngine) {
                (defaultEngine, localeJSON) -> String in
                let inner = localeJSON[region] as? [String: Any]
                return inner?["searchDefault"] as? String ?? defaultEngine
        }
    }
}
