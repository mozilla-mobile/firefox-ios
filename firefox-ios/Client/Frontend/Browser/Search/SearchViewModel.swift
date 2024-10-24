// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import class MozillaAppServices.FeatureHolder

protocol SearchViewDelegate: AnyObject {
    func reloadSearchEngines()
    func reloadTableView()
    var searchData: Cursor<Site> { get set}
}

class SearchViewModel: FeatureFlaggable, LoaderListener {
    private var profile: Profile
    private var tabManager: TabManager
    private var suggestClient: SearchSuggestClient?
    private var highlightManager: HistoryHighlightsManagerProtocol

    var remoteClientTabs = [ClientTabsSearchWrapper]()
    var filteredRemoteClientTabs = [ClientTabsSearchWrapper]()
    var filteredOpenedTabs = [Tab]()
    var searchHighlights = [HighlightItem]()
    var firefoxSuggestions = [RustFirefoxSuggestion]()
    let model: SearchEnginesManager
    var suggestions: [String]? = []
    static var userAgent: String?
    var searchFeature: FeatureHolder<Search>
    private var searchTelemetry: SearchTelemetry

    var bookmarkSites: [Site] {
        delegate?.searchData.compactMap { $0 }
            .filter { $0.bookmarked == true } ?? []
    }

    var historySites: [Site] {
        delegate?.searchData.compactMap { $0 }
            .filter { $0.bookmarked == false } ?? []
    }

    private let maxNumOfFirefoxSuggestions: Int32 = 1
    weak var delegate: SearchViewDelegate?
    private let isPrivate: Bool
    let isBottomSearchBar: Bool
    var savedQuery: String = ""
    var searchQuery: String = "" {
        didSet {
            querySuggestClient()
        }
    }

    var quickSearchEngines: [OpenSearchEngine] {
        guard let defaultEngine = searchEnginesManager?.defaultEngine else { return [] }

        var engines = searchEnginesManager?.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if !(searchEnginesManager?.shouldShowSearchSuggestions ?? false) {
            engines?.insert(defaultEngine, at: 0)
        }

        return engines!
    }

    var searchEnginesManager: SearchEnginesManager? {
        didSet {
            guard let defaultEngine = searchEnginesManager?.defaultEngine else { return }

            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            setupSuggestClient(with: defaultEngine)

            // Reload the footer list of search engines.
            delegate?.reloadSearchEngines()
        }
    }

    /// Whether to show sponsored suggestions from Firefox Suggest.
    var shouldShowSponsoredSuggestions: Bool {
        return !isPrivate &&
        model.shouldShowSponsoredSuggestions
    }

    /// Whether to show non-sponsored suggestions from Firefox Suggest.
    var shouldShowNonSponsoredSuggestions: Bool {
        return !isPrivate &&
        model.shouldShowFirefoxSuggestions
    }

    /// Whether to show suggestions from the search engine.
    var shouldShowSearchEngineSuggestions: Bool {
        return searchEnginesManager?.shouldShowSearchSuggestions ?? false
    }

    var shouldShowSyncedTabsSuggestions: Bool {
        return shouldShowFirefoxSuggestions(
            model.shouldShowSyncedTabsSuggestions
        )
    }

    var shouldShowBookmarksSuggestions: Bool {
        return shouldShowFirefoxSuggestions(
            model.shouldShowBookmarksSuggestions
        )
    }

    var shouldShowBrowsingHistorySuggestions: Bool {
        return shouldShowFirefoxSuggestions(
            model.shouldShowBrowsingHistorySuggestions
        )
    }

    private var hasBookmarksSuggestions: Bool {
        return !bookmarkSites.isEmpty &&
        shouldShowBookmarksSuggestions
    }

    private var hasHistorySuggestions: Bool {
        return !historySites.isEmpty &&
        shouldShowBrowsingHistorySuggestions
    }

    private var hasHistoryAndBookmarksSuggestions: Bool {
        let dataCount = delegate?.searchData.count
        return dataCount != 0 &&
        shouldShowBookmarksSuggestions &&
        shouldShowBrowsingHistorySuggestions
    }

