// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared
import Storage
//Ecosia: import Glean
//Ecosia: import Telemetry

private enum SearchListSection: Int, CaseIterable {
    case searchSuggestions
    // Ecosia: case remoteTabs
    case openedTabs
    case bookmarksAndHistory
    case searchHighlights
}

private struct SearchViewControllerUX {
    static var SearchEngineScrollViewBackgroundColor: CGColor { return UIColor.theme.ecosia.barBackground.withAlphaComponent(0.8).cgColor }
    static let SearchEngineScrollViewBorderColor = UIColor.black.withAlphaComponent(0.2).cgColor

    // TODO: This should use ToolbarHeight in BVC. Fix this when we create a shared theming file.
    static let EngineButtonHeight: Float = 44
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = "search"
    static let SearchAppendImage = "search-append"
    static let SearchEngineTopBorderWidth = 0.5
    static let SuggestionMargin: CGFloat = 8

    static let IconSize: CGFloat = 23
    static let FaviconSize: CGFloat = 29
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5

    static let HeaderHeight: CGFloat = 16
}

protocol SearchViewControllerDelegate: AnyObject {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL, searchTerm: String?)
    func searchViewController(_ searchViewController: SearchViewController, uuid: String)
    func presentSearchSettingsController()
    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool)
    func searchViewController(_ searchViewController: SearchViewController, didAppend text: String)
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

class SearchViewController: SiteTableViewController, KeyboardHelperDelegate, LoaderListener, FeatureFlaggable {
    var searchDelegate: SearchViewControllerDelegate?
    var currentTheme: BuiltinThemeName {
        return BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
    }
    private let viewModel: SearchViewModel
    private var suggestClient: SearchSuggestClient?
    private var remoteClientTabs = [ClientTabsSearchWrapper]()
    private var filteredRemoteClientTabs = [ClientTabsSearchWrapper]()
    private var openedTabs = [Tab]()
    private var filteredOpenedTabs = [Tab]()
    private var tabManager: TabManager
    private var searchHighlights = [HighlightItem]()
    private var highlightManager: HistoryHighlightsManagerProtocol

    // Views for displaying the bottom scrollable search engine list. searchEngineScrollView is the
    // scrollable container; searchEngineScrollViewContent contains the actual set of search engine buttons.
    /* Ecosia: deactivate search engine customization
    private let searchEngineContainerView = UIView()
    private let searchEngineScrollView = ButtonScrollView()
    private let searchEngineScrollViewContent = UIView()
    */

    private lazy var bookmarkedBadge: UIImage = {
        return UIImage(named: "bookmark_results")!
    }()

    private lazy var openAndSyncTabBadge: UIImage = {
        return UIImage(named: "sync_open_tab")!
    }()

    var suggestions: [String]? = []
    var savedQuery: String = ""
    // Ecosia // var searchFeature: FeatureHolder<Search>
    static var userAgent: String?

    var hasFirefoxSuggestions: Bool {
        let dataCount = data.count
        return dataCount != 0
            || !filteredOpenedTabs.isEmpty
            || !filteredRemoteClientTabs.isEmpty
            || !searchHighlights.isEmpty
    }

    var hasAutocompleteSuggestions: Bool {
        let count = suggestions?.count ?? 0
        return count != 0
    }

