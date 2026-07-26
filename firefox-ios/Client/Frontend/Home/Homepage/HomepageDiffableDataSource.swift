// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebKit

typealias HomepageSection = HomepageDiffableDataSource.HomeSection
typealias HomepageItem = HomepageDiffableDataSource.HomeItem

/// Holds the data source configuration for the new homepage as part of the rebuild project
final class HomepageDiffableDataSource: UICollectionViewDiffableDataSource<HomepageSection, HomepageItem> {
    typealias TextColor = UIColor
    typealias NumberOfTilesPerRow = Int
    typealias ShouldShowSectionHeader = Bool
    typealias ShowiPadSetup = Bool

    private struct TopSitesSnapshotData {
        let items: [HomeItem]
        let numberOfTilesPerRow: NumberOfTilesPerRow
        let shouldShowSectionHeader: ShouldShowSectionHeader
    }

    enum HomeSection: Hashable {
        case privacyNotice
        case header
        case messageCard
        case topSites(TextColor?, NumberOfTilesPerRow, ShouldShowSectionHeader)
        case widgets
        case searchBar
        case jumpBackIn(TextColor?, JumpBackInSectionLayoutConfiguration)
        case trackerBlockerModule
        case bookmarks(TextColor?)
        case pocket(TextColor?)
        case worldcup
        case spacer

        var canHandleLongPress: Bool {
            switch self {
            case .topSites, .jumpBackIn, .bookmarks, .pocket:
                return true
            default:
                return false
            }
        }
    }

    enum HomeItem: Hashable, Sendable {
        case header(HeaderState, TextColor?, ShowiPadSetup)
        case privacyNotice
        case messageCard(MessageCardConfiguration)
        case topSite(TopSiteConfiguration, TextColor?)
        case addShortcutTile(TextColor?)
        case topSiteEmpty
        case searchBar
        case jumpBackIn(JumpBackInTabConfiguration)
        case jumpBackInSyncedTab(JumpBackInSyncedTabConfiguration)
        case trackerBlockerModule(Int)
        case bookmark(BookmarkConfiguration)
        /// FXIOS-15423: Include the selected category in the item's identity so category transitions are treated as
        /// a presentation-context change. Without the category context, diffable treats the same story in
        /// a filtered feed and in the full "All" feed as one continuous item, which causes it to preserve
        /// that story's on-screen position as stories are inserted above it.
        case merino(MerinoStoryConfiguration, String?)
        case worldcupCard
        case widget(URL)
        case spacer

        static var cellTypes: [ReusableCell.Type] {
            return [
                HomepageHeaderCell.self,
                PrivacyNoticeCell.self,
                HomepageMessageCardCell.self,
                TopSiteCell.self,
                EmptyTopSiteCell.self,
                SearchBarCell.self,
                JumpBackInCell.self,
                SyncedTabCell.self,
                TrackerBlockerModuleCell.self,
                BookmarksCell.self,
                StoryCell.self,
                WorldCupCell.self,
                WidgetsCell.self,
                HomepageSpacerCell.self
            ]
        }

        var telemetryItemType: HomepageTelemetry.ItemType? {
            switch self {
            case .topSite:
                return .topSite
            case .jumpBackIn:
                return .jumpBackInTab
            case .jumpBackInSyncedTab:
                return .jumpBackInSyncedTab
            case .bookmark:
                return .bookmark
            case .merino:
                return .story
            case .worldcupCard:
                return .worldCupWidget
            default:
                return nil
            }
        }

        var canHandleLongPress: Bool {
            switch self {
            case .addShortcutTile:
                return false
            default:
                return true
            }
        }
    }

