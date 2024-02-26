// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Glean
import Storage

// Search Partner Codes
// https://docs.google.com/spreadsheets/d/1HMm9UXjfJv-uHhGU1pJlbP4ILkdpSD9w_Fd-3yOd8oY/
struct SearchPartner {
    // Google partner code for US and ROW (rest of the world)
    private static let google = ["US": "firefox-b-1-m",
                                 "ROW": "firefox-b-m"]

    static func getCode(searchEngine: SearchEngine, region: String) -> String {
        switch searchEngine {
        case .google:
            return google[region] ?? "none"
        case .none:
            return "none"
        }
    }
}

// Our default search engines
enum SearchEngine: String, CaseIterable {
    case google
    case none
}

// all the values explained: https://mozilla-hub.atlassian.net/browse/FXIOS-8109
enum SearchTelemetryValues {
    enum Sap: String {
        case urlbar
        case urlbarNewtab = "urlbar_newtab"
    }

    enum SearchMode: String {
        case actions
        case bookmarks
        case history
        case tabs // the only one that's valid for iOS at the moment
        case unknown
        case inactive = "" // Empty string for inactive search mode
    }

    enum Reason: String {
        case pause
    }

    enum Interaction: String {
        case typed
        case pasted
        case returned
        case restarted
        case refined
        case persistedSearchTerms = "persisted_search_terms"
        case persistedSearchTermsRestarted = "persisted_search_terms_restarted"
        case persistedSearchTermsRefined = "persisted_search_terms_refined"
    }

    enum Provider: String {
        case iOS_app
    }

    enum EngagementType: String {
        case tap
        case enter
        case dropGo = "drop_go"
        case pasteGo = "paste_go"
        case dismiss
        case help
    }

    enum Groups: String {
        case heuristic
        case adaptiveHistory = "adaptive_history"
        case searchHistory = "search_history"
        case searchSuggest = "search_suggest"
        case topPick = "top_pick"
        case topSite = "top_site"
        case remoteTab = "remote_tab"
        case general
        case suggest
    }

    enum Results: String {
        case unknown
        case bookmark
        case history
        case keyword
        case searchEngine = "search_engine"
        case searchSuggest = "search_suggest"
        case searchHistory = "search_history"
        case url
        case action
        case tab
        case remoteTab = "remote_tab"
        case tabToSearch = "tab_to_search"
        case topSite = "top_site"
        case suggestSponsor = "suggest_sponsor"
        case suggestNonSponsor = "suggest_non_sponsor"
    }

    enum SelectedResult: String {
        case unknown
        case bookmark
        case history
        case keyword
        case searchEngine = "search_engine"
        case searchSuggest = "search_suggest"
        case searchHistory = "search_history"
        case url
        case action
        case tab
        case remoteTab = "remote_tab"
        case tabToSearch = "tab_to_search"
        case topSite = "top_site"
        case suggestSponsor = "suggest_sponsor"
        case suggestNonSponsor = "suggest_non_sponsor"
    }
}

class SearchTelemetry {
    var code: String = ""
    var provider: SearchEngine = .none
    var shouldSetGoogleTopSiteSearch = false
    var shouldSetUrlTypeSearch = false
    private var tabManager: TabManager

    var interactionType: SearchTelemetryValues.Interaction = .typed
    var selectedResult: SearchTelemetryValues.SelectedResult = .unknown
    var engagementType: SearchTelemetryValues.EngagementType = .tap
    var impressionTelemetryTimer: Timer?

    var remoteClientTabs = [ClientTabsSearchWrapper]()
    var filteredOpenedTabs = [Tab]()
    var filteredRemoteClientTabs = [ClientTabsSearchWrapper]()
    var suggestions: [String]? = []
    var firefoxSuggestions = [RustFirefoxSuggestion]()
    var searchHighlights = [HighlightItem]()

    var data: Cursor<Site> = Cursor<Site>(status: .success, msg: "No data set")
    var searchQuery: String = ""
    var savedQuery: String = ""

    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    // MARK: Searchbar SAP

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

    // MARK: Google Top Site SAP

    // Note: This tracks google top site tile tap which opens a google search page
    func trackGoogleTopSiteTap() {
        GleanMetrics.Search.googleTopsitePressed["\(SearchEngine.google).\(code)"].add()
    }