    init(profile: Profile,
         viewModel: SearchViewModel,
         tabManager: TabManager,
         // Ecosia // featureConfig: FeatureHolder<Search> = FxNimbus.shared.features.search,
         highlightManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager()) {
        self.viewModel = viewModel
        self.tabManager = tabManager
        // Ecosia // self.searchFeature = featureConfig
        self.highlightManager = highlightManager
        super.init(profile: profile, style: .insetGrouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        /* Ecosia: deactivate blur
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blur)
         */

        super.viewDidLoad()
        getCachedTabs()
        KeyboardHelper.defaultHelper.addDelegate(self)

        /* Ecosia: deactivate search engine customization
        searchEngineContainerView.layer.backgroundColor = SearchViewControllerUX.SearchEngineScrollViewBackgroundColor
        searchEngineContainerView.layer.shadowRadius = 0
        searchEngineContainerView.layer.shadowOpacity = 100
        searchEngineContainerView.layer.shadowOffset = CGSize(width: 0, height: -SearchViewControllerUX.SearchEngineTopBorderWidth)
        searchEngineContainerView.layer.shadowColor = SearchViewControllerUX.SearchEngineScrollViewBorderColor
        searchEngineContainerView.clipsToBounds = false

        searchEngineScrollView.decelerationRate = UIScrollView.DecelerationRate.fast
        searchEngineContainerView.addSubview(searchEngineScrollView)
        view.addSubview(searchEngineContainerView)

        searchEngineScrollViewContent.layer.backgroundColor = UIColor.clear.cgColor
        searchEngineScrollView.addSubview(searchEngineScrollViewContent)
        */

        layoutTable()

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.sectionFooterHeight = 0
        
        /* Ecosia: deactivate search engine customization
        layoutSearchEngineScrollView()
        layoutSearchEngineScrollViewContent()
        */

        /* Ecosia: deactivate blur
        blur.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        */
    
        /* Ecosia: deactivate search engine customization
        searchEngineContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        */

        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
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

    func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSearchEngines()
        reloadData()
    }

    /* Ecosia: deactivate search engine customization
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchFeature.recordExposure()
    }

    private func layoutSearchEngineScrollView() {
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(self.view) ?? 0
        searchEngineScrollView.snp.remakeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            if keyboardHeight == 0 {
                make.bottom.equalTo(view.safeArea.bottom)
            } else {
                let offset = viewModel.isBottomSearchBar ? 0 : keyboardHeight
                make.bottom.equalTo(view).offset(-offset)
            }
        }
    }
    */

    private func layoutSearchEngineScrollViewContent() {
        /* Ecosia: remove alternative search
        searchEngineScrollViewContent.snp.remakeConstraints { make in
            make.center.equalTo(self.searchEngineScrollView).priority(10)
            // left-align the engines on iphones, center on ipad
            if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
                make.leading.equalTo(self.searchEngineScrollView).priority(1000)
            } else {
                make.leading.greaterThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            }
            make.trailing.lessThanOrEqualTo(self.searchEngineScrollView).priority(1000)
            make.top.equalTo(self.searchEngineScrollView)
            make.bottom.equalTo(self.searchEngineScrollView)
        }
        */
    }

    var searchEngines: SearchEngines! {
        didSet {
            suggestClient?.cancelPendingRequest()

            // Query and reload the table with new search suggestions.
            querySuggestClient()

            // Show the default search engine first.
            if !viewModel.isPrivate {
                let ua = SearchViewController.userAgent ?? "FxSearch"
                suggestClient = SearchSuggestClient(searchEngine: searchEngines.defaultEngine, userAgent: ua)
            }

            // Reload the footer list of search engines.
            reloadSearchEngines()
        }
    }

    private var quickSearchEngines: [OpenSearchEngine] {
        var engines = searchEngines.quickSearchEngines

        // If we're not showing search suggestions, the default search engine won't be visible
        // at the top of the table. Show it with the others in the bottom search bar.
        if viewModel.isPrivate || !searchEngines.shouldShowSearchSuggestions {
            engines?.insert(searchEngines.defaultEngine, at: 0)
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
        tableView.contentInsetAdjustmentBehavior = .scrollableAxes
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func reloadSearchEngines() {
        /* Ecosia: deactivate search engine customization
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.snp.leading

        // search settings icon
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "quickSearch"), for: [])
        searchButton.imageView?.contentMode = .center
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.addTarget(self, action: #selector(didClickSearchButton), for: .touchUpInside)
        searchButton.accessibilityLabel = String(format: .SearchSettingsAccessibilityLabel)

        searchEngineScrollViewContent.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.size.equalTo(SearchViewControllerUX.FaviconSize)
            // offset the left edge to align with search results
            make.leading.equalTo(leftEdge).offset(SearchViewControllerUX.SuggestionMargin * 2)
            make.top.equalTo(self.searchEngineScrollViewContent).offset(SearchViewControllerUX.SuggestionMargin)
            make.bottom.equalTo(self.searchEngineScrollViewContent).offset(-SearchViewControllerUX.SuggestionMargin)
        }

        // search engines
        leftEdge = searchButton.snp.trailing

        for engine in quickSearchEngines {
            let engineButton = UIButton()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.imageView?.layer.cornerRadius = 4
            engineButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
            engineButton.addTarget(self, action: #selector(didSelectEngine), for: .touchUpInside)
            engineButton.accessibilityLabel = String(format: .SearchSearchEngineAccessibilityLabel, engine.shortName)

            engineButton.imageView?.snp.makeConstraints { make in
                make.width.height.equalTo(SearchViewControllerUX.FaviconSize)
                return
            }

            searchEngineScrollViewContent.addSubview(engineButton)
            engineButton.snp.makeConstraints { make in
                make.width.equalTo(SearchViewControllerUX.EngineButtonWidth)
                make.height.equalTo(SearchViewControllerUX.EngineButtonHeight)
                make.leading.equalTo(leftEdge)
                make.top.equalTo(self.searchEngineScrollViewContent)
                make.bottom.equalTo(self.searchEngineScrollViewContent)
                if engine === self.searchEngines.quickSearchEngines.last {
                    make.trailing.equalTo(self.searchEngineScrollViewContent)
                }
            }
            leftEdge = engineButton.snp.trailing
        }
        */
    }

    func didSelectEngine(_ sender: UIButton) {
        /* Ecosia: deactivate search engine customization
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

        Telemetry.default.recordSearch(location: .quickSearch, searchEngine: engine.engineID ?? "other")
        GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.quickSearch.rawValue)"].add()

        searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: "")
        */
    }

    func didClickSearchButton() {
        self.searchDelegate?.presentSearchSettingsController()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        animateSearchEnginesWithKeyboard(state)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillChangeWithState state: KeyboardState) {
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
        /* Ecosia: remove search customization
        layoutSearchEngineScrollView()

        UIView.animate(
            withDuration: keyboardState.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(keyboardState.animationCurve.rawValue << 16))],
            animations: {
                self.view.layoutIfNeeded()
            })
         */
    }

    private func getCachedTabs() {
        assert(Thread.isMainThread)
        // Short circuit if the user is not logged in
        guard profile.hasSyncableAccount() else { return }
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
        /* Ecosia: hardcode config
        let config = searchFeature.value().awesomeBar
        // Searching within the content will get annoying, so only start searching
        // in content when there are at least one word with more than 3 letters in.

        let searchInContent = config.usePageContent
            && searchTerms.find { $0.count >= config.minSearchTerm } != nil
         */
        let searchInContent = searchTerms.find { $0.count >= 3 } != nil


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
        for remoteClientTab in remoteClientTabs {
            if remoteClientTab.tab.title.lowercased().contains(searchQuery) {
                filteredRemoteClientTabs.append(remoteClientTab)
            }
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

        if searchQuery.isEmpty || !searchEngines.shouldShowSearchSuggestions || searchQuery.looksLikeAURL() {
            suggestions = []
            tableView.reloadData()
            return
        }

        loadSearchHighlights()

        let tempSearchQuery = searchQuery
        suggestClient?.query(searchQuery, callback: { suggestions, error in
            if let error = error {
                let isSuggestClientError = error.domain == SearchSuggestClientErrorDomain

                switch error.code {
                case NSURLErrorCancelled where error.domain == NSURLErrorDomain:
                    // Request was cancelled. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidEngine where isSuggestClientError:
                    // Engine does not support search suggestions. Do nothing.
                    break
                case SearchSuggestClientErrorInvalidResponse where isSuggestClientError:
                    print("Error: Invalid search suggestion data")
                default:
                    print("Error: \(error.description)")
                }
            } else {
                self.suggestions = suggestions!
                // Remove user searching term inside suggestions list
                self.suggestions?.removeAll(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == self.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) })
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
            // Assume that only the default search engine can provide search suggestions.
            let engine = searchEngines.defaultEngine
            guard let suggestions = suggestions else { return }
            guard let suggestion = suggestions[safe: indexPath.row] else { return }
            if let url = engine.searchURLForQuery(suggestion) {
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: suggestion)
            }
        case .openedTabs:
            guard let tab = self.filteredOpenedTabs[safe: indexPath.row] else { return }
            searchDelegate?.searchViewController(self, uuid: tab.tabUUID)
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                if let url = URL(string: site.url) {
                    searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
                }
            }
        case .searchHighlights:
            if let url = searchHighlights[safe: indexPath.row]?.siteUrl {
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            return hasAutocompleteSuggestions ? UITableView.automaticDimension : 0
        case .openedTabs:
            return filteredOpenedTabs.isEmpty ? 0 : SearchViewControllerUX.HeaderHeight
        case .bookmarksAndHistory:
            return data.count == 0 ? 0 : SearchViewControllerUX.HeaderHeight
        case .searchHighlights:
            return searchHighlights.isEmpty ? 0 : SearchViewControllerUX.HeaderHeight
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == SearchListSection.searchSuggestions.rawValue,
              hasAutocompleteSuggestions,
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderIdentifier) as?
                SiteTableViewHeader
        else { return nil }

        headerView.titleLabel.text = "Ecosia search".uppercased()
        return headerView
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let twoLineImageOverlayCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! TwoLineImageOverlayCell
        let oneLineTableViewCell = tableView.dequeueReusableCell(withIdentifier: OneLineCellIdentifier, for: indexPath) as! OneLineTableViewCell
        return getCellForSection(twoLineImageOverlayCell, oneLineCell: oneLineTableViewCell, for: SearchListSection(rawValue: indexPath.section)!, indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .theme.ecosia.ntpImpactBackground
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            guard let count = suggestions?.count else { return 0 }
            return count < 4 ? count : 4
        case .openedTabs:
            return filteredOpenedTabs.count
        case .bookmarksAndHistory:
            return data.count
        case .searchHighlights:
            return searchHighlights.count
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
        view.backgroundColor = .theme.ecosia.ntpBackground
        tableView.backgroundColor = .theme.ecosia.ntpBackground
        reloadData()
    }

    func getAttributedBoldSearchSuggestions(searchPhrase: String, query: String) -> NSAttributedString {
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: DynamicFontHelper().DefaultStandardFont.pointSize)]
        let regularAttributes = [NSAttributedString.Key.font: DynamicFontHelper().DefaultStandardFont]
        let attributedString = NSMutableAttributedString(string: "", attributes: regularAttributes)
        let phraseString = NSAttributedString(string: searchPhrase, attributes: regularAttributes)
        let suggestion = searchPhrase.components(separatedBy: query)
        guard searchPhrase != query, suggestion.count > 1 else { return phraseString }
        // split suggestion into searchQuery and suggested part
        let searchString = NSAttributedString(string: query, attributes: regularAttributes)
        let restOfSuggestion = NSAttributedString(string: suggestion[1], attributes: boldAttributes)
        attributedString.append(searchString)
        attributedString.append(restOfSuggestion)
        return attributedString
    }

    private func getCellForSection(_ twoLineCell: TwoLineImageOverlayCell, oneLineCell: OneLineTableViewCell, for section: SearchListSection, _ indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        switch section {
        case .searchSuggestions:
            if let site = suggestions?[indexPath.row] {
                oneLineCell.titleLabel.text = site
                if Locale.current.languageCode == "en" {
                    oneLineCell.titleLabel.attributedText = getAttributedBoldSearchSuggestions(searchPhrase: site, query: savedQuery)
                }
                oneLineCell.leftImageView.contentMode = .center
                oneLineCell.leftImageView.layer.borderWidth = 0
                oneLineCell.leftImageView.image = UIImage(named: SearchViewControllerUX.SearchImage)
                oneLineCell.leftImageView.tintColor = UIColor.theme.ecosia.primaryButton
                oneLineCell.leftImageView.backgroundColor = nil
                let appendButton = UIButton(type: .roundedRect)
                appendButton.setImage(searchAppendImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                appendButton.addTarget(self, action: #selector(append(_ :)), for: .touchUpInside)
                appendButton.tintColor = UIColor.theme.ecosia.secondaryText
                appendButton.sizeToFit()
                oneLineCell.accessoryView = indexPath.row > 0 ? appendButton : nil
                oneLineCell.backgroundColor = UIColor.theme.ecosia.autocompleteBackground
                cell = oneLineCell
            }
        case .openedTabs:
            if self.filteredOpenedTabs.count > indexPath.row {
                let openedTab = self.filteredOpenedTabs[indexPath.row]
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.titleLabel.text = openedTab.title ?? openedTab.lastTitle
                twoLineCell.descriptionLabel.text = String.SearchSuggestionCellSwitchToTabLabel
                twoLineCell.leftImageView.contentMode = .center
                twoLineCell.leftImageView.image = .init(named: "switchTab")
                twoLineCell.leftImageView.tintColor = .theme.ecosia.secondaryText
                twoLineCell.backgroundColor = UIColor.theme.ecosia.autocompleteBackground
                cell = twoLineCell
            }
        case .bookmarksAndHistory:
            if let site = data[indexPath.row] {
                let isBookmark = site.bookmarked ?? false
                cell = twoLineCell
                twoLineCell.descriptionLabel.isHidden = false
                twoLineCell.titleLabel.text = site.title
                twoLineCell.descriptionLabel.text = site.url
                twoLineCell.backgroundColor = UIColor.theme.ecosia.autocompleteBackground
                twoLineCell.accessoryView = nil
                let imageName = isBookmark ? "bookmarksEmpty" : "libraryHistory"
                twoLineCell.leftImageView.contentMode = .center
                twoLineCell.leftImageView.image = .init(named: imageName)
                twoLineCell.leftImageView.tintColor = .theme.ecosia.secondaryText
                cell = twoLineCell
            }
        case .searchHighlights:
            let highlightItem = searchHighlights[indexPath.row]
            let urlString = highlightItem.siteUrl?.absoluteString ?? ""
            let site = Site(url: urlString, title: highlightItem.displayTitle)
            cell = twoLineCell
            twoLineCell.descriptionLabel.isHidden = false
            twoLineCell.titleLabel.text = highlightItem.displayTitle
            twoLineCell.descriptionLabel.text = urlString
            twoLineCell.leftImageView.contentMode = .center
            profile.favicons.getFaviconImage(forSite: site).uponQueue(.main) {
                [weak twoLineCell] result in
                // Check that we successfully retrieved an image (should always happen)
                // and ensure that the cell we were fetching for is still on-screen.
                guard let image = result.successValue else { return }
                twoLineCell?.leftImageView.image = image
                twoLineCell?.leftImageView.image = twoLineCell?.leftImageView.image?.createScaled(CGSize(width: SearchViewControllerUX.IconSize, height: SearchViewControllerUX.IconSize))
            }
            twoLineCell.accessoryView = nil
            cell = twoLineCell
        }
        return cell
    }

    func append(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPosition), let newQuery = suggestions?[indexPath.row] {
            searchDelegate?.searchViewController(self, didAppend: newQuery + " ")
            searchQuery = newQuery + " "
        }
    }

    private var searchAppendImage: UIImage? {
        let searchAppendImage = UIImage(named: SearchViewControllerUX.SearchAppendImage)

        /* Ecosia: always point arrow up
        if viewModel.isBottomSearchBar, let image = searchAppendImage, let cgImage = image.cgImage {
            searchAppendImage = UIImage(
                cgImage: cgImage,
                scale: image.scale,
                orientation: .downMirrored
            )
        }
         */
        return searchAppendImage
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
