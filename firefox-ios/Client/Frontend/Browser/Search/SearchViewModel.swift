// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared
import Common
import class MozillaAppServices.FeatureHolder

protocol SearchViewDelegate: AnyObject {
    @MainActor
    func reloadSearchEngines()
    @MainActor
    func reloadTableView()
    @MainActor
    var searchData: Cursor<Site> { get set }
}

@MainActor
class SearchViewModel: FeatureFlaggable, LoaderListener {
    private var profile: Profile
    private var tabManager: TabManager
    private var suggestClient: SearchSuggestClient?
    private let recentSearchProvider: RecentSearchProvider
    private let trendingSearchClient: TrendingSearchClientProvider
    private let logger: Logger

    var remoteClientTabs = [ClientTabsSearchWrapper]()
    var filteredRemoteClientTabs = [ClientTabsSearchWrapper]()
    var filteredOpenedTabs = [Tab]()
    var firefoxSuggestions = [RustFirefoxSuggestion]()
    var trendingSearches = [String]()
    var recentSearches = [String]()
    let model: SearchEnginesManager
    var suggestions: [String]? = []
    // TODO: FXIOS-12588 This global property is not concurrency safe
    nonisolated(unsafe) static var userAgent: String?
    var searchFeature: FeatureHolder<Search>
    private var searchTelemetry: SearchTelemetry

    @MainActor
    var bookmarkSites: [Site] {
        delegate?.searchData.compactMap { $0 }
            .filter { $0.isBookmarked == true } ?? []
    }

    @MainActor
    var historySites: [Site] {
        let bookmarkURLs = Set(bookmarkSites.map { $0.url })

        return delegate?.searchData.compactMap { $0 }
            .filter { $0.isBookmarked == false && !bookmarkURLs.contains($0.url) } ?? []
    }

    private let maxNumOfFirefoxSuggestions: Int32 = 1
    weak var delegate: SearchViewDelegate?
    private let isPrivate: Bool
    public private(set) var isBottomSearchBar: Bool
    var savedQuery = ""
    @MainActor
    var searchQuery = "" {
        didSet {
            querySuggestClient()
            handleShowingOrHidingQuickSearchEngines(with: oldValue, newValue: searchQuery)
            // We want to reload showing the zero search suggestions
            // only if the previous search term is not empty.
            if searchQuery.isEmpty, !oldValue.isEmpty {
                loadTrendingSearches()
                retrieveRecentSearches()
                searchTelemetry.clearZeroSearchSectionSeen()
            }
        }
    }

    @MainActor
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

    @MainActor
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
    /// Does not show when search term in url is empty (aka zero search state).
    @MainActor
    var shouldShowSearchEngineSuggestions: Bool {
        let shouldShowSuggestions = searchEnginesManager?.shouldShowSearchSuggestions ?? false
        return shouldShowSuggestions && !isZeroSearchState
    }

