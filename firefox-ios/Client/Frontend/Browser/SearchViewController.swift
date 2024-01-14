// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import Telemetry
import Common
import SiteImageView

private enum SearchListSection: Int, CaseIterable {
    case searchSuggestions
    case remoteTabs
    case openedTabs
    case bookmarksAndHistory
    case searchHighlights
    case firefoxSuggestions
}

private struct SearchViewControllerUX {
    static let EngineButtonHeight: Float = 44 // Equivalent to toolbar height, fixed at the moment
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = "search"
    static let SearchEngineTopBorderWidth = 0.5
    static let SuggestionMargin: CGFloat = 8

    static let IconSize: CGFloat = 23
    static let FaviconSize: CGFloat = 29
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

protocol SearchViewControllerDelegate: AnyObject {
    func searchViewController(
        _ searchViewController: SearchViewController,
        didSelectURL url: URL,
        searchTerm: String?
    )
    func searchViewController(_ searchViewController: SearchViewController, uuid: String)
    func presentSearchSettingsController()
    func searchViewController(
        _ searchViewController: SearchViewController,
        didHighlightText text: String,
        search: Bool
    )
    func searchViewController(
        _ searchViewController: SearchViewController,
        didAppend text: String
    )
}

// Note: ClientAndTabs data structure contains all tabs under a remote client. To make traversal and search easier
// this wrapper combines them and is helpful in showing Remote Client and Remote tab in our SearchViewController
struct ClientTabsSearchWrapper {
    var client: RemoteClient
    var tab: RemoteTab
}

struct SearchViewModel {
    let isPrivate: Bool
    let isBottomSearchBar: Bool
}

class SearchViewController: SiteTableViewController,
                            KeyboardHelperDelegate,
                            LoaderListener,
                            FeatureFlaggable,
                            Notifiable {
    typealias ExtraKey = TelemetryWrapper.EventExtraKey

    var searchDelegate: SearchViewControllerDelegate?
    private let viewModel: SearchViewModel
    private let model: SearchEngines
    private var suggestClient: SearchSuggestClient?
    private var remoteClientTabs = [ClientTabsSearchWrapper]()
    private var filteredRemoteClientTabs = [ClientTabsSearchWrapper]()
    private var openedTabs = [Tab]()
    private var filteredOpenedTabs = [Tab]()
    private var tabManager: TabManager
    private var searchHighlights = [HighlightItem]()
    var firefoxSuggestions = [RustFirefoxSuggestion]()
    private var highlightManager: HistoryHighlightsManagerProtocol

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    private let searchEngineContainerView: UIView = .build()
    private let searchEngineScrollView: ButtonScrollView = .build()
    private let searchEngineScrollViewContent: UIView = .build()
    private var bottomConstraintWithKeyboard: NSLayoutConstraint?
    private var bottomConstraintWithoutKeyboard: NSLayoutConstraint?

    private lazy var bookmarkedBadge: UIImage = {
        return UIImage(named: StandardImageIdentifiers.Medium.bookmarkBadgeFillBlue50)!
    }()

    private lazy var openAndSyncTabBadge: UIImage = {
        return UIImage(named: "sync_open_tab")!
    }()

    var suggestions: [String]? = []
    var savedQuery: String = ""
    var searchFeature: FeatureHolder<Search>
    static var userAgent: String?

    var hasFirefoxSuggestions: Bool {
        let dataCount = data.count
        return dataCount != 0
            || !filteredOpenedTabs.isEmpty
            || !filteredRemoteClientTabs.isEmpty
            || !searchHighlights.isEmpty
            || !firefoxSuggestions.isEmpty
    }

    init(profile: Profile,
         viewModel: SearchViewModel,
         model: SearchEngines,
         tabManager: TabManager,
         featureConfig: FeatureHolder<Search> = FxNimbus.shared.features.search,
         highlightManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager()) {
        self.viewModel = viewModel
        self.model = model
        self.tabManager = tabManager
        self.searchFeature = featureConfig
        self.highlightManager = highlightManager
        super.init(profile: profile)

        tableView.sectionHeaderTopPadding = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getCachedTabs()
        KeyboardHelper.defaultHelper.addDelegate(self)

        searchEngineContainerView.layer.shadowRadius = 0
        searchEngineContainerView.layer.shadowOpacity = 100
        searchEngineContainerView.layer.shadowOffset = CGSize(
            width: 0,
            height: -SearchViewControllerUX.SearchEngineTopBorderWidth
        )
        searchEngineContainerView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        searchEngineContainerView.addSubview(searchEngineScrollView)
        view.addSubview(searchEngineContainerView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clear.cgColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)

        layoutTable()
        layoutSearchEngineScrollView()
        layoutSearchEngineScrollViewContent()

        NSLayoutConstraint.activate([
            searchEngineContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchEngineContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchEngineContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupNotifications(forObserver: self, observing: [.DynamicFontChanged,
                                                          .SearchSettingsChanged])
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
            self.tableView.reloadData()
        }
    }

    func loadFirefoxSuggestions() -> Task<(), Never>? {
        let includeNonSponsored = profile.prefs.boolForKey(PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions) ?? false
        let includeSponsored = profile.prefs.boolForKey(PrefsKeys.FirefoxSuggestShowSponsoredSuggestions) ?? false
        guard featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser)
                && (includeNonSponsored || includeSponsored)
        else { return nil }

        profile.firefoxSuggest?.interruptReader()

        let tempSearchQuery = searchQuery
        return Task { [weak self] in
            guard let suggestions = try? await self?.profile.firefoxSuggest?.query(
                tempSearchQuery,
                includeSponsored: includeSponsored,
                includeNonSponsored: includeNonSponsored
            ) else { return }
            await MainActor.run {
                guard let self, self.searchQuery == tempSearchQuery else { return }
                self.firefoxSuggestions = suggestions
                self.tableView.reloadData()
            }
        }
    }

    func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSearchEngines()
        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchFeature.recordExposure()
    }

