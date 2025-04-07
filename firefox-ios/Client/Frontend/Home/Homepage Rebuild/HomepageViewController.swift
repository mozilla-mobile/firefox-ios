// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared

final class HomepageViewController: UIViewController,
                                    UICollectionViewDelegate,
                                    UIPopoverPresentationControllerDelegate,
                                    UIAdaptivePresentationControllerDelegate,
                                    FeatureFlaggable,
                                    ContentContainable,
                                    Themeable,
                                    Notifiable,
                                    StoreSubscriber {
    // MARK: - Typealiases
    typealias SubscriberStateType = HomepageState

    // MARK: - ContentContainable variables
    var contentType: ContentType = .homepage

    // MARK: - Themable variables
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Layout variables
    var statusBarFrame: CGRect? {
        guard let keyWindow = UIWindow.keyWindow else { return nil }

        return keyWindow.windowScene?.statusBarManager?.statusBarFrame
    }

    weak var statusBarScrollDelegate: StatusBarScrollDelegate?

    // MARK: - Private variables
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage
    private var collectionView: UICollectionView?
    private var dataSource: HomepageDiffableDataSource?
    // TODO: FXIOS-10541 will handle scrolling for wallpaper and other scroll issues
    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }

    private let jumpBackInContextualHintViewController: ContextualHintViewController
    private let syncTabContextualHintViewController: ContextualHintViewController
    // TODO: FXIOS-11504: Move this to state + add comments on what this is + why we use it
    private let isZeroSearch: Bool
    private var homepageState: HomepageState
    private var lastContentOffsetY: CGFloat = 0

    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    private var availableWidth: CGFloat {
        return view.frame.size.width
    }

    // MARK: - Private constants
    private let overlayManager: OverlayModeManager
    private let logger: Logger
    private let toastContainer: UIView

    // MARK: - Initializers
    init(windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         isZeroSearch: Bool,
         overlayManager: OverlayModeManager,
         statusBarScrollDelegate: StatusBarScrollDelegate? = nil,
         toastContainer: UIView,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.isZeroSearch = isZeroSearch
        self.overlayManager = overlayManager
        self.statusBarScrollDelegate = statusBarScrollDelegate
        self.toastContainer = toastContainer
        self.logger = logger

        // FXIOS-11490: This should be refactored when we refactor CFR to adhere to Redux
        let jumpBackInContextualViewProvider = ContextualHintViewProvider(
            forHintType: .jumpBackIn,
            with: profile
        )
        self.jumpBackInContextualHintViewController = ContextualHintViewController(
            with: jumpBackInContextualViewProvider,
            windowUUID: windowUUID
        )

        let syncTabContextualViewProvider = ContextualHintViewProvider(
            forHintType: .jumpBackInSyncedTab,
            with: profile
        )
        self.syncTabContextualHintViewController = ContextualHintViewController(
            with: syncTabContextualViewProvider,
            windowUUID: windowUUID
        )

        homepageState = HomepageState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self, observing: [
            UIApplication.didBecomeActiveNotification,
            .FirefoxAccountChanged,
            .PrivateDataClearedHistory,
            .ProfileDidFinishSyncing,
            .TopSitesUpdated,
            .DefaultSearchEngineUpdated,
            .BookmarksUpdated,
            .RustPlacesOpened
        ])

        subscribeToRedux()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
        notificationCenter.removeObserver(self)
    }

    func stopCFRsTimer() {
        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWallpaperView()
        configureCollectionView()
        setupLayout()
        configureDataSource()

        store.dispatch(
            HomepageAction(
                numberOfTopSitesPerRow: numberOfTilesPerRow(for: availableWidth),
                showiPadSetup: shouldUseiPadSetup(),
                windowUUID: windowUUID,
                actionType: HomepageActionType.initialize
            )
        )

        listenForThemeChange(view)
        applyTheme()
        addTapGestureRecognizerToDismissKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// Used as a trigger for showing a microsurvey based on viewing the homepage
        Experiments.events.recordEvent(BehavioralTargetingEvent.homepageViewed)
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewWillAppear
            )
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCFRsTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        wallpaperView.updateImageForOrientationChange()
        store.dispatch(
            HomepageAction(
                numberOfTopSitesPerRow: numberOfTilesPerRow(for: size.width),
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewWillTransition
            )
        )
    }

    // called when the homepage is displayed to make sure it's scrolled to top
    func scrollToTop(animated: Bool = false) {
        collectionView?.setContentOffset(.zero, animated: animated)
        if let collectionView = collectionView {
            handleScroll(collectionView, isUserInteraction: false)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView, isUserInteraction: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
        handleToolbarStateOnScroll()
    }

    private func handleScroll(_ scrollView: UIScrollView, isUserInteraction: Bool) {
        // We only handle status bar overlay alpha if there's a wallpaper applied on the homepage
        if homepageState.wallpaperState.wallpaperConfiguration.hasImage {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            statusBarScrollDelegate?.scrollViewDidScroll(
                scrollView,
                statusBarFrame: statusBarFrame,
                theme: theme
            )
        }
        // this action controls the address toolbar's border position, and to prevent spamming redux with actions for every
        // change in content offset, we keep track of lastContentOffsetY to know if the border needs to be updated
        if (lastContentOffsetY > 0 && scrollView.contentOffset.y <= 0) ||
            (lastContentOffsetY <= 0 && scrollView.contentOffset.y > 0) {
            lastContentOffsetY = scrollView.contentOffset.y
            store.dispatch(
                GeneralBrowserMiddlewareAction(
                    scrollOffset: scrollView.contentOffset,
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll))
        }
    }

    private func handleToolbarStateOnScroll() {
        guard featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly) else { return }
        // When the user scrolls the homepage (not overlaid on a webpage when searching) we cancel edit mode
        let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEditOnHomepage)
        store.dispatch(action)
    }

    /// Calculates the number of tiles that can fit in a single row based on the available width.
    /// Used for top sites section layout and data filtering.
    /// Must be calculated on main thread only due to use of traitCollection.
    ///
    /// - Parameter availableWidth: The total width available for displaying the tiles, determined by the view's size.
    /// - Returns: The number of tiles that can fit in a single row within the available width.
    private func numberOfTilesPerRow(for availableWidth: CGFloat) -> Int {
        let tiles = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: availableWidth,
            leadingInset: HomepageSectionLayoutProvider.UX.leadingInset(
                traitCollection: traitCollection
            )
        )
        return tiles
    }

    private func getJumpBackInDisplayConfig() -> JumpBackInSectionLayoutConfiguration {
        return HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: traitCollection
        )
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .homepage
        )
        store.dispatch(action)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return HomepageState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })
    }

    func newState(state: HomepageState) {
        self.homepageState = state
        wallpaperView.wallpaperState = state.wallpaperState

        dataSource?.updateSnapshot(
            state: state,
            jumpBackInDisplayConfig: getJumpBackInDisplayConfig()
        )
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .homepage
        )
        store.dispatch(action)
    }

    // MARK: - Theming
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    // MARK: - Layout

    func configureWallpaperView() {
        view.addSubview(wallpaperView)

        // Constraint so wallpaper appears under the status bar
        let wallpaperTopConstant: CGFloat = UIWindow.keyWindow?.safeAreaInsets.top ?? statusBarFrame?.height ?? 0

        NSLayoutConstraint.activate([
            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor, constant: -wallpaperTopConstant),
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.sendSubviewToBack(wallpaperView)
    }

    private func setupLayout() {
        guard let collectionView else {
            logger.log(
                "Homepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .homepage
            )
            return
        }

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())

        HomepageItem.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }

        collectionView.registerSupplementary(
            of: UICollectionView.elementKindSectionHeader,
            cellType: LabelButtonHeaderView.self
        )
        collectionView.registerSupplementary(
            of: UICollectionView.elementKindSectionFooter,
            cellType: PocketFooterView.self
        )

        collectionView.keyboardDismissMode = .onDrag
        collectionView.addGestureRecognizer(longPressRecognizer)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView
        collectionView.delegate = self

        self.collectionView = collectionView

        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider = HomepageSectionLayoutProvider(windowUUID: self.windowUUID)
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, environment)
            -> NSCollectionLayoutSection? in
            guard let section = self?.dataSource?.snapshot().sectionIdentifiers[safe: sectionIndex] else {
                self?.logger.log(
                    "Section should not have been nil, something went wrong for \(sectionIndex)",
                    level: .fatal,
                    category: .homepage
                )
                return nil
            }

            return sectionProvider.createLayoutSection(
                for: section,
                with: environment.traitCollection
            )
        }
        return layout
    }

    private func configureDataSource() {
        guard let collectionView else {
            logger.log(
                "Homepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .homepage
            )
            return
        }

        dataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.configureCell(for: item, at: indexPath)
        }

        dataSource?.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            return self?.configureSupplementaryCell(with: collectionView, for: kind, at: indexPath)
        }
    }

    private func configureCell(
        for item: HomepageDiffableDataSource.HomeItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item {
        case .header(let state):
            guard let headerCell = collectionView?.dequeueReusableCell(
                cellType: HomepageHeaderCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            headerCell.configure(headerState: state)
            headerCell.applyTheme(theme: currentTheme)

            return headerCell

        case .messageCard(let config):
            guard let messageCardCell = collectionView?.dequeueReusableCell(
                cellType: HomepageMessageCardCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            messageCardCell.configure(with: config, windowUUID: windowUUID, theme: currentTheme)
            return messageCardCell
        case .topSite(let site, let textColor):
            guard let topSiteCell = collectionView?.dequeueReusableCell(cellType: TopSiteCell.self, for: indexPath) else {
                return UICollectionViewCell()
            }

            topSiteCell.configure(
                site,
                position: indexPath.row,
                theme: currentTheme,
                textColor: textColor
            )
            return topSiteCell

        case .topSiteEmpty:
            guard let emptyCell = collectionView?.dequeueReusableCell(cellType: EmptyTopSiteCell.self, for: indexPath) else {
                return UICollectionViewCell()
            }

            emptyCell.applyTheme(theme: currentTheme)
            return emptyCell

        case .jumpBackIn(let tab):
            guard let jumpBackInCell = collectionView?.dequeueReusableCell(
                cellType: JumpBackInCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            jumpBackInCell.configure(config: tab, theme: currentTheme)
            return jumpBackInCell

        case .jumpBackInSyncedTab(let config):
            guard let syncedTabCell = collectionView?.dequeueReusableCell(
                cellType: SyncedTabCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            syncedTabCell.configure(
                configuration: config,
                theme: currentTheme,
                onTapShowAllAction: { [weak self] in
                    self?.navigateToTabTray(with: .syncedTabs)
                },
                onOpenSyncedTabAction: { [weak self] url in
                    self?.navigateToNewTab(with: url)
                }
            )
            prepareSyncedTabContextualHint(onCell: syncedTabCell)
            return syncedTabCell

        case .bookmark(let item):
            guard let bookmarksCell = collectionView?.dequeueReusableCell(
                cellType: BookmarksCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            bookmarksCell.configure(config: item, theme: currentTheme)
            return bookmarksCell
        case .pocket(let story):
            guard let pocketCell = collectionView?.dequeueReusableCell(
                cellType: PocketStandardCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            pocketCell.configure(story: story, theme: currentTheme)

            return pocketCell
        case .pocketDiscover(let item):
            guard let pocketDiscoverCell = collectionView?.dequeueReusableCell(
                cellType: PocketDiscoverCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            pocketDiscoverCell.configure(text: item.title, theme: currentTheme)

            return pocketDiscoverCell

        case .customizeHomepage:
            guard let customizeHomeCell = collectionView?.dequeueReusableCell(
                cellType: CustomizeHomepageSectionCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }

            customizeHomeCell.configure(onTapAction: { [weak self] _ in
                self?.navigateToHomepageSettings()
            }, theme: currentTheme)

            return customizeHomeCell
        }
    }

    private func configureSupplementaryCell(
        with collectionView: UICollectionView,
        for kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView? {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let sectionHeaderView = collectionView.dequeueSupplementary(
                of: kind,
                cellType: LabelButtonHeaderView.self,
                for: indexPath)
            else { return UICollectionReusableView() }
            guard let section = dataSource?.sectionIdentifier(for: indexPath.section) else {
                self.logger.log(
                    "Section should not have been nil, something went wrong",
                    level: .fatal,
                    category: .homepage
                )
                return UICollectionReusableView()
            }
            return self.configureSectionHeader(for: section, with: sectionHeaderView)
        case UICollectionView.elementKindSectionFooter:
            guard let footerView = collectionView.dequeueSupplementary(
                of: kind,
                cellType: PocketFooterView.self,
                for: indexPath)
            else { return UICollectionReusableView() }
            footerView.onTapLearnMore = {
                self.navigateToPocketLearnMore()
            }
            footerView.applyTheme(theme: currentTheme)
            return footerView
        default:
            return nil
        }
    }

    private func configureSectionHeader(
        for section: HomepageSection,
        with sectionLabelCell: LabelButtonHeaderView
    ) -> LabelButtonHeaderView? {
        switch section {
        case .jumpBackIn(let textColor, _):
            sectionLabelCell.configure(
                state: homepageState.jumpBackInState.sectionHeaderState,
                moreButtonAction: { [weak self] _ in
                    self?.navigateToTabTray(with: .tabs)
                },
                textColor: textColor,
                theme: currentTheme
            )
            prepareJumpBackInContextualHint(onView: sectionLabelCell)
            return sectionLabelCell
        case .bookmarks(let textColor):
            sectionLabelCell.configure(
                state: homepageState.bookmarkState.sectionHeaderState,
                moreButtonAction: { [weak self] _ in
                    self?.navigateToBookmarksPanel()
                },
                textColor: textColor,
                theme: currentTheme
            )
            return sectionLabelCell
        case .pocket(let textColor):
            sectionLabelCell.configure(
                state: homepageState.pocketState.sectionHeaderState,
                textColor: textColor,
                theme: currentTheme
            )
            return sectionLabelCell
        default:
            return nil
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        store.dispatch(
            HomepageAction(
                showiPadSetup: shouldUseiPadSetup(),
                windowUUID: windowUUID,
                actionType: HomepageActionType.traitCollectionDidChange
            )
        )
    }

    // MARK: Tap Geasutre Recognizer
    private func addTapGestureRecognizerToDismissKeyboard() {
        // We want any interaction with the homepage to dismiss the keyboard, including taps
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func dismissKeyboard() {
        let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
        store.dispatch(action)
    }

    // MARK: Long Press (Photon Action Sheet)
    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()

    @objc
    private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView?.indexPathForItem(at: point),
              let item = dataSource?.itemIdentifier(for: indexPath),
              let section = dataSource?.sectionIdentifier(for: indexPath.section),
              let sourceView = collectionView?.cellForItem(at: indexPath)
        else {
            self.logger.log(
                "Context menu handling skipped: No valid indexPath, item, section or sourceView found at \(point)",
                level: .debug,
                category: .homepage
            )
            return
        }
        if section.canHandleLongPress {
            navigateToContextMenu(for: section, and: item, sourceView: sourceView)
        }
    }

    private func navigateToHomepageSettings() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.settings(.homePage)),
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnCustomizeHomepage
            )
        )
    }

    private func navigateToPocketLearnMore() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(
                    .link,
                    url: homepageState.pocketState.footerURL,
                    visitType: .link
                ),
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnLink
            )
        )
    }

    private func navigateToContextMenu(for section: HomepageSection, and item: HomepageItem, sourceView: UIView? = nil) {
        let configuration = ContextMenuConfiguration(
            homepageSection: section,
            item: item,
            sourceView: sourceView,
            toastContainer: toastContainer
        )
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.contextMenu, contextMenuConfiguration: configuration),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.longPressOnCell
            )
        )
    }

    private func navigateToTabTray(with type: TabTrayPanelType) {
        dispatchNavigationBrowserAction(
            with: NavigationDestination(.tabTray(type)),
            actionType: NavigationBrowserActionType.tapOnJumpBackInShowAllButton
        )
    }

    private func navigateToNewTab(with url: URL) {
        let destination = NavigationDestination(
            .newTab,
            url: url,
            isPrivate: false,
            selectNewTab: true
        )
        self.dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
    }

    private func navigateToBookmarksPanel() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.bookmarksPanel),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnBookmarksShowMoreButton
            )
        )
    }

    private func dispatchNavigationBrowserAction(with destination: NavigationDestination, actionType: ActionType) {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: self.windowUUID,
                actionType: actionType
            )
        )
    }

    private func dispatchOpenPocketAction(at index: Int, actionType: ActionType) {
        let config = OpenPocketTelemetryConfig(isZeroSearch: isZeroSearch, position: index)
        store.dispatch(
            PocketAction(
                telemetryConfig: config,
                windowUUID: self.windowUUID,
                actionType: actionType
            )
        )
    }

    private func dispatchOpenTopSitesAction(at index: Int, tileType: String, urlString: String) {
        let config = TopSitesTelemetryConfig(
            isZeroSearch: isZeroSearch,
            position: index,
            tileType: tileType,
            url: urlString
        )
        store.dispatch(
            TopSitesAction(
                telemetryConfig: config,
                windowUUID: self.windowUUID,
                actionType: TopSitesActionType.tapOnHomepageTopSitesCell
            )
        )
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else {
            self.logger.log(
                "Item selected at \(indexPath) but does not navigate anywhere",
                level: .debug,
                category: .homepage
            )
            return
        }
        switch item {
        case .topSite(let state, _):
            let destination = NavigationDestination(
                .link,
                url: state.site.url.asURL,
                isGoogleTopSite: state.isGoogleURL,
                visitType: .link
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
            dispatchOpenTopSitesAction(
                at: indexPath.item,
                tileType: state.getTelemetrySiteType,
                urlString: state.site.url
            )

        case .jumpBackIn(let config):
            store.dispatch(
                JumpBackInAction(
                    tab: config.tab,
                    windowUUID: self.windowUUID,
                    actionType: JumpBackInActionType.tapOnCell
                )
            )
        case .bookmark(let config):
            let destination = NavigationDestination(
                .link,
                url: URIFixup.getURL(config.site.url),
                isGoogleTopSite: false,
                visitType: .bookmark
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
        case .pocket(let story):
            let destination = NavigationDestination(
                .link,
                url: story.url,
                visitType: .link
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
            dispatchOpenPocketAction(at: indexPath.item, actionType: PocketActionType.tapOnHomepagePocketCell)
        case .pocketDiscover(let item):
            let destination = NavigationDestination(
                .link,
                url: item.url,
                visitType: .link
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
        default:
            return
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate - Context Hints (CFR)
    func popoverPresentationController(
        _ popoverPresentationController: UIPopoverPresentationController,
        willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
        in view: AutoreleasingUnsafeMutablePointer<UIView>
    ) {
        // Do not dismiss if the popover is a CFR when device is rotated
        guard !jumpBackInContextualHintViewController.isPresenting &&
                !syncTabContextualHintViewController.isPresenting else { return }
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }

    private func prepareJumpBackInContextualHint(onView headerView: LabelButtonHeaderView) {
        guard jumpBackInContextualHintViewController.shouldPresentHint(),
              dataSource?.snapshot().sectionIdentifiers.contains(.messageCard) == nil
        else { return }

        jumpBackInContextualHintViewController.configure(
            anchor: headerView.titleLabel,
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                guard let self else { return }
                self.presentContextualHint(with: self.jumpBackInContextualHintViewController)
            },
            overlayState: overlayManager)
    }

    private func prepareSyncedTabContextualHint(onCell cell: SyncedTabCell) {
        guard syncTabContextualHintViewController.shouldPresentHint() else {
            syncTabContextualHintViewController.unconfigure()
            return
        }

        syncTabContextualHintViewController.configure(
            anchor: cell.getContextualHintAnchor(),
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                guard let self else { return }
                self.presentContextualHint(with: self.syncTabContextualHintViewController)
            },
            overlayState: overlayManager)
    }

    private var canModalBePresented: Bool {
        return presentedViewController == nil && isZeroSearch
    }

    @objc
    private func presentContextualHint(with contextualHintViewController: ContextualHintViewController) {
        guard canModalBePresented else { return }
        contextualHintViewController.isPresenting = true
        present(contextualHintViewController, animated: true, completion: nil)
        UIAccessibility.post(notification: .layoutChanged, argument: contextualHintViewController)
    }

    // MARK: UIAdaptivePresentationControllerDelegate
    /// Prevents popovers from becoming modals on iPhone
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            store.dispatch(
                PocketAction(
                    windowUUID: self.windowUUID,
                    actionType: PocketActionType.enteredForeground
                )
            )
        case .PrivateDataClearedHistory,
                .TopSitesUpdated,
                .DefaultSearchEngineUpdated:
            dispatchActionToFetchTopSites()
        case .BookmarksUpdated, .RustPlacesOpened:
            store.dispatch(
                BookmarksAction(
                    windowUUID: self.windowUUID,
                    actionType: BookmarksActionType.fetchBookmarks
                )
            )
        case .ProfileDidFinishSyncing, .FirefoxAccountChanged:
            dispatchActionToFetchTopSites()
            dispatchActionToFetchTabs()
        default: break
        }
    }

    private func dispatchActionToFetchTopSites() {
        store.dispatch(
            TopSitesAction(
                windowUUID: self.windowUUID,
                actionType: TopSitesActionType.fetchTopSites
            )
        )
    }

    private func dispatchActionToFetchTabs() {
        store.dispatch(
            JumpBackInAction(
                windowUUID: self.windowUUID,
                actionType: JumpBackInActionType.fetchLocalTabs
            )
        )
        store.dispatch(
            JumpBackInAction(
                windowUUID: self.windowUUID,
                actionType: JumpBackInActionType.fetchRemoteTabs
            )
        )
    }
}