    var hasFirefoxSuggestions: Bool {
        return hasBookmarksSuggestions
               || hasHistorySuggestions
               || hasHistoryAndBookmarksSuggestions
               || !filteredOpenedTabs.isEmpty
               || (!filteredRemoteClientTabs.isEmpty && shouldShowSyncedTabsSuggestions)
               || !searchHighlights.isEmpty
               || (!firefoxSuggestions.isEmpty && (shouldShowNonSponsoredSuggestions
                                                   || shouldShowSponsoredSuggestions))
    }

    init(isPrivate: Bool, isBottomSearchBar: Bool,
         profile: Profile,
         model: SearchEnginesManager,
         tabManager: TabManager,
         featureConfig: FeatureHolder<Search> = FxNimbus.shared.features.search,
         highlightManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager()
    ) {
        self.isPrivate = isPrivate
        self.isBottomSearchBar = isBottomSearchBar
        self.profile = profile
        self.model = model
        self.tabManager = tabManager
        self.searchFeature = featureConfig
        self.highlightManager = highlightManager
        self.searchTelemetry = SearchTelemetry(tabManager: tabManager)
    }

    func shouldShowHeader(for section: Int) -> Bool {
        switch section {
        case SearchListSection.firefoxSuggestions.rawValue:
            return hasFirefoxSuggestions
        case SearchListSection.searchSuggestions.rawValue:
            return shouldShowSearchEngineSuggestions
        default:
            return false
        }
    }

    private func loadSearchHighlights() {
        guard featureFlags.isFeatureEnabled(.searchHighlights, checking: .buildOnly) else { return }

        highlightManager.searchHighlightsData(
            searchQuery: searchQuery,
            profile: profile,
            tabs: tabManager.tabs,
            resultCount: 3) { results in
            guard let results = results else { return }
            self.searchHighlights = results
            self.delegate?.reloadTableView()
        }
    }

    func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty
            || searchQuery.looksLikeAURL() {
            suggestions = []
            delegate?.reloadTableView()
            return
        }

        loadSearchHighlights()
        _ = loadFirefoxSuggestions()