    func updateSnapshot(
        state: HomepageState,
        selectedNewsfeedCategoryID: String? = nil,
        jumpBackInDisplayConfig: JumpBackInSectionLayoutConfiguration,
        showiPadSetup: ShowiPadSetup = false,
        animatingDifferences: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        let textColor = state.wallpaperState.wallpaperConfiguration.textColor
        let headerItem = HomeItem.header(state.headerState,
                                         state.wallpaperState.wallpaperConfiguration.logoTextColor,
                                         showiPadSetup)

        snapshot.appendSections([.header])
        snapshot.appendItems([headerItem], toSection: .header)

        if state.shouldShowPrivacyNotice {
            snapshot.appendSections([.privacyNotice])
            snapshot.appendItems([.privacyNotice], toSection: .privacyNotice)
        }

        if let configuration = state.messageState.messageCardConfiguration {
            snapshot.appendSections([.messageCard])
            snapshot.appendItems([.messageCard(configuration)], toSection: .messageCard)
        }

        if let topSitesSnapshotData = getTopSites(with: state.topSitesState, and: textColor) {
            let topSitesSection = HomeSection.topSites(
                textColor,
                topSitesSnapshotData.numberOfTilesPerRow,
                topSitesSnapshotData.shouldShowSectionHeader
            )
            snapshot.appendSections([topSitesSection])
            snapshot.appendItems(topSitesSnapshotData.items, toSection: topSitesSection)
        }

        if state.widgetsState.shouldShowSection, let widgetURL = state.widgetsState.widgetURL {
            snapshot.appendSections([.widgets])
            snapshot.appendItems([.widget(widgetURL)], toSection: .widgets)
        }

        if state.worldcupState.shouldShowSection {
            snapshot.appendSections([.worldcup])
            snapshot.appendItems(
                [.worldcupCard],
                toSection: .worldcup
            )
            snapshot.reconfigureItems([.worldcupCard])
        }

        if state.trackerBlockerModuleState.shouldShowSection {
            snapshot.appendSections([.trackerBlockerModule])
            snapshot.appendItems(
                [.trackerBlockerModule(state.trackerBlockerModuleState.blockedTrackerCount)],
                toSection: .trackerBlockerModule
            )
        }

        if let (tabs, configuration) = getJumpBackInTabs(with: state.jumpBackInState, and: jumpBackInDisplayConfig) {
            snapshot.appendSections([.jumpBackIn(textColor, configuration)])
            snapshot.appendItems(tabs, toSection: .jumpBackIn(textColor, configuration))
        }

        if let bookmarks = getBookmarks(with: state.bookmarkState) {
            snapshot.appendSections([.bookmarks(textColor)])
            snapshot.appendItems(bookmarks, toSection: .bookmarks(textColor))
        }

        snapshot.appendSections([.spacer])
        snapshot.appendItems([.spacer], toSection: .spacer)

        if state.searchState.shouldShowSearchBar {
            snapshot.appendSections([.searchBar])
            snapshot.appendItems([.searchBar], toSection: .searchBar)
        }

        if let stories = getMerinoStories(with: state.merinoState, selectedNewsfeedCategoryID: selectedNewsfeedCategoryID) {
            let pocketSection = HomeSection.pocket(textColor)
            snapshot.appendSections([pocketSection])
            snapshot.appendItems(stories, toSection: pocketSection)
        }

        apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
    }

    /// Gets the proper amount of top sites based on layout configuration
    /// which is determined by the number of rows and number of tiles per row
    /// - Parameters:
    ///   - topSiteState: state object for top site section
    ///   - textColor: text color from wallpaper configuration
    private func getTopSites(
        with topSitesState: TopSitesSectionState,
        and textColor: TextColor?
    ) -> TopSitesSnapshotData? {
        guard topSitesState.shouldShowSection else { return nil }
        let maxVisibleItemCount = topSitesState.numberOfRows * topSitesState.numberOfTilesPerRow
        guard maxVisibleItemCount > 0 else { return nil }

        let topSitesItems: [HomeItem] = topSitesState.topSitesData.prefix(
            maxVisibleItemCount
        ).compactMap {
            .topSite($0, textColor)
        }
        let allItems = topSitesState.shouldShowAddShortcutTile
            ? topSitesItems + [.addShortcutTile(textColor)]
            : topSitesItems
        let visibleItems = Array(allItems.prefix(maxVisibleItemCount))
        guard !visibleItems.isEmpty else { return nil }

        return TopSitesSnapshotData(
            items: visibleItems,
            numberOfTilesPerRow: topSitesState.numberOfTilesPerRow,
            shouldShowSectionHeader: topSitesState.shouldShowSectionHeader
        )
    }