    var shouldShowSyncedTabsSuggestions: Bool {
        guard !isZeroSearchState else { return false }
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

    @MainActor
    private var hasBookmarksSuggestions: Bool {
        return !bookmarkSites.isEmpty &&
        shouldShowBookmarksSuggestions
    }

    @MainActor
    private var hasHistorySuggestions: Bool {
        return !historySites.isEmpty &&
        shouldShowBrowsingHistorySuggestions
    }

    @MainActor
    private var hasHistoryAndBookmarksSuggestions: Bool {
        let dataCount = delegate?.searchData.count
        return dataCount != 0 &&
        hasBookmarksSuggestions &&
        hasHistorySuggestions
    }

    /// Does not show when search term in url is empty (aka zero search state).
    @MainActor
    var hasFirefoxSuggestions: Bool {
        guard !isZeroSearchState else { return false }
        return hasBookmarksSuggestions
               || hasHistorySuggestions
               || hasHistoryAndBookmarksSuggestions
               || !filteredOpenedTabs.isEmpty
               || (!filteredRemoteClientTabs.isEmpty && shouldShowSyncedTabsSuggestions)
               || (!firefoxSuggestions.isEmpty && (shouldShowNonSponsoredSuggestions
                                                   || shouldShowSponsoredSuggestions))
    }

    // MARK: - Zero Search State Variables
    // Determines whether we should zero search state based on searchQuery being empty.
    // Zero search state is when the user has not entered a search term in the address bar.
    @MainActor
    var isZeroSearchState: Bool {
        return searchQuery.isEmpty
    }

    // Show list of recent searches if user puts focus in the address bar but does not enter any text.
    @MainActor
    var shouldShowRecentSearches: Bool {
        let isFeatureOn = featureFlags.isFeatureEnabled(.recentSearches, checking: .buildOnly)
        let isSettingsToggleOn = model.shouldShowRecentSearches
        return isFeatureOn && isSettingsToggleOn && isZeroSearchState
    }

    // Show list of trending searches if user puts focus in the address bar but does not enter any text.
    @MainActor
    var shouldShowTrendingSearches: Bool {
        let isFeatureOn = featureFlags.isFeatureEnabled(.trendingSearches, checking: .buildOnly)
        let isSettingsToggleOn = model.shouldShowTrendingSearches
        return isFeatureOn && isSettingsToggleOn && isZeroSearchState
    }

    init(
        isPrivate: Bool,
        isBottomSearchBar: Bool,
        profile: Profile,
        model: SearchEnginesManager,
        tabManager: TabManager,
        trendingSearchClient: TrendingSearchClientProvider,
        recentSearchProvider: RecentSearchProvider,
        logger: Logger = DefaultLogger.shared,
        featureConfig: FeatureHolder<Search> = FxNimbus.shared.features.search
    ) {
        self.isPrivate = isPrivate
        self.isBottomSearchBar = isBottomSearchBar
        self.profile = profile
        self.model = model
        self.tabManager = tabManager
        self.trendingSearchClient = trendingSearchClient
        self.recentSearchProvider = recentSearchProvider
        self.logger = logger
        self.searchFeature = featureConfig
        self.searchTelemetry = SearchTelemetry(tabManager: tabManager)
    }

    func updateBottomSearchBarState(isBottomSearchBar: Bool) {
        self.isBottomSearchBar = isBottomSearchBar
    }

    @MainActor
    func shouldShowHeader(for section: Int) -> Bool {
        switch section {
        case SearchListSection.recentSearches.rawValue:
            guard !recentSearches.isEmpty else { return false }
            return shouldShowRecentSearches
        case SearchListSection.trendingSearches.rawValue:
            guard !trendingSearches.isEmpty else { return false }
            return shouldShowTrendingSearches
        case SearchListSection.firefoxSuggestions.rawValue:
            return hasFirefoxSuggestions
        case SearchListSection.searchSuggestions.rawValue:
            return shouldShowSearchEngineSuggestions
        default:
            return false
        }
    }

    @MainActor
    func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty
            || searchQuery.looksLikeAURL() {
            suggestions = []
            delegate?.reloadTableView()
            return
        }

        Task {
            await loadFirefoxSuggestions()
        }

        let tempSearchQuery = searchQuery
        suggestClient?.query(searchQuery,
                             callback: { suggestions, error in
            ensureMainThread {
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
            }
        })
    }

    /// Provides suggestions from external suggestion providers other than the local ones (history, bookmarks, etc.). For now
    /// this includes suggestions from `amp` (sponsored ads) and `wikipedia`. Application Services supports the other ones.
    /// This behaviour is currently geo-locked to the US, so to debug locally ensure your simulator region is set to US.
    @MainActor
    func loadFirefoxSuggestions() async {
        let includeNonSponsored = shouldShowNonSponsoredSuggestions
        let includeSponsored = shouldShowSponsoredSuggestions

        guard featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser)
                && (includeNonSponsored || includeSponsored) else {
            if !firefoxSuggestions.isEmpty {
                firefoxSuggestions = []
                delegate?.reloadTableView()
            }
            return
        }

        profile.firefoxSuggest?.interruptReader()

        let tempSearchQuery = searchQuery
        let providers = [.amp, .wikipedia]
            .filter { NimbusFirefoxSuggestFeatureLayer().isSuggestionProviderAvailable($0) }
            .filter {
                switch $0 {
                case .amp: includeSponsored
                case .wikipedia: includeNonSponsored
                default: false
                }
            }

        // TODO: FXIOS-12610 Profile should be refactored so it is **not** `Sendable`. That will cause future issues with
        // passing `firefoxSuggest` out of this `@MainActor` isolated context.
        guard let suggestions = try? await profile.firefoxSuggest?.query(
            tempSearchQuery,
            providers: providers,
            limit: maxNumOfFirefoxSuggestions
        ),
              searchQuery == tempSearchQuery,
              firefoxSuggestions != suggestions
        else { return }

