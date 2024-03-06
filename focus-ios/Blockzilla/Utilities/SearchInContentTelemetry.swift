// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Glean

// Search Partner Codes
// https://docs.google.com/spreadsheets/d/1HMm9UXjfJv-uHhGU1pJlbP4ILkdpSD9w_Fd-3yOd8oY/
// Google partner codes for US and ROW (Rest of World)
enum SearchPartnerCode: String {
    case US = "firefox-b-1-m"
    case ROW = "firefox-b-m"
}

enum URLType: String {
    case regular
    case search
    case followOnSearch
    case organicSearch
}

class SearchInContentTelemetry {
    private var code = ""
    private var provider = ""
    private var urlType: URLType = .regular
    static var shouldSetUrlTypeSearch = false
    private let searchEngineManager = SearchEngineManager(prefs: UserDefaults.standard)

    // MARK: - URLBar SAP (Search Access Point)

    // sap: directly from search access point
    func trackSAP() {
        GleanMetrics.BrowserSearch.inContent["\(provider).in-content.sap.\(code)"].add()
    }

    // sap-follow-on: user continues to search from an existing sap search
    func trackSAPFollowOn() {
        GleanMetrics.BrowserSearch.inContent["\(provider).in-content.sap-follow-on.\(code)"].add()
    }

    // organic: search that didn't come from a SAP
    func trackOrganicSearch() {
        GleanMetrics.BrowserSearch.inContent["\(provider).organic.none"].add()
    }

    func isFollowOnSearch(clientValue: String?, code: String) -> Bool {
        if (urlType == .search || urlType == .followOnSearch)
            && clientValue == code { return true }
        return false
    }

    func isOrganicSearch(sClientValue: String?, provider: String) -> Bool {
        if provider == BasicSearchProvider.google.rawValue && sClientValue != nil { return true }
        return false
    }

    func getClientsValue(url: URL) -> (clientValue: String?, sClientValue: String?) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let clientValue = components.valueForQuery("client")
        let sClientValue = components.valueForQuery("sclient")
        return (clientValue, sClientValue)
    }

    func getCode(searchEngine: String, region: String) -> String {
        if searchEngine == BasicSearchProvider.google.rawValue {
            return region
        }
        return "none"
    }

    func setSearchType(webView: WKWebView) {
        provider = searchEngineManager.activeEngine.getNameOrCustom().lowercased()
        code = getCode(searchEngine: provider, region:
                        Locale.current.regionCode == "US" ?
                       SearchPartnerCode.US.rawValue :
                        SearchPartnerCode.ROW.rawValue)

        if SearchInContentTelemetry.shouldSetUrlTypeSearch {
            urlType = .search
            SearchInContentTelemetry.shouldSetUrlTypeSearch = false
            trackSAP()
        }
        else if let url = webView.url {
            let clients = getClientsValue(url: url)
            if isFollowOnSearch(clientValue: clients.clientValue, code: code) {
                urlType = .followOnSearch
                trackSAPFollowOn()
            }
            else if isOrganicSearch(sClientValue: clients.sClientValue, provider: provider) {
                urlType = .organicSearch
                trackOrganicSearch()
            }
            else { urlType = .regular }
        }
    }
}

// MARK: - Extensions
extension URLComponents {
    func valueForQuery(_ param: String) -> String? {
        queryItems?.first { $0.name == param }?.value
    }
}