    private func layoutSearchEngineScrollView() {
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0

        NSLayoutConstraint.activate([
            searchEngineScrollView.leadingAnchor.constraint(equalTo: searchEngineContainerView.leadingAnchor),
            searchEngineScrollView.trailingAnchor.constraint(equalTo: searchEngineContainerView.trailingAnchor),
            searchEngineScrollView.topAnchor.constraint(equalTo: searchEngineContainerView.topAnchor)
        ])

        // Remove existing keyboard-related bottom constraints (if any)
        bottomConstraintWithKeyboard?.isActive = false
        bottomConstraintWithoutKeyboard?.isActive = false

        if keyboardHeight == 0 {
            bottomConstraintWithoutKeyboard = searchEngineScrollView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            )
            bottomConstraintWithoutKeyboard?.isActive = true
        } else {
            let offset = viewModel.isBottomSearchBar ? 0 : keyboardHeight
            bottomConstraintWithKeyboard = searchEngineScrollView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -offset
            )
            bottomConstraintWithKeyboard?.isActive = true
        }
    }

    private func layoutSearchEngineScrollViewContent() {
        NSLayoutConstraint.activate(
            [
                searchEngineScrollViewContent.centerXAnchor.constraint(
                    equalTo: searchEngineScrollView.centerXAnchor
                ).priority(.defaultLow),
                searchEngineScrollViewContent.centerYAnchor.constraint(
                    equalTo: searchEngineScrollView.centerYAnchor
                ).priority(.defaultLow),
                searchEngineScrollViewContent.trailingAnchor.constraint(
                    lessThanOrEqualTo: searchEngineScrollView.trailingAnchor
                ).priority(.defaultHigh),
                searchEngineScrollViewContent.topAnchor.constraint(equalTo: searchEngineScrollView.topAnchor),
                searchEngineScrollViewContent.bottomAnchor.constraint(equalTo: searchEngineScrollView.bottomAnchor)
            ]
        )

        // left-align the engines on iphones, center on ipad
        let isCompact = UIScreen.main.traitCollection.horizontalSizeClass == .compact
        searchEngineScrollViewContent.leadingAnchor.constraint(
            equalTo: searchEngineScrollView.leadingAnchor
        ).priority(.defaultHigh).isActive = isCompact
        searchEngineScrollViewContent.leadingAnchor.constraint(
            greaterThanOrEqualTo: searchEngineScrollView.leadingAnchor
        ).priority(.defaultHigh).isActive = !isCompact
    }

    var searchEngines: SearchEngines? {
        didSet {
            guard let defaultEngine = searchEngines?.defaultEngine else { return }

            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            if !viewModel.isPrivate {
                let ua = SearchViewController.userAgent ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: defaultEngine, userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()
        }
    }

    private var quickSearchEngines: [OpenSearchEngine] {
        guard let defaultEngine = searchEngines?.defaultEngine else { return [] }

        var engines = searchEngines?.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if viewModel.isPrivate || !(searchEngines?.shouldShowSearchSuggestions ?? false) {
            engines?.insert(defaultEngine, at: 0)
        }

        return engines!
    }

    var searchQuery: String = "" {
        didSet {
            // Reload the tableView to show the updated text in each engine.
            reloadData()
        }
    }

    override func reloadData() {
        querySuggestClient()
    }

    private func layoutTable() {
        // Note: We remove and re-add tableview from superview so that we can update
        // the constraints to be aligned with Search Engine Scroll View top anchor
        tableView.removeFromSuperview()
        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: searchEngineScrollView.topAnchor)
        ])
    }

    func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.leadingAnchor

        // search settings icon
        let searchButton: UIButton = .build()
        searchButton.setImage(UIImage(named: "quickSearch"), for: [])
        searchButton.imageView?.contentMode = .scaleAspectFit
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        searchButton.accessibilityLabel = String(format: .SearchSettingsAccessibilityLabel)

        if let imageView = searchButton.imageView {
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 20),
                imageView.heightAnchor.constraint(equalToConstant: 20)
            ])
        }

        searchEngineScrollViewContent.addSubview(searchButton)

        NSLayoutConstraint.activate(
            [
                searchButton.widthAnchor.constraint(equalToConstant: SearchViewControllerUX.FaviconSize),
                searchButton.heightAnchor.constraint(equalToConstant: SearchViewControllerUX.FaviconSize),
                // offset the left edge to align with search results
                searchButton.leadingAnchor.constraint(equalTo: leftEdge, constant: 16),
                searchButton.topAnchor.constraint(
                    equalTo: searchEngineScrollViewContent.topAnchor,
                    constant: SearchViewControllerUX.SuggestionMargin
                ),
                searchButton.bottomAnchor.constraint(
                    equalTo: searchEngineScrollViewContent.bottomAnchor,
                    constant: -SearchViewControllerUX.SuggestionMargin
                )
            ]
        )

        leftEdge = searchButton.trailingAnchor

        for engine in quickSearchEngines {
            let engineButton: UIButton = .build()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.imageView?.layer.cornerRadius = 4
            engineButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(didSelectEngine), for: .touchUpInside)
            engineButton.accessibilityLabel = String(format: .SearchSearchEngineAccessibilityLabel, engine.shortName)

            if let imageView = engineButton.imageView {
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: SearchViewControllerUX.FaviconSize),
                    imageView.heightAnchor.constraint(equalToConstant: SearchViewControllerUX.FaviconSize)
                ])
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            NSLayoutConstraint.activate(
                [
                    engineButton.widthAnchor.constraint(
                        equalToConstant: CGFloat(SearchViewControllerUX.EngineButtonWidth)
                    ),
                    engineButton.heightAnchor.constraint(
                        equalToConstant: CGFloat(SearchViewControllerUX.EngineButtonHeight)
                    ),
                    engineButton.leadingAnchor.constraint(equalTo: leftEdge),
                    engineButton.topAnchor.constraint(equalTo: searchEngineScrollViewContent.topAnchor),
                    engineButton.bottomAnchor.constraint(equalTo: searchEngineScrollViewContent.bottomAnchor)
                ]
            )

            if engine === self.searchEngines?.quickSearchEngines.last {
                engineButton.trailingAnchor.constraint(
                    equalTo: searchEngineScrollViewContent.trailingAnchor
                ).isActive = true
            }

            leftEdge = engineButton.trailingAnchor
        }
    }

    func didSelectEngine(_ sender: UIButton) {
        // The UIButtons are the same cardinality and order as the array of quick search engines.
        // Subtract 1 from index to account for magnifying glass accessory.
        guard let index = searchEngineScrollViewContent.subviews.firstIndex(of: sender) else {
            assertionFailure()
            return
        }

        let engine = quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(searchQuery) else {
            assertionFailure()
            return
        }
        let extras = [
            ExtraKey.recordSearchLocation.rawValue: SearchesMeasurement.SearchLocation.quickSearch,
            ExtraKey.recordSearchEngineID.rawValue: engine.engineID as Any
        ] as [String: Any]
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: .recordSearch,
                                          extras: extras)

        searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: "")
    }

    func didClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()
    }

    func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillShowWithState state: KeyboardState
    ) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillHideWithState state: KeyboardState
    ) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(
        _ keyboardHelper: KeyboardHelper,
        keyboardWillChangeWithState state: KeyboardState
    ) {
        animateSearchEnginesWithKeyboard(state)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // The height of the suggestions row may change, so call reloadData() to recalculate cell heights.
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
            self.layoutSearchEngineScrollViewContent()
        }, completion: nil)
    }

    private func animateSearchEnginesWithKeyboard(_ keyboardState: KeyboardState) {
        layoutSearchEngineScrollView()

        UIView.animate(
            withDuration: keyboardState.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(keyboardState.animationCurve.rawValue << 16))],
            animations: {
                self.view.layoutIfNeeded()
            })
    }

    private func getCachedTabs() {
        // Short circuit if the user is not logged in
        guard profile.hasSyncableAccount() else { return }

        ensureMainThread {
            // Get cached tabs
            self.profile.getCachedClientsAndTabs().uponQueue(.main) { result in
                guard let clientAndTabs = result.successValue else { return }
                self.remoteClientTabs.removeAll()
                // Update UI with cached data.
                clientAndTabs.forEach { value in
                    value.tabs.forEach { (tab) in
                        self.remoteClientTabs.append(ClientTabsSearchWrapper(client: value.client, tab: tab))
                    }
                }
            }
        }
    }

    func searchTabs(for searchString: String) {
        let currentTabs = viewModel.isPrivate ? tabManager.privateTabs : tabManager.normalTabs

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
            && searchTerms.find { $0.count >= config.minSearchTerm } != nil

        filteredOpenedTabs = currentTabs.filter { tab in
            guard let url = tab.url ?? tab.sessionData?.urls.last,
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

            if tab.title.lowercased().contains(searchString.lowercased()) {
                return true
            }

            if tab.URL.absoluteString.lowercased().contains(searchString.lowercased()) {
                return true
            }

            return false
        }
    }

    private func querySuggestClient() {
        suggestClient?.cancelPendingRequest()

        if searchQuery.isEmpty
            || !(searchEngines?.shouldShowSearchSuggestions ?? false)
            || searchQuery.looksLikeAURL() {
            suggestions = []
            tableView.reloadData()
            return
        }

        loadSearchHighlights()
        _ = loadFirefoxSuggestions()

        let tempSearchQuery = searchQuery
        suggestClient?.query(searchQuery,
                             callback: { suggestions, error in
            if error == nil {
                self.suggestions = suggestions!
                // Remove user searching term inside suggestions list
                self.suggestions?.removeAll(where: {
                    // swiftlint:disable line_length
                    $0.trimmingCharacters(in: .whitespacesAndNewlines) == self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                    // swiftlint:enable line_length
                })
                // First suggestion should be what the user is searching
                self.suggestions?.insert(self.searchQuery, at: 0)
            }

            // If there are no suggestions, just use whatever the user typed.
            if suggestions?.isEmpty ?? true {
                self.suggestions = [self.searchQuery]
            }

            self.searchTabs(for: self.searchQuery)
            self.searchRemoteTabs(for: self.searchQuery)
            // Reload the tableView to show the new list of search suggestions.
            self.savedQuery = tempSearchQuery
            self.tableView.reloadData()
        })
    }

    func loader(dataLoaded data: Cursor<Site>) {
        self.data = data
        tableView.reloadData()
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SearchListSection(rawValue: indexPath.section)! {
        case .searchSuggestions:
            guard let defaultEngine = searchEngines?.defaultEngine else { return }

            recordSearchListSelectionTelemetry(type: .searchSuggestions)
            // Assume that only the default search engine can provide search suggestions.
            guard let suggestions = suggestions,
                  let suggestion = suggestions[safe: indexPath.row],
                  let url = defaultEngine.searchURLForQuery(suggestion)
            else { return }

            let extras = [
                ExtraKey.recordSearchLocation.rawValue: SearchesMeasurement.SearchLocation.suggestion,
                ExtraKey.recordSearchEngineID.rawValue: defaultEngine.engineID as Any
            ] as [String: Any]
            TelemetryWrapper.gleanRecordEvent(category: .action,
                                              method: .tap,
                                              object: .recordSearch,
                                              extras: extras)
            searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: suggestion)
        case .openedTabs:
            recordSearchListSelectionTelemetry(type: .openedTabs)
            let tab = self.filteredOpenedTabs[indexPath.row]
            searchDelegate?.searchViewController(self, uuid: tab.tabUUID)
        case .remoteTabs:
            recordSearchListSelectionTelemetry(type: .remoteTabs)
            let remoteTab = self.filteredRemoteClientTabs[indexPath.row].tab
            searchDelegate?.searchViewController(self, didSelectURL: remoteTab.URL, searchTerm: nil)
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                recordSearchListSelectionTelemetry(type: .bookmarksAndHistory,
                                                   isBookmark: site.bookmarked ?? false)
                if let url = URL(string: site.url, invalidCharacters: false) {
                    searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
                }
            }
        case .searchHighlights:
            if let urlString = searchHighlights[indexPath.row].urlString,
                let url = URL(string: urlString, invalidCharacters: false) {
                recordSearchListSelectionTelemetry(type: .searchHighlights)
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
            }
        case .firefoxSuggestions:
            let firefoxSuggestion = firefoxSuggestions[indexPath.row]
            if let clickInfo = firefoxSuggestion.clickInfo {
                // The 1-based position of this suggestion, relative to the top of the table.
                let position = SearchListSection.allCases.filter { $0.rawValue < indexPath.section }
                    .reduce(0) { $0 + self.tableView(tableView, numberOfRowsInSection: $1.rawValue) }
                + indexPath.row + 1
                recordFirefoxSuggestSelectionTelemetry(
                    clickInfo: clickInfo,
                    position: position
                )
            }

            searchDelegate?.searchViewController(
                self,
                didSelectURL: firefoxSuggestion.url,
                searchTerm: nil
            )
        }
    }

    override func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        guard shouldShowHeader(for: section) else { return 0 }

        return UITableView.automaticDimension
    }

    override func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard shouldShowHeader(for: section),
              let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: SiteTableViewHeader.cellIdentifier) as? SiteTableViewHeader
        else { return nil }

        var title: String
        switch section {
        case SearchListSection.remoteTabs.rawValue:
            title = .Search.SuggestSectionTitle
        case SearchListSection.searchSuggestions.rawValue:
            title = searchEngines?.defaultEngine?.headerSearchTitle ?? ""
        default:  title = ""
        }

        let viewModel = SiteTableViewHeaderModel(title: title,
                                                 isCollapsible: false,
                                                 collapsibleState: nil)
        headerView.configure(viewModel)
        headerView.applyTheme(theme: themeManager.currentTheme)
        return headerView
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let twoLineImageOverlayCell = tableView.dequeueReusableCell(
            withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
            for: indexPath
        ) as! TwoLineImageOverlayCell
        let oneLineTableViewCell = tableView.dequeueReusableCell(
            withIdentifier: OneLineTableViewCell.cellIdentifier,
            for: indexPath
        ) as! OneLineTableViewCell
        return getCellForSection(twoLineImageOverlayCell,
                                 oneLineCell: oneLineTableViewCell,
                                 for: SearchListSection(rawValue: indexPath.section)!,
                                 indexPath)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            guard let count = suggestions?.count else { return 0 }
            return count < 4 ? count : 4
        case .openedTabs:
            return filteredOpenedTabs.count
        case .remoteTabs:
            return filteredRemoteClientTabs.count
        case .bookmarksAndHistory:
            return data.count
        case .searchHighlights:
            return searchHighlights.count
        case .firefoxSuggestions:
            return firefoxSuggestions.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return SearchListSection.allCases.count
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let section = SearchListSection(rawValue: indexPath.section) else { return }

        if section == .bookmarksAndHistory,
            let suggestion = data[indexPath.item] {
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        }
    }

    override func applyTheme() {
        super.applyTheme()
        view.backgroundColor = themeManager.currentTheme.colors.layer5
        searchEngineContainerView.layer.backgroundColor = themeManager.currentTheme.colors.layer1.cgColor
        searchEngineContainerView.layer.shadowColor = themeManager.currentTheme.colors.shadowDefault.cgColor
        reloadData()
    }

    func getAttributedBoldSearchSuggestions(searchPhrase: String, query: String) -> NSAttributedString? {
        // the search term (query) stays normal weight
        // everything past the search term (query) will be bold
        let range = searchPhrase.range(of: query)
        guard searchPhrase != query, let upperBound = range?.upperBound else { return nil }

        let attributedString = searchPhrase.attributedText(
            boldIn: upperBound..<searchPhrase.endIndex,
            font: DefaultDynamicFontHelper.preferredFont(
                withTextStyle: .body,
                size: 17,
                weight: .regular
            )
        )
        return attributedString
    }

    private func getCellForSection(_ twoLineCell: TwoLineImageOverlayCell,
                                   oneLineCell: OneLineTableViewCell,
                                   for section: SearchListSection,
                                   _ indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        switch section {
        case .searchSuggestions:
            if let site = suggestions?[indexPath.row] {
                oneLineCell.titleLabel.text = site
                if Locale.current.languageCode == "en",
                   let attributedString = getAttributedBoldSearchSuggestions(
                    searchPhrase: site,
                    query: savedQuery
                   ) {
                    oneLineCell.titleLabel.attributedText = attributedString
                }
                oneLineCell.leftImageView.contentMode = .center
                oneLineCell.leftImageView.layer.borderWidth = 0
                oneLineCell.leftImageView.manuallySetImage(
                    UIImage(named: SearchViewControllerUX.SearchImage) ?? UIImage()
                )
                oneLineCell.leftImageView.tintColor = themeManager.currentTheme.colors.iconPrimary
                oneLineCell.leftImageView.backgroundColor = nil
                let appendButton = UIButton(type: .roundedRect)
                appendButton.setImage(searchAppendImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                appendButton.addTarget(self, action: #selector(append(_ :)), for: .touchUpInside)
                appendButton.tintColor = themeManager.currentTheme.colors.iconPrimary
                appendButton.sizeToFit()
                oneLineCell.accessoryView = indexPath.row > 0 ? appendButton : nil
                cell = oneLineCell
            }
        case .openedTabs:
            if self.filteredOpenedTabs.count > indexPath.row {
                let openedTab = self.filteredOpenedTabs[indexPath.row]
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.titleLabel.text = openedTab.title ?? openedTab.lastTitle
                twoLineCell.descriptionLabel.text = String.SearchSuggestionCellSwitchToTabLabel
                twoLineCell.leftOverlayImageView.image = openAndSyncTabBadge
                twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                if let urlString = openedTab.url?.absoluteString {
                    twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: urlString))
                }
                twoLineCell.accessoryView = nil
                cell = twoLineCell
            }
        case .remoteTabs:
            if self.filteredRemoteClientTabs.count > indexPath.row {
                let remoteTab = self.filteredRemoteClientTabs[indexPath.row].tab
                let remoteClient = self.filteredRemoteClientTabs[indexPath.row].client
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.titleLabel.text = remoteTab.title
                twoLineCell.descriptionLabel.text = remoteClient.name
                twoLineCell.leftOverlayImageView.image = openAndSyncTabBadge
                twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                let urlString = remoteTab.URL.absoluteString
                twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: urlString))
                twoLineCell.accessoryView = nil
                cell = twoLineCell
            }
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                let isBookmark = site.bookmarked ?? false
                cell = twoLineCell
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.titleLabel.text = site.title
                twoLineCell.descriptionLabel.text = site.url
                twoLineCell.leftOverlayImageView.image = isBookmark ? self.bookmarkedBadge : nil
                twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
                twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
                twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
                twoLineCell.accessoryView = nil
                cell = twoLineCell
            }
        case .searchHighlights:
            let highlightItem = searchHighlights[indexPath.row]
            let urlString = highlightItem.urlString ?? ""
            let site = Site(url: urlString, title: highlightItem.displayTitle)
            cell = twoLineCell
            twoLineCell.descriptionLabel.isHidden = false
            twoLineCell.titleLabel.text = highlightItem.displayTitle
            twoLineCell.descriptionLabel.text = urlString
            twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
            twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
            twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: site.url))
            twoLineCell.accessoryView = nil
            cell = twoLineCell
        case .firefoxSuggestions:
            let firefoxSuggestion = firefoxSuggestions[indexPath.row]
            twoLineCell.titleLabel.text = firefoxSuggestion.title
            if firefoxSuggestion.isSponsored {
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.descriptionLabel.text = .Search.SponsoredSuggestionDescription
            } else {
                twoLineCell.descriptionLabel.isHidden = true
            }
            twoLineCell.leftOverlayImageView.image = nil
            twoLineCell.leftImageView.contentMode = .scaleAspectFit
            twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
            twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
            twoLineCell.leftImageView.manuallySetImage(firefoxSuggestion.iconImage ?? UIImage())
            twoLineCell.accessoryView = nil
            cell = twoLineCell
        }

        // We need to set the correct theme on the cells when the initial display happens
        oneLineCell.applyTheme(theme: themeManager.currentTheme)
        twoLineCell.applyTheme(theme: themeManager.currentTheme)
        return cell
    }

    private func shouldShowHeader(for section: Int) -> Bool {
        switch section {
        case SearchListSection.remoteTabs.rawValue:
            return hasFirefoxSuggestions
        case SearchListSection.searchSuggestions.rawValue:
            return model.shouldShowSearchSuggestions
        default:
            return false
        }
    }

    func append(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPosition), let newQuery = suggestions?[indexPath.row] {
            searchDelegate?.searchViewController(self, didAppend: newQuery + " ")
            searchQuery = newQuery + " "
        }
    }

    private var searchAppendImage: UIImage? {
        var searchAppendImage = UIImage(named: StandardImageIdentifiers.Large.appendUp)

        if viewModel.isBottomSearchBar, let image = searchAppendImage, let cgImage = image.cgImage {
            searchAppendImage = UIImage(
                cgImage: cgImage,
                scale: image.scale,
                orientation: .downMirrored
            )
        }
        return searchAppendImage
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            dynamicFontChanged(notification)
        case .SearchSettingsChanged:
            reloadSearchEngines()
        default:
            break
        }
    }
}