    // Note: This tracks SAP follow-on search. Also, the first search that the user performs is considered
    // a follow-on where OQ query item in google url is present but has no data in it
    // Flow: User taps google top site tile -> google page opens -> user types item to search in the page
    func trackGoogleTopSiteFollowOn() {
        GleanMetrics.Search.inContent["\(SearchEngine.google).in-content.google-topsite-follow-on.\(code)"].add()
    }

    // MARK: Track Regular and Follow-on SAP from Tab and TopSite

    func trackTabAndTopSiteSAP(_ tab: Tab, webView: WKWebView) {
        let provider = tab.getProviderForUrl()
        let code = SearchPartner.getCode(
            searchEngine: provider,
            region: Locale.current.regionCode == "US" ? "US" : "ROW"
        )
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
            let sClientValue = components.valueForQuery("sclient")
            // Special case google followOn search
            if (tab.urlType == .googleTopSite || tab.urlType == .googleTopSiteFollowOn) && clientValue == code {
                tab.urlType = .googleTopSiteFollowOn
                self.trackGoogleTopSiteFollowOn()
            // Check if previous tab type is search
            } else if (tab.urlType == .search || tab.urlType == .followOnSearch) && clientValue == code {
                tab.urlType = .followOnSearch
                self.trackSAPFollowOn()
            } else if provider == .google && sClientValue != nil {
                tab.urlType = .organicSearch
                self.trackOrganic()
            } else {
                tab.urlType = .regular
            }
        }
    }

    // MARK: Impression Telemetry
    func startImpressionTimer() {
        impressionTelemetryTimer?.invalidate()
        impressionTelemetryTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                        target: self,
                                                        selector: #selector(recordURLBarSearchImpressionTelemetryEvent),
                                                        userInfo: nil,
                                                        repeats: false)
    }

    func stopImpressionTimer() {
        impressionTelemetryTimer?.invalidate()
    }

    @objc
    func recordURLBarSearchImpressionTelemetryEvent() {
        guard let tab = tabManager.selectedTab else { return }
        let reasonKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.reason.rawValue
        let reason = SearchTelemetryValues.Reason.pause.rawValue

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = checkSAP(for: tab).rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = interactionType.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.tabs.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars = Int32(searchQuery.count)

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords = numberOfWords(in: searchQuery)

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults = Int32(numberOfSearchResults())

        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = listGroupTypes()

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = listResultTypes()

        let extraDetails = [
            reasonKey: reason,
            sapKey: sap,
            interactionKey: interaction,
            searchModeKey: searchMode,
            nCharsKey: nChars,
            nWordsKey: nWords,
            nResultsKey: nResults,
            groupsKey: groups,
            resultsKey: results]
        as [String: Any]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .urlbarImpression,
                                     extras: extraDetails)
    }

    // MARK: Engagement Telemetry
    func recordURLBarSearchEngagementTelemetryEvent() {
        guard let tab = tabManager.selectedTab else { return }

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = checkSAP(for: tab).rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = interactionType.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.tabs.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars = Int32(searchQuery.count)

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords = numberOfWords(in: searchQuery)

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults = Int32(numberOfSearchResults())

        let selectedResultKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResult.rawValue
        let selectedResult = selectedResult.rawValue

        let selectedResultSubtypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResultSubtype.rawValue
        let selectedResultSubtype = selectedResult

        let providerKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.provider.rawValue
        let provider = tab.getProviderForUrl().rawValue

        let engagementTypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.engagementType.rawValue
        let engagementType = engagementType.rawValue

        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = listGroupTypes()

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = listResultTypes()

        let extraDetails = [
            sapKey: sap,
            interactionKey: interaction,
            searchModeKey: searchMode,
            nCharsKey: nChars,
            nWordsKey: nWords,
            nResultsKey: nResults,
            selectedResultKey: selectedResult,
            selectedResultSubtypeKey: selectedResultSubtype,
            providerKey: provider,
            engagementTypeKey: engagementType,
            groupsKey: groups,
            resultsKey: results
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .urlbarEngagement,
                                     extras: extraDetails)
    }

    func recordURLBarSearchAbandonmentTelemetryEvent() {
        guard let tab = tabManager.selectedTab else { return }

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = checkSAP(for: tab).rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = interactionType.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.tabs.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars = Int32(searchQuery.count)

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords = numberOfWords(in: searchQuery)

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults = Int32(numberOfSearchResults())

        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = listGroupTypes()

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = listResultTypes()

        let extraDetails = [
            sapKey: sap,
            interactionKey: interaction,
            searchModeKey: searchMode,
            nCharsKey: nChars,
            nWordsKey: nWords,
            nResultsKey: nResults,
            groupsKey: groups,
            resultsKey: results
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .urlbarAbandonment,
                                     extras: extraDetails)
    }

    func checkSAP(for tab: Tab?) -> SearchTelemetryValues.Sap {
        guard let tab = tab else { return .urlbar }
        if tab.isFxHomeTab || tab.isCustomHomeTab {
            return .urlbarNewtab
        }
        return .urlbar
    }

    func determineInteractionType() {
        if searchQuery.count - savedQuery.count == 1 {
            interactionType = .typed
        } else if searchQuery.count - savedQuery.count > 1 {
            interactionType = .pasted
        }
    }

    func numberOfWords(in string: String) -> Int32 {
        let words = string.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let filteredWords = words.filter { !$0.isEmpty }
        return Int32(filteredWords.count)
    }

    func numberOfSearchResults() -> Int {
        return suggestions?.count ?? 0 + data.count + searchHighlights.count
        + filteredOpenedTabs.count + firefoxSuggestions.count
        + filteredRemoteClientTabs.count
    }

    // Comma separated list of result types in order.
    func listResultTypes() -> String {
        var resultTypes: [String] = []

        if let suggestionsCount = suggestions?.count, suggestionsCount > 0 {
            resultTypes += Array(repeating: SearchTelemetryValues.Results.searchSuggest.rawValue,
                                 count: suggestionsCount)
        }

        if !filteredOpenedTabs.isEmpty {
            resultTypes += Array(repeating: SearchTelemetryValues.Results.tab.rawValue,
                                 count: filteredOpenedTabs.count)
        }

        if !filteredRemoteClientTabs.isEmpty {
            resultTypes += Array(repeating: SearchTelemetryValues.Results.remoteTab.rawValue,
                                 count: filteredRemoteClientTabs.count)
        }

        for clientTab in data {
            if let isBookmarked = clientTab?.bookmarked {
                resultTypes.append(isBookmarked ?
                                   SearchTelemetryValues.Results.bookmark.rawValue :
                                    SearchTelemetryValues.Results.history.rawValue)
            }
        }

        if !searchHighlights.isEmpty {
            resultTypes += Array(repeating: SearchTelemetryValues.Results.searchHistory.rawValue,
                                 count: searchHighlights.count)
        }

        for suggestion in firefoxSuggestions {
            resultTypes.append(suggestion.isSponsored ?
                               SearchTelemetryValues.Results.suggestSponsor.rawValue :
                                SearchTelemetryValues.Results.suggestNonSponsor.rawValue)
        }

        return resultTypes.joined(separator: ",")
    }

    // Comma separated list of result groups in order, groups may be
    // repeated, since the list will match 1:1 the results list, so we
    // Can link each result to a group
    func listGroupTypes() -> String {
        var groupTypes: [String] = []

        if !(suggestions?.isEmpty ?? true) {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.searchSuggest.rawValue,
                                count: suggestions!.count)
        }

        if !filteredOpenedTabs.isEmpty {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.heuristic.rawValue,
                                count: filteredOpenedTabs.count)
        }

        if !filteredRemoteClientTabs.isEmpty {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.remoteTab.rawValue,
                                count: filteredRemoteClientTabs.count)
        }

        if !remoteClientTabs.isEmpty {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.general.rawValue,
                                count: remoteClientTabs.count)
        }

        if !searchHighlights.isEmpty {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.searchHistory.rawValue,
                                count: searchHighlights.count)
        }

        if !firefoxSuggestions.isEmpty {
            groupTypes += Array(repeating: SearchTelemetryValues.Groups.suggest.rawValue,
                                count: firefoxSuggestions.count)
        }

        return groupTypes.joined(separator: ",")
    }
}

private extension URLComponents {
    // Return the first query parameter that matches
    func valueForQuery(_ param: String) -> String? {
        return self.queryItems?.first { $0.name == param }?.value
    }
}
