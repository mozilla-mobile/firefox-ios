/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Search Partner Codes
// https://docs.google.com/spreadsheets/d/1HMm9UXjfJv-uHhGU1pJlbP4ILkdpSD9w_Fd-3yOd8oY/
struct SearchPartner {
    // Google partner code for US and ROW (rest of the world)
    private static let google = ["US":"firefox-b-1-m",
                                 "ROW":"firefox-b-m"]
    
    static func getCode(searchEngine: SearchEngine, region: String) -> String {
        return google[region] ?? ""
    }
}

// Our default search engines
enum SearchEngine {
    case Google
}

class SearchTelemetry {
    let countryCode = Locale.current.regionCode
    
    // sap: directly from search access point (Url Bar)
    func trackSAP() {
        
    }
    
    // sap-follow-on: user continues to search from an existing search
    func trackSapFollowOn() {
    
    }
    
    // organic: search that didn't come from a SAP
    func trackOrganic() {
        
    }
}