        firefoxSuggestions = suggestions
        delegate?.reloadTableView()
    }

    // MARK: - Zero Search State Feature
    // The zero search state refers to when user puts focus in the address bar but does not enter any text.
    @MainActor
    func loadTrendingSearches() {
        Task { @MainActor in
            await retrieveTrendingSearches()
            delegate?.reloadTableView()
        }
    }

    @MainActor
    private func retrieveTrendingSearches() async {
        guard shouldShowTrendingSearches else {
            trendingSearches = []
            return
        }

        do {
            let searchEngine = searchEnginesManager?.defaultEngine
            let results = try await trendingSearchClient.getTrendingSearches(for: searchEngine)
            trendingSearches = results
        } catch {
            logger.log(
                "Trending searches errored out, return empty list.",
                level: .info,
                category: .searchEngines
            )
            trendingSearches = []
        }
    }

    // We only care about if the section has shown at least one trending search
    // so we check if trending searches is empty or not
    func recordTrendingSearchesDisplayedEvent() {
        guard !trendingSearches.isEmpty && shouldShowTrendingSearches else { return }
        if !searchTelemetry.hasSeenTrendingSearches {
            searchTelemetry.trendingSearchesShown(count: trendingSearches.count)
            searchTelemetry.hasSeenTrendingSearches = true
        }
    }

    // Loads recent searches from the default search engine and updates `recentSearches`.
    // Falls back to an empty list on error.
    @MainActor
    func retrieveRecentSearches() {
        guard shouldShowRecentSearches else {
            recentSearches = []
            return
        }

        recentSearchProvider.loadRecentSearches { searchTerms in
            ensureMainThread { [weak self] in
                self?.recentSearches = searchTerms
                self?.delegate?.reloadTableView()
            }
        }
    }

    // We only care about if the section has shown at least one recent search
    // so we check if recent searches is empty or not.
    func recordRecentSearchesDisplayedEvent() {
        guard !recentSearches.isEmpty && shouldShowRecentSearches else { return }
        if !searchTelemetry.hasSeenRecentSearches {
            searchTelemetry.recentSearchesShown(count: recentSearches.count)
            searchTelemetry.hasSeenRecentSearches = true
        }
    }

    func clearRecentSearches() {
        searchTelemetry.recentSearchesClearButtonTapped()

        recentSearchProvider.clear { result in
            ensureMainThread { [weak self] in
                if case .success = result {
                    self?.recentSearches = []
                    self?.delegate?.reloadTableView()
                } else {
                    self?.logger.log(
                        "Unable to clear recent searches.",
                        level: .warning,
                        category: .searchEngines
                    )
                }
            }
        }
    }

    @MainActor
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

    @MainActor
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

    /// Handles reloading the quick search engine list when the search text transitions
    /// between empty and non-empty value.
    ///
    /// This method determines whether should hit showing the quick search engines code.
    /// It triggers a reload only when search text changes from empty to non-empty or vice-versa.
    /// For example, when the user starts typing (empty → non-empty)
    /// or clears the search field (non-empty → empty).
    ///
    /// - Parameters:
    ///   - oldValue: The previous search text value.
    ///   - newValue: The updated search text value.
    @MainActor
    private func handleShowingOrHidingQuickSearchEngines(with oldValue: String, newValue: String) {
        guard oldValue.isEmpty != newValue.isEmpty else { return }
        delegate?.reloadSearchEngines()
    }

    /// Sets up the suggestClient used to query our searches
    /// - Parameter defaultEngine: default search engine set in settings (i.e. Google)
    private func setupSuggestClient(with defaultEngine: OpenSearchEngine) {
        let ua = SearchViewModel.userAgent ?? "FxSearch"
        suggestClient = SearchSuggestClient(searchEngine: defaultEngine, userAgent: ua)
    }

    /// Determines if a suggestion should be shown based on the view model's privacy mode and
    /// the specific suggestion's status. We do not show if in zero search state.
    private func shouldShowFirefoxSuggestions(_ suggestion: Bool) -> Bool {
        guard !isZeroSearchState else { return false }
        model.shouldShowPrivateModeFirefoxSuggestions = true
        return isPrivate ?
        (suggestion && model.shouldShowPrivateModeFirefoxSuggestions) :
        suggestion
    }

    // MARK: LoaderListener
    func loader(dataLoaded data: Cursor<Site>) {
        ensureMainThread {
            let previousData = self.delegate?.searchData
            self.delegate?.searchData = if self.shouldShowSponsoredSuggestions {
                ArrayCursor<Site>(data: SponsoredContentFilterUtility().filterSponsoredSites(from: data.asArray()))
            } else {
                data
            }

            if previousData?.asArray() != self.delegate?.searchData.asArray() {
                self.delegate?.reloadTableView()
            }
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
