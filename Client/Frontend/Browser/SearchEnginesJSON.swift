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

    public func visibleDefaultEngines(region: String) -> [String] {
        let engineNames = json[region]["visibleDefaultEngines"].asArray;
        if (engineNames == nil) {
            return []
        } else {
            return jsonsToStrings(engineNames)!
        }
    }
}

extension SearchEnginesJSON {
    func asJSON() -> JSON {
        return self.json
    }
}
