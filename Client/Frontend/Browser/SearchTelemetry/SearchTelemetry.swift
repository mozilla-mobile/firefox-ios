/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices

// Search Partner Codes
// https://docs.google.com/spreadsheets/d/1HMm9UXjfJv-uHhGU1pJlbP4ILkdpSD9w_Fd-3yOd8oY/
struct SearchPartner {
    // Google partner code for US and ROW (rest of the world)
    private static let google = ["US": "firefox-b-1-m",
                                 "ROW": "firefox-b-m"]
    
    static func getCode(searchEngine: SearchEngine, region: String) -> String {
        switch(searchEngine) {
        case .google:
            return google[region] ?? ""
        case .none:
            return ""
        }
    }
}

// Our default search engines
enum SearchEngine: String, CaseIterable {
    case google
    case none
}

class SearchTelemetry {
    var code: String
    var provider: SearchEngine
    
    init(_ code: String, provider: SearchEngine) {
        self.code = code
        self.provider = provider
    }
    // sap: directly from search access point
    func trackSAP() {
        GleanMetrics.Search.inContent["\(provider).in-content.sap.\(code)"].add()
    }
    
    // sap-follow-on: user continues to search from an existing sap search
    func trackSAPFollowOn() {
        GleanMetrics.Search.inContent["\(provider).in-content.sap-follow-on.\(code)"].add()
    }
    
    // organic: search that didn't come from a SAP
    func trackOrganic() {
        GleanMetrics.Search.inContent["\(provider).organic.none"].add()
    }
}
