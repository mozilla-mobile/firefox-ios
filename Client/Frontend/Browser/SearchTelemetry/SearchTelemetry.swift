/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import WebKit

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
    var code: String = ""
    var provider: SearchEngine = .none
    var shouldSetGoogleTopSiteSearch = false
    var shouldSetUrlTypeSearch = false
    
    //MARK: Searchbar SAP
    
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
    
    //MARK: Google Top Site SAP
    
    //Note: This tracks google top site tile tap which opens a google search page
    func trackGoogleTopSiteTap() {
        GleanMetrics.Search.googleTopsitePressed["\(SearchEngine.google).\(code)"].add()
    }
    
    //Note: This tracks SAP follow-on search. Also, the first search that the user performs is considered
    //a follow-on where OQ query item in google url is present but has no data in it
    //Flow: User taps google top site tile -> google page opens -> user types item to search in the page
    func trackGoogleTopSiteFollowOn() {
        GleanMetrics.Search.inContent["\(SearchEngine.google).in-content.google-topsite-follow-on.\(code)"].add()
    }
    
    //MARK: Track Regular and Follow-on SAP from Tab and TopSite
    
    func trackTabAndTopSiteSAP(_ tab: Tab, webView: WKWebView) {
        let provider = tab.getProviderForUrl()
        let code = SearchPartner.getCode(searchEngine: provider, region: Locale.current.regionCode == "US" ? "US" : "ROW")
        self.code = code
        self.provider = provider
        
        if shouldSetGoogleTopSiteSearch {
            tab.urlType = .googleTopSite
            shouldSetGoogleTopSiteSearch = false
            self.trackGoogleTopSiteTap()
        } else if shouldSetUrlTypeSearch {
            tab.urlType = .search
            shouldSetUrlTypeSearch = false
            self.trackSAP()
        } else if let webUrl = webView.url {
            let components = URLComponents(url: webUrl, resolvingAgainstBaseURL: false)!
            let clientValue = components.valueForQuery("client")
            // Special case google followOn search
            if (tab.urlType == .googleTopSite || tab.urlType == .googleTopSiteFollowOn) && clientValue == code {
                tab.urlType = .googleTopSiteFollowOn
                self.trackGoogleTopSiteFollowOn()
            // Check if previous tab type is search
            } else if (tab.urlType == .search || tab.urlType == .followOnSearch) && clientValue == code {
                tab.urlType = .followOnSearch
                self.trackSAPFollowOn()
            } else if provider == .google {
                tab.urlType = .organicSearch
                self.trackOrganic()
            } else {
                tab.urlType = .regular
            }
        }
    }
}