// MARK: - Telemetry
private extension SearchViewController {
    func recordSearchListSelectionTelemetry(type: SearchListSection, isBookmark: Bool = false) {
        let key = TelemetryWrapper.EventExtraKey.awesomebarSearchTapType.rawValue
        var extra: String
        switch type {
        case .searchSuggestions:
            extra = TelemetryWrapper.EventValue.searchSuggestion.rawValue
        case .remoteTabs:
            extra = TelemetryWrapper.EventValue.remoteTab.rawValue
        case .openedTabs:
            extra = TelemetryWrapper.EventValue.openedTab.rawValue
        case .bookmarksAndHistory:
            extra = isBookmark ? TelemetryWrapper.EventValue.bookmarkItem.rawValue :
                        TelemetryWrapper.EventValue.historyItem.rawValue
        case .searchHighlights:
            extra = TelemetryWrapper.EventValue.searchHighlights.rawValue
        case .firefoxSuggestions:
            return
        }

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .awesomebarResults,
                                     extras: [key: extra])
    }

    func recordFirefoxSuggestSelectionTelemetry(clickInfo: RustFirefoxSuggestionInteractionInfo, position: Int) {
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: TelemetryWrapper.EventObject.fxSuggest,
                                          extras: [
                                            TelemetryWrapper.EventValue.fxSuggestionClickInfo.rawValue: clickInfo,
                                            TelemetryWrapper.EventValue.fxSuggestionPosition.rawValue: position
                                          ])
    }
}

