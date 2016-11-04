/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SearchEngine {
    private lazy var template: String = {
        let enginesPath = Bundle.main.path(forResource: "SearchEngines", ofType: "plist")!
        let engines = NSDictionary(contentsOfFile: enginesPath) as! [String: String]

        var components = Locale.preferredLanguages.first!.components(separatedBy: "-")
        if components.count == 3 {
            components.remove(at: 1)
        }

        return engines[components.joined(separator: "-")] ?? engines[components[0]] ?? engines["default"]!
    }()

    func urlForQuery(_ query: String) -> URL? {
        guard let escaped = query.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let url = URL(string: template.replacingOccurrences(of: "{searchTerms}", with: escaped)) else {
            assertionFailure("Invalid search URL")
            return nil
        }

        return url
    }
}
