/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

open class SearchEnginesJSON {
    fileprivate let json: JSON

    public init(_ jsonString: String) {
        self.json = JSON(parseJSON: jsonString)
    }

    public init(_ json: JSON) {
        self.json = json
    }

    open func visibleDefaultEngines(possibilities: [String], region: String) -> [String] {
        var engineNames: [JSON]? = nil
        for possibleLocale in possibilities {
            if let regions = json["locales"][possibleLocale].dictionary {
                if regions[region] == nil || regions[region]!["visibleDefaultEngines"] == JSON.null {
                    engineNames = regions["default"]!["visibleDefaultEngines"].array
                } else {
                    engineNames = regions[region]!["visibleDefaultEngines"].array
                }
                break;
            }
        }
        if engineNames == nil {
            engineNames = json["default"]["visibleDefaultEngines"].array
        }
        var engineNamesArray = jsonsToStrings(engineNames)!
        let regionOverrides = json["regionOverrides"].dictionary
        if regionOverrides![region] != nil {
            for (index, engineName) in engineNamesArray.enumerated() {
                if regionOverrides![region]![engineName] != JSON.null {
                    engineNamesArray[index] = regionOverrides![region]![engineName].string!
                }
            }
            
        }
        return engineNamesArray
    }

    open func searchDefault(possibilities: [String], region: String) -> String {
        var searchDefault: String? = nil
        for possibleLocale in possibilities {
            if let regions = json["locales"][possibleLocale].dictionary {
                if regions[region] == nil {
                    searchDefault = regions["default"]!["searchDefault"].string
                } else {
                    searchDefault = regions[region]!["searchDefault"].string
                }
                break;
            }
        }
        if searchDefault == nil {
            searchDefault = json["default"]["searchDefault"].string
        }
        return searchDefault!
    }    
}

extension SearchEnginesJSON {
    func asJSON() -> JSON {
        return self.json
    }
}