        let tempSearchQuery = searchQuery
        suggestClient?.query(searchQuery,
                             callback: { suggestions, error in
            if error == nil, self.shouldShowSearchEngineSuggestions {
                self.suggestions = suggestions!
                // Remove user searching term inside suggestions list
                self.suggestions?.removeAll(where: {
                    // swiftlint:disable line_length
                    $0.trimmingCharacters(in: .whitespacesAndNewlines) == self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    // swiftlint:enable line_length
                })
                // First suggestion should be what the user is searching
                self.suggestions?.insert(self.searchQuery, at: 0)
                self.searchTelemetry.clearVisibleResults()
            }

            // If there are no suggestions, just use whatever the user typed.
            if self.shouldShowSearchEngineSuggestions &&
               suggestions?.isEmpty ?? true {
                self.suggestions = [self.searchQuery]
            }

            self.searchTabs(for: self.searchQuery)
            self.searchRemoteTabs(for: self.searchQuery)
            self.savedQuery = tempSearchQuery
            self.searchTelemetry.savedQuery = tempSearchQuery
            self.delegate?.reloadTableView()
        })
    }

    func loadFirefoxSuggestions() -> Task<(), Never>? {
        let includeNonSponsored = shouldShowNonSponsoredSuggestions
        let includeSponsored = shouldShowSponsoredSuggestions
        guard featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser)
                && (includeNonSponsored || includeSponsored) else {
            if !firefoxSuggestions.isEmpty {
                firefoxSuggestions = []
                delegate?.reloadTableView()
            }
            return nil
        }

        profile.firefoxSuggest?.interruptReader()

        let tempSearchQuery = searchQuery
        let providers = [.amp, .ampMobile, .wikipedia]
            .filter { NimbusFirefoxSuggestFeatureLayer().isSuggestionProviderAvailable($0) }
            .filter {
                switch $0 {
                case .amp: includeSponsored
                case .ampMobile: includeSponsored
                case .wikipedia: includeNonSponsored
                default: false
                }
            }
        return Task { [weak self] in
            guard let self,
                  let suggestions = try? await self.profile.firefoxSuggest?.query(
                    tempSearchQuery,
                    providers: providers,
                    limit: maxNumOfFirefoxSuggestions
            ) else { return }
            await MainActor.run {
                guard self.searchQuery == tempSearchQuery, self.firefoxSuggestions != suggestions else { return }
                self.firefoxSuggestions = suggestions
                self.delegate?.reloadTableView()
            }
        }
    }

    func searchTabs(for searchString: String) {
        let currentTabs = isPrivate ? tabManager.privateTabs : tabManager.normalTabs

        // Small helper function to do case insensitive searching.
        // We split the search query by spaces so we can simulate full text search.
        let searchTerms = searchString.split(separator: " ")
        func find(in content: String?) -> Bool {
            guard let content = content else {
                return false
            }
            return searchTerms.reduce(true) {
                $0 && content.range(of: $1, options: .caseInsensitive) != nil
            }
        }
        let config = searchFeature.value().awesomeBar
        // Searching within the content will get annoying, so only start searching
        // in content when there are at least one word with more than 3 letters in.
        let searchInContent = config.usePageContent
        && searchTerms.contains(where: { $0.count >= config.minSearchTerm })

        filteredOpenedTabs = currentTabs.filter { tab in
            guard let url = tab.url,
                  !InternalURL.isValid(url: url) else {
                return false
            }
            let lines = [
                    tab.title ?? tab.lastTitle,
                    searchInContent ? tab.readabilityResult?.textContent : nil,
                    url.absoluteString
                ]
                .compactMap { $0 }

            let text = lines.joined(separator: "\n")
            return find(in: text)
        }
    }

    func searchRemoteTabs(for searchString: String) {
        filteredRemoteClientTabs.removeAll()
        for remoteClientTab in remoteClientTabs where remoteClientTab.tab.title.lowercased().contains(searchQuery) {
            filteredRemoteClientTabs.append(remoteClientTab)
        }

        let currentTabs = self.remoteClientTabs
        self.filteredRemoteClientTabs = currentTabs.filter { value in
            let tab = value.tab

            if InternalURL.isValid(url: tab.URL) {
                return false
            }

            if shouldShowSponsoredSuggestions &&
                SponsoredContentFilterUtility().containsSearchParam(url: tab.URL) {
                return false
            }

            if tab.title.lowercased().contains(searchString.lowercased()) {
                return true
            }

            if tab.URL.absoluteString.lowercased().contains(searchString.lowercased()) {
                return true
            }

            return false
        }
    }

    /// Sets up the suggestClient used to query our searches
    /// - Parameter defaultEngine: default search engine set in settings (i.e. Google)
    private func setupSuggestClient(with defaultEngine: OpenSearchEngine) {
        let ua = SearchViewModel.userAgent ?? "FxSearch"
        suggestClient = SearchSuggestClient(searchEngine: defaultEngine, userAgent: ua)
    }

    /// Determines if a suggestion should be shown based on the view model's privacy mode and
    /// the specific suggestion's status.
    private func shouldShowFirefoxSuggestions(_ suggestion: Bool) -> Bool {
        model.shouldShowPrivateModeFirefoxSuggestions = true
        return isPrivate ?
        (suggestion && model.shouldShowPrivateModeFirefoxSuggestions) :
        suggestion
    }

    // MARK: LoaderListener
    func loader(dataLoaded data: Cursor<Site>) {
        let previousData = self.delegate?.searchData
        self.delegate?.searchData = if shouldShowSponsoredSuggestions {
            ArrayCursor<Site>(data: SponsoredContentFilterUtility().filterSponsoredSites(from: data.asArray()))
        } else {
            data
        }

        if previousData?.asArray() != self.delegate?.searchData.asArray() {
            delegate?.reloadTableView()
        }
    }
}

/**
 * Private extension containing string operations specific to this view controller
 */
fileprivate extension String {
    func looksLikeAURL() -> Bool {
        // The assumption here is that if the user is typing in a forward slash and there are no spaces
        // involved, it's going to be a URL. If we type a space, any url would be invalid.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1192155 for additional details.
        return self.contains("/") && !self.contains(" ")
    }
}
