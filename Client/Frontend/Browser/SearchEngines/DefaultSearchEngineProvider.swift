// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol SearchEngineProvider {
    func getUnorderedBundledEnginesFor(locale: Locale,
                                       possibleLanguageIdentifier: [String],
                                       completion: @escaping ([OpenSearchEngine]) -> Void)
}

class DefaultSearchEngineProvider: SearchEngineProvider {
    func getUnorderedBundledEnginesFor(locale: Locale,
                                       possibleLanguageIdentifier: [String],
                                       completion: @escaping ([OpenSearchEngine]) -> Void ) {
        let region = locale.regionCode ?? "US"
        let parser = OpenSearchParser(pluginMode: true)

        guard let pluginDirectory = Bundle.main.resourceURL?.appendingPathComponent("SearchPlugins") else {
            assertionFailure("Search plugins not found. Check bundle")
            completion([])
            return
        }

        guard let defaultSearchPrefs = DefaultSearchPrefs(with: pluginDirectory.appendingPathComponent("list.json")) else {
            assertionFailure("Failed to parse List.json")
            completion([])
            return
        }
        let possibilities = possibleLanguageIdentifier
        let engineNames = defaultSearchPrefs.visibleDefaultEngines(for: possibilities, and: region)
        let defaultEngineName = defaultSearchPrefs.searchDefault(for: possibilities, and: region)
        assert(!engineNames.isEmpty, "No search engines")

        DispatchQueue.global().async {
            let result = engineNames.map({ (name: $0, path: pluginDirectory.appendingPathComponent("\($0).xml").path) })
                .filter({
                    FileManager.default.fileExists(atPath: $0.path)
                }).compactMap({
                    parser.parse($0.path, engineID: $0.name)
                }).sorted { e, _ in
                    e.shortName == defaultEngineName
                }

            completion(result)
        }
    }
}