    private func getJumpBackInTabs(
        with state: JumpBackInSectionState,
        and config: JumpBackInSectionLayoutConfiguration
    ) -> ([HomepageDiffableDataSource.HomeItem], JumpBackInSectionLayoutConfiguration)? {
        guard state.shouldShowSection else { return nil }
        var updatedConfig = config
        updatedConfig.hasSyncedTab = state.mostRecentSyncedTab != nil

        var tabs: [HomeItem] = state.jumpBackInTabs
            .prefix(updatedConfig.getMaxNumberOfLocalTabsLayout)
            .compactMap { .jumpBackIn($0) }

        // Determines if remote tab should appear first depending on device size
        if let mostRecentSyncedTab = state.mostRecentSyncedTab {
            if updatedConfig.layoutType == .compact {
                tabs.append(.jumpBackInSyncedTab(mostRecentSyncedTab))
            } else {
                tabs.insert(.jumpBackInSyncedTab(mostRecentSyncedTab), at: 0)
            }
        }
        guard !tabs.isEmpty else { return nil }
        return (tabs, updatedConfig)
    }

    private func getBookmarks(
        with state: BookmarksSectionState
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        guard state.shouldShowSection, !state.bookmarks.isEmpty else { return nil }
        return state.bookmarks.compactMap { .bookmark($0) }
    }

    private func getMerinoStories(
        with merinoState: MerinoState,
        selectedNewsfeedCategoryID: String?
    ) -> [HomepageDiffableDataSource.HomeItem]? {
        let stories: [HomeItem] = merinoState.visibleStories(selectedNewsfeedCategoryID: selectedNewsfeedCategoryID).map {
            .merino($0, selectedNewsfeedCategoryID)
        }
        guard merinoState.shouldShowSection, !stories.isEmpty else { return nil }
        return stories
    }
}

class HomepageSpacerCell: UICollectionViewCell, ReusableCell { }

/// Homepage tile that hosts a `WKWebView` loading an interactive experience via an iframe.
/// Matches the look and feel of the Stories cards: rounded corners, an opaque background and a soft shadow.
final class WidgetsCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let cornerRadius: CGFloat = 16
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowBlurRadius: CGFloat = 2
        static let shadowOpacity: Float = 1
    }

    /// Stable identifier for the widgets' dedicated persistent data store (iOS 17+).
    private static let dataStoreIdentifier = UUID(uuidString: "0A9E1D2C-3B4F-4A6E-8C1D-2E3F4A5B6C7D")!

    /// A single data store shared by every widget tile across the app, kept isolated from the
    /// browsing tabs' cookie/site-data store. Persistent on iOS 17+, in-memory on older versions.
    private static let sharedDataStore: WKWebsiteDataStore = {
        if #available(iOS 17.0, *) {
            return WKWebsiteDataStore(forIdentifier: WidgetsCell.dataStoreIdentifier)
        } else {
            return .nonPersistent()
        }
    }()

    // MARK: - UI Elements

    /// Clips the webview to the rounded corners while `contentView` carries the shadow.
    private let rootContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = WidgetsCell.sharedDataStore
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }()

    private var loadedURL: URL?

    /// Invoked when the keyboard is presented while an input inside the web view (iframe) is focused.
    /// The associated value is the keyboard's end frame in screen coordinates (includes any toolbar).
    private var onKeyboardPresented: ((CGRect) -> Void)?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        setupLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.cornerRadius).cgPath
    }

    // MARK: - Public

    func configure(url: URL, theme: Theme, onKeyboardPresented: ((CGRect) -> Void)? = nil) {
        self.onKeyboardPresented = onKeyboardPresented
        if loadedURL != url {
            loadedURL = url
            webView.load(URLRequest(url: url))
        }
        applyTheme(theme: theme)
    }

    // MARK: - Keyboard

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        // Only react when the keyboard was triggered by an input within our web view (the iframe),
        // not by unrelated first responders elsewhere on the homepage (e.g. the address bar).
        guard firstResponder(in: webView) != nil,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }
        onKeyboardPresented?(keyboardFrame.cgRectValue)
    }

    private func firstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for subview in view.subviews {
            if let responder = firstResponder(in: subview) { return responder }
        }
        return nil
    }

    // MARK: - Helpers

    private func setupLayout() {
        rootContainer.addSubview(webView)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            webView.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            webView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
        ])
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = UX.shadowBlurRadius
        contentView.layer.shadowOffset = UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = UX.shadowOpacity
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = .clear
        rootContainer.backgroundColor = theme.colors.layer2
        setupShadow(theme: theme)
    }
}