// MARK: - Keyboard shortcuts
extension SearchViewController {
    func handleKeyCommands(sender: UIKeyCommand) {
        let initialSection = SearchListSection.bookmarksAndHistory.rawValue
        guard let current = tableView.indexPathForSelectedRow else {
            let initialSectionCount = tableView(tableView, numberOfRowsInSection: initialSection)
            if sender.input == UIKeyCommand.inputDownArrow, initialSectionCount > 0 {
                let next = IndexPath(item: 0, section: initialSection)
                self.tableView(tableView, didHighlightRowAt: next)
                tableView.selectRow(at: next, animated: false, scrollPosition: .top)
            }
            return
        }

        let nextSection: Int
        let nextItem: Int
        guard let input = sender.input else { return }
        switch input {
        case UIKeyCommand.inputUpArrow:
            // we're going down, we should check if we've reached the first item in this section.
            if current.item == 0 {
                // We have, so check if we can decrement the section.
                if current.section == initialSection {
                    // We've reached the first item in the first section.
                    searchDelegate?.searchViewController(self, didHighlightText: searchQuery, search: false)
                    return
                } else {
                    nextSection = current.section - 1
                    nextItem = tableView(tableView, numberOfRowsInSection: nextSection) - 1
                }
            } else {
                nextSection = current.section
                nextItem = current.item - 1
            }
        case UIKeyCommand.inputDownArrow:
            let currentSectionItemsCount = tableView(tableView, numberOfRowsInSection: current.section)
            if current.item == currentSectionItemsCount - 1 {
                if current.section == tableView.numberOfSections - 1 {
                    // We've reached the last item in the last section
                    return
                } else {
                    // We can go to the next section.
                    guard current.section + 1 < initialSection else { return }
                    nextSection = current.section + 1
                    nextItem = 0
                }
            } else {
                nextSection = current.section
                nextItem = current.item + 1
            }
        default:
            return
        }
        guard nextItem >= 0 else { return }
        let next = IndexPath(item: nextItem, section: nextSection)
        self.tableView(tableView, didHighlightRowAt: next)
        tableView.selectRow(at: next, animated: false, scrollPosition: .middle)
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

/**
 * UIScrollView that prevents buttons from interfering with scroll.
 */
private class ButtonScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
