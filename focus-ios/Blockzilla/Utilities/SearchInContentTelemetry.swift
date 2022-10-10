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

// Our default search engines
enum DefaultSearchEngine: String, CaseIterable {
    case google
    case none

    static func getProviderForUrl(webView: WKWebView) -> DefaultSearchEngine {
        guard let url = webView.url else { return .none }
        for provider in DefaultSearchEngine.allCases {
            if url.baseDomain!.contains(provider.rawValue) { return provider }
        }
        return .none
    }

    static func getCode(searchEngine: DefaultSearchEngine, region: String) -> String {
        switch searchEngine {
        case .google:
            return region
        case .none:
            return DefaultSearchEngine.none.rawValue
        }
    }
}

class SearchInContentTelemetry {
    private var code = ""
    private var provider: DefaultSearchEngine = .none
    private var urlType: URLType = .regular
    static var shouldSetUrlTypeSearch = false

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

    func isOrganicSearch(sClientValue: String?, provider: DefaultSearchEngine) -> Bool {
        if provider == .google && sClientValue != nil { return true }
        return false
    }

    func getClientsValue(url: URL) -> (clientValue: String?, sClientValue: String?) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let clientValue = components.valueForQuery("client")
        let sClientValue = components.valueForQuery("sclient")
        return (clientValue, sClientValue)
    }

    func setSearchType(webView: WKWebView) {
        let provider = DefaultSearchEngine.getProviderForUrl(webView: webView)
        let code = DefaultSearchEngine.getCode(searchEngine: provider, region:
                                                Locale.current.regionCode == "US" ?
                                               SearchPartnerCode.US.rawValue :
                                                SearchPartnerCode.ROW.rawValue)
        self.code = code
        self.provider = provider

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
