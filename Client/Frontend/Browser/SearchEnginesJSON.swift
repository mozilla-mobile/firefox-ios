/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class SearchEnginesJSON {
    private let json: JSON

    public init(_ jsonString: String) {
        self.json = JSON.parse(jsonString)
    }

    public init(_ json: JSON) {
        self.json = json
    }

    public func visibleDefaultEngines(possibilities: [String], region: String) -> [String] {
        var engineNames: [JSON]? = nil
        for possibleLocale in possibilities {
            if let regions = json["locales"][possibleLocale].asDictionary {
                if regions[region] == nil {
                    engineNames = regions["default"]!["visibleDefaultEngines"].asArray
                    // We keep looping through just in case
                    // another possible locale gets us more specific
                } else {
                    engineNames = regions[region]!["visibleDefaultEngines"].asArray
                }
            }
        }
        if engineNames == nil {
            engineNames = json["default"]["visibleDefaultEngines"].asArray
        }
        return jsonsToStrings(engineNames)!
    }
}

extension SearchEnginesJSON {
    func asJSON() -> JSON {
        return self.json
    }
}
