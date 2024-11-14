// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import Common
import SiteImageView

private struct SearchViewControllerUX {
    static let EngineButtonHeight: Float = 44 // Equivalent to toolbar height, fixed at the moment
    static let EngineButtonWidth = EngineButtonHeight * 1.4
    static let EngineButtonBackgroundColor = UIColor.clear.cgColor

    static let SearchImage = StandardImageIdentifiers.Large.search
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
    func searchViewControllerWillHide(_ searchViewController: SearchViewController)
}

class SearchViewController: SiteTableViewController,
                            KeyboardHelperDelegate,
                            SearchViewDelegate,
                            FeatureFlaggable,
                            Notifiable {
    typealias ExtraKey = TelemetryWrapper.EventExtraKey

    var searchDelegate: SearchViewControllerDelegate?
    let viewModel: SearchViewModel
    private var tabManager: TabManager
    private let logger: Logger

    var searchTelemetry: SearchTelemetry?

    private var selectedIndexPath: IndexPath?

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
        return UIImage(named: ImageIdentifiers.syncOpenTab)!
    }()

    private lazy var searchButton: UIButton = .build { button in
        let image = UIImage(named: StandardImageIdentifiers.Large.search)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.didClickSearchButton), for: .touchUpInside)
        button.accessibilityLabel = String(format: .SearchSettingsAccessibilityLabel)
    }

    init(profile: Profile,
         viewModel: SearchViewModel,
         tabManager: TabManager,
         highlightManager: HistoryHighlightsManagerProtocol = HistoryHighlightsManager(),
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = viewModel
        self.tabManager = tabManager
        self.searchTelemetry = SearchTelemetry(tabManager: tabManager)
        self.logger = logger
        super.init(profile: profile, windowUUID: tabManager.windowUUID)
        viewModel.delegate = self

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
                                                          .SearchSettingsChanged,
                                                          .SponsoredAndNonSponsoredSuggestionsChanged])
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
        viewModel.searchFeature.recordExposure()

        searchTelemetry?.startImpressionTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchDelegate?.searchViewControllerWillHide(self)
        searchTelemetry?.stopImpressionTimer()
        super.viewWillDisappear(animated)
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

    /// Information to record in telemetry for the currently visible
    /// suggestions.
    var visibleSuggestionsTelemetryInfo: [SearchViewVisibleSuggestionTelemetryInfo] {
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        return visibleIndexPaths.enumerated().compactMap { (position, indexPath) in
            switch SearchListSection(rawValue: indexPath.section)! {
            case .firefoxSuggestions:
                let firefoxSuggestion = viewModel.firefoxSuggestions[safe: indexPath.row]
                guard let telemetryInfo = firefoxSuggestion?.telemetryInfo else {
                    return nil
                }
                return .firefoxSuggestion(
                    telemetryInfo,
                    position: position + 1,
                    didTap: indexPath == selectedIndexPath
                )

            default:
                return nil
            }
        }
    }

    override func reloadData() {
        viewModel.querySuggestClient()
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

    // MARK: SearchViewDelegate
    var searchData: Cursor<Site> {
        get { data }
        set { data = newValue }
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    func reloadSearchEngines() {
        searchEngineScrollViewContent.subviews.forEach { $0.removeFromSuperview() }
        var leftEdge = searchEngineScrollViewContent.leadingAnchor

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

        for engine in viewModel.quickSearchEngines {
            let engineButton: UIButton = .build()
            engineButton.setImage(engine.image, for: [])
            engineButton.imageView?.contentMode = .scaleAspectFit
            engineButton.imageView?.translatesAutoresizingMaskIntoConstraints = false
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

            if engine === self.viewModel.searchEnginesManager?.quickSearchEngines.last {
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

        let engine = viewModel.quickSearchEngines[index - 1]

        guard let url = engine.searchURLForQuery(viewModel.searchQuery) else {
            assertionFailure()
            return
        }

        let extras = [
            ExtraKey.recordSearchLocation.rawValue: SearchLocation.quickSearch,
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
        coordinator.animate(alongsideTransition: { [self] _ in
            tableView.reloadData()
            layoutSearchEngineScrollViewContent()
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
                self.viewModel.remoteClientTabs.removeAll()
                // Update UI with cached data.
                clientAndTabs.forEach { value in
                    value.tabs.forEach { (tab) in
                        self.viewModel.remoteClientTabs.append(ClientTabsSearchWrapper(client: value.client, tab: tab))
                    }
                }
            }
        }
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchTelemetry?.engagementType = .tap
        switch SearchListSection(rawValue: indexPath.section)! {
        case .searchSuggestions:
            guard let defaultEngine = viewModel.searchEnginesManager?.defaultEngine else { return }

            searchTelemetry?.selectedResult = .searchSuggest
            // Assume that only the default search engine can provide search suggestions.
            guard let suggestions = viewModel.suggestions,
                  let suggestion = suggestions[safe: indexPath.row],
                  let url = defaultEngine.searchURLForQuery(suggestion)
            else { return }

            let extras = [
                ExtraKey.recordSearchLocation.rawValue: SearchLocation.suggestion,
                ExtraKey.recordSearchEngineID.rawValue: defaultEngine.engineID as Any
            ] as [String: Any]
            TelemetryWrapper.gleanRecordEvent(category: .action,
                                              method: .tap,
                                              object: .recordSearch,
                                              extras: extras)
            selectedIndexPath = indexPath
            searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: suggestion)
        case .openedTabs:
            searchTelemetry?.selectedResult = .tab
            let tab = viewModel.filteredOpenedTabs[indexPath.row]
            selectedIndexPath = indexPath
            searchDelegate?.searchViewController(self, uuid: tab.tabUUID)
        case .remoteTabs:
            searchTelemetry?.selectedResult = .remoteTab
            let remoteTab = viewModel.filteredRemoteClientTabs[indexPath.row].tab
            selectedIndexPath = indexPath
            searchDelegate?.searchViewController(self, didSelectURL: remoteTab.URL, searchTerm: nil)
        case .history:
            let site = viewModel.historySites[indexPath.row]
            searchTelemetry?.selectedResult = .history
            if let url = URL(string: site.url, invalidCharacters: false) {
                selectedIndexPath = indexPath
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
            }
        case .bookmarks:
            let site = viewModel.bookmarkSites[indexPath.row]
            searchTelemetry?.selectedResult = .bookmark
            if let url = URL(string: site.url, invalidCharacters: false) {
                selectedIndexPath = indexPath
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
            }
        case .searchHighlights:
            if let urlString = viewModel.searchHighlights[indexPath.row].urlString,
                let url = URL(string: urlString, invalidCharacters: false) {
                searchTelemetry?.selectedResult = .searchHistory
                selectedIndexPath = indexPath
                searchDelegate?.searchViewController(self, didSelectURL: url, searchTerm: nil)
            }
        case .firefoxSuggestions:
            let firefoxSuggestion = viewModel.firefoxSuggestions[indexPath.row]
            searchTelemetry?.selectedResult = firefoxSuggestion.isSponsored ? .suggestSponsor : .suggestNonSponsor
            selectedIndexPath = indexPath
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
        guard viewModel.shouldShowHeader(for: section) else { return 0 }

        return UITableView.automaticDimension
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    override func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard viewModel.shouldShowHeader(for: section),
              let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: SiteTableViewHeader.cellIdentifier) as? SiteTableViewHeader
        else { return nil }

        var title: String
        switch section {
        case SearchListSection.firefoxSuggestions.rawValue:
            title = .Search.SuggestSectionTitle
        case SearchListSection.searchSuggestions.rawValue:
            title = viewModel.searchEnginesManager?.defaultEngine?.headerSearchTitle ?? ""
        default:  title = ""
        }

        let viewModel = SiteTableViewHeaderModel(title: title,
                                                 isCollapsible: false,
                                                 collapsibleState: nil)
        headerView.configure(viewModel)
        headerView.applyTheme(theme: currentTheme())
        return headerView
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let twoLineImageOverlayCell = tableView.dequeueReusableCell(
            withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
            for: indexPath
        ) as? TwoLineImageOverlayCell else {
            logger.log("Failed to dequeue TwoLineImageOverlayCell at indexPath: \(indexPath)",
                       level: .fatal,
                       category: .lifecycle)
            return UITableViewCell()
        }
        guard let oneLineTableViewCell = tableView.dequeueReusableCell(
            withIdentifier: OneLineTableViewCell.cellIdentifier,
            for: indexPath
        ) as? OneLineTableViewCell else {
            logger.log("Failed to dequeue OneLineTableViewCell at indexPath: \(indexPath)",
                       level: .fatal,
                       category: .lifecycle)
            return UITableViewCell()
        }
        return getCellForSection(twoLineImageOverlayCell,
                                 oneLineCell: oneLineTableViewCell,
                                 for: SearchListSection(rawValue: indexPath.section)!,
                                 indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let section = SearchListSection(rawValue: indexPath.section) {
            switch section {
            case .searchSuggestions:
                if let site = viewModel.suggestions?[indexPath.row] {
                    if searchTelemetry?.visibleSuggestions.contains(site) == false {
                        searchTelemetry?.visibleSuggestions.append(site)
                    }
                }
            case .openedTabs:
                if viewModel.filteredOpenedTabs.count > indexPath.row {
                    let openedTab = viewModel.filteredOpenedTabs[indexPath.row]
                    if searchTelemetry?.visibleFilteredOpenedTabs.contains(openedTab) == false {
                        searchTelemetry?.visibleFilteredOpenedTabs.append(openedTab)
                    }
                }
            case .remoteTabs:
                if viewModel.filteredRemoteClientTabs.count > indexPath.row {
                    let remoteTab = viewModel.filteredRemoteClientTabs[indexPath.row]
                    if searchTelemetry?.visibleFilteredRemoteClientTabs.contains(where: { $0 == remoteTab }) == false {
                        searchTelemetry?.visibleFilteredRemoteClientTabs.append(remoteTab)
                    }
                }
            case .history:
                if viewModel.shouldShowBrowsingHistorySuggestions {
                    let site = viewModel.historySites[indexPath.row]
                    if searchTelemetry?.visibleData.contains(site) == false {
                        searchTelemetry?.visibleData.append(site)
                    }
                }
            case .bookmarks:
                if viewModel.shouldShowBookmarksSuggestions {
                    let site = viewModel.bookmarkSites[indexPath.row]
                    if searchTelemetry?.visibleData.contains(site) == false {
                        searchTelemetry?.visibleData.append(site)
                    }
                }
            case .searchHighlights:
                let highlightItem = viewModel.searchHighlights[indexPath.row]
                if searchTelemetry?.visibleSearchHighlights.contains(
                    where: { $0.urlString == highlightItem.urlString }
                ) == false {
                    searchTelemetry?.visibleSearchHighlights.append(highlightItem)
                }
            case .firefoxSuggestions:
                if featureFlags.isFeatureEnabled(.firefoxSuggestFeature, checking: .buildAndUser) {
                    let firefoxSuggestion = viewModel.firefoxSuggestions[indexPath.row]
                    if searchTelemetry?.visibleFirefoxSuggestions
                        .contains(where: { $0.url == firefoxSuggestion.url }) == false {
                        searchTelemetry?.visibleFirefoxSuggestions.append(firefoxSuggestion)
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SearchListSection(rawValue: section)! {
        case .searchSuggestions:
            guard let count = viewModel.suggestions?.count else { return 0 }
            return count < 4 ? count : 4
        case .openedTabs:
            return viewModel.filteredOpenedTabs.count
        case .remoteTabs:
            return viewModel.shouldShowSyncedTabsSuggestions ? viewModel.filteredRemoteClientTabs.count : 0
        case .history:
            return viewModel.shouldShowBrowsingHistorySuggestions ? viewModel.historySites.count : 0
        case .bookmarks:
            return viewModel.shouldShowBookmarksSuggestions ? viewModel.bookmarkSites.count : 0
        case .searchHighlights:
            return viewModel.searchHighlights.count
        case .firefoxSuggestions:
            return viewModel.firefoxSuggestions.count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return SearchListSection.allCases.count
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let section = SearchListSection(rawValue: indexPath.section) else { return }

        switch section {
        case .bookmarks:
            let suggestion = viewModel.bookmarkSites[indexPath.item]
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        case .history:
            let suggestion = viewModel.historySites[indexPath.item]
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url, search: false)
        case .searchSuggestions:
            guard let suggestion = viewModel.suggestions?[indexPath.item] else { return }
            searchDelegate?.searchViewController(self, didHighlightText: suggestion, search: false)
        case .remoteTabs:
            let suggestion = viewModel.remoteClientTabs[indexPath.item]
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.tab.URL.absoluteString, search: false)
        case .firefoxSuggestions:
            let suggestion = viewModel.firefoxSuggestions[indexPath.item]
            searchDelegate?.searchViewController(self, didHighlightText: suggestion.url.absoluteString, search: false)
        default: return
        }
    }

    override func applyTheme() {
        super.applyTheme()
        view.backgroundColor = currentTheme().colors.layer5

        // search settings icon
        searchButton.layer.backgroundColor = SearchViewControllerUX.EngineButtonBackgroundColor
        searchButton.tintColor = currentTheme().colors.iconPrimary

        searchEngineContainerView.layer.backgroundColor = currentTheme().colors.layer1.cgColor
        searchEngineContainerView.layer.shadowColor = currentTheme().colors.shadowDefault.cgColor
        reloadData()
    }

    func getAttributedBoldSearchSuggestions(searchPhrase: String, query: String) -> NSAttributedString? {
        // the search term (query) stays normal weight
        // everything past the search term (query) will be bold
        let range = searchPhrase.range(of: query)
        guard searchPhrase != query, let upperBound = range?.upperBound else { return nil }

        let attributedString = searchPhrase.attributedText(
            boldIn: upperBound..<searchPhrase.endIndex,
            font: FXFontStyles.Regular.body.scaledFont()
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
            if let site = viewModel.suggestions?[indexPath.row] {
                oneLineCell.titleLabel.text = site
                if Locale.current.languageCode == "en",
                   let attributedString = getAttributedBoldSearchSuggestions(
                    searchPhrase: site,
                    query: viewModel.savedQuery
                   ) {
                    oneLineCell.titleLabel.attributedText = attributedString
                }
                oneLineCell.leftImageView.contentMode = .center
                oneLineCell.leftImageView.layer.borderWidth = 0
                oneLineCell.leftImageView.manuallySetImage(
                    UIImage(named: SearchViewControllerUX.SearchImage)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
                )
                oneLineCell.leftImageView.tintColor = currentTheme().colors.iconPrimary
                oneLineCell.leftImageView.backgroundColor = nil
                let appendButton = UIButton(type: .roundedRect)
                appendButton.setImage(searchAppendImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                appendButton.addTarget(self, action: #selector(append(_ :)), for: .touchUpInside)
                appendButton.tintColor = currentTheme().colors.iconPrimary
                appendButton.sizeToFit()
                oneLineCell.accessoryView = indexPath.row > 0 ? appendButton : nil
                cell = oneLineCell
            }
        case .openedTabs:
            if viewModel.filteredOpenedTabs.count > indexPath.row {
                let openedTab = viewModel.filteredOpenedTabs[indexPath.row]
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
            if viewModel.shouldShowSyncedTabsSuggestions,
               viewModel.filteredRemoteClientTabs.count > indexPath.row {
                let remoteTab = viewModel.filteredRemoteClientTabs[indexPath.row].tab
                let remoteClient = viewModel.filteredRemoteClientTabs[indexPath.row].client
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
        case .history:
            if viewModel.shouldShowBrowsingHistorySuggestions {
                let site = viewModel.historySites[indexPath.row]
                configureBookmarksAndHistoryCell(
                    twoLineCell,
                    site.title,
                    site.url
                )
                cell = twoLineCell
            }

        case .bookmarks:
            if viewModel.shouldShowBookmarksSuggestions {
                let site = viewModel.bookmarkSites[indexPath.row]
                configureBookmarksAndHistoryCell(
                    twoLineCell,
                    site.title,
                    site.url,
                    site.bookmarked ?? false
                )
                cell = twoLineCell
            }

        case .searchHighlights:
            let highlightItem = SearchHighlightItem(highlightItem: viewModel.searchHighlights[indexPath.row])
            twoLineCell.descriptionLabel.isHidden = false
            twoLineCell.titleLabel.text = highlightItem.displayTitle
            twoLineCell.descriptionLabel.text = highlightItem.urlString
            twoLineCell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
            twoLineCell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
            twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: highlightItem.siteURL))
            twoLineCell.accessoryView = nil
            cell = twoLineCell
        case .firefoxSuggestions:
            let firefoxSuggestion = viewModel.firefoxSuggestions[indexPath.row]
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
        oneLineCell.applyTheme(theme: currentTheme())
        twoLineCell.applyTheme(theme: currentTheme())
        return cell
    }

    private func configureBookmarksAndHistoryCell(
        _ cell: TwoLineImageOverlayCell,
        _ title: String,
        _ description: String,
        _ isBookmark: Bool = false
    ) {
        cell.descriptionLabel.isHidden = false
        cell.titleLabel.text = title
        cell.descriptionLabel.text = description
        cell.leftOverlayImageView.image = isBookmark ? bookmarkedBadge : nil
        cell.leftImageView.layer.borderColor = SearchViewControllerUX.IconBorderColor.cgColor
        cell.leftImageView.layer.borderWidth = SearchViewControllerUX.IconBorderWidth
        cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: description))
        cell.accessoryView = nil
    }

    func append(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to: tableView)
        if let indexPath = tableView.indexPathForRow(
            at: buttonPosition
        ), let newQuery = viewModel.suggestions?[indexPath.row] {
            searchDelegate?.searchViewController(self, didAppend: newQuery + " ")
            viewModel.searchQuery = newQuery + " "
            searchTelemetry?.searchQuery = viewModel.searchQuery
        }
    }

    private var searchAppendImage: UIImage? {
        var searchAppendImage = UIImage(named: StandardImageIdentifiers.Large.appendUpLeft)
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
        case .SponsoredAndNonSponsoredSuggestionsChanged:
            guard !viewModel.searchQuery.isEmpty else { return }
            _ = viewModel.loadFirefoxSuggestions()
        default:
            break
        }
    }

    // MARK: - Internal Utilities

    private func firstNonEmptySection(before: Int? = nil, after: Int? = nil) -> Int? {
        let allSections = SearchListSection.allCases
        let sectionsOrdered = before != nil ? allSections.reversed() : allSections
        for section in sectionsOrdered {
            let sectionValue = section.rawValue
            guard before == nil || sectionValue < before! else { continue }
            guard after == nil || sectionValue > after! else { continue }
            guard tableView(tableView, numberOfRowsInSection: sectionValue) > 0 else { continue }
            return sectionValue
        }
        return nil
    }
}

// MARK: - Keyboard shortcuts
extension SearchViewController {
    func handleKeyCommands(sender: UIKeyCommand) {
        let initialSection: Int = firstNonEmptySection() ?? 0
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
                    searchDelegate?.searchViewController(self, didHighlightText: viewModel.searchQuery, search: false)
                    return
                } else {
                    let currentSection = current.section
                    guard let next = firstNonEmptySection(before: currentSection) else { return }
                    nextSection = next
                    nextItem = tableView(tableView, numberOfRowsInSection: next) - 1
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
                    let currentSection = current.section
                    guard let next = firstNonEmptySection(after: currentSection) else { return }
                    nextSection = next
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
 * UIScrollView that prevents buttons from interfering with scroll.
 */
private class ButtonScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
}
