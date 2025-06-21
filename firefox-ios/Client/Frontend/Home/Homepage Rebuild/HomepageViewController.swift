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
                                    Screenshotable,
                                    Themeable,
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

    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }

    private let jumpBackInContextualHintViewController: ContextualHintViewController
    private let syncTabContextualHintViewController: ContextualHintViewController
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

    // Telemetry related
    private var alreadyTrackedSections = Set<HomepageSection>()
    private var alreadyTrackedTopSites = Set<HomepageItem>()
    private let trackingImpressionsThrottler: ThrottleProtocol

    // MARK: - Initializers
    init(windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         overlayManager: OverlayModeManager,
         statusBarScrollDelegate: StatusBarScrollDelegate? = nil,
         toastContainer: UIView,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         throttler: ThrottleProtocol = GCDThrottler(seconds: 0.5)
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.overlayManager = overlayManager
        self.statusBarScrollDelegate = statusBarScrollDelegate
        self.toastContainer = toastContainer
        self.logger = logger
        self.trackingImpressionsThrottler = throttler

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

        store.dispatchLegacy(
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
        store.dispatchLegacy(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewWillAppear
            )
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackVisibleItemImpressions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCFRsTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetTrackedObjects()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        store.dispatchLegacy(
            HomepageAction(
                numberOfTopSitesPerRow: numberOfTilesPerRow(for: availableWidth),
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewDidLayoutSubviews
            )
        )
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        wallpaperView.updateImageForOrientationChange()
        store.dispatchLegacy(
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

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        trackVisibleItemImpressions()
    }

    private func handleScroll(_ scrollView: UIScrollView, isUserInteraction: Bool) {
        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)

        // We only handle status bar overlay alpha if there's a wallpaper applied on the homepage
        // or if the toolbar refactor feature is turned on
        if homepageState.wallpaperState.wallpaperConfiguration.hasImage || isToolbarRefactorEnabled {
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
            store.dispatchLegacy(
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
        store.dispatchLegacy(action)
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
        store.dispatchLegacy(action)

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
        // FXIOS-11523 - Trigger impression when user opens homepage view new tab + scroll to top
        if homepageState.shouldTriggerImpression {
            scrollToTop()
            resetTrackedObjects()
            trackVisibleItemImpressions()
        }
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .homepage
        )
        store.dispatchLegacy(action)
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
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
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
                    "Section should not have been nil, something went wrong",
                    level: .fatal,
                    category: .homepage,
                    extra: ["Section Index": "\(sectionIndex)"]
                )

                /// FXIOS-10131: Copied over from legacy homepage in that we want to create an empty layout
                /// to avoid an app crash.
                /// However, if we see this path getting hit, then something is wrong and
                /// we should investigate the underlying issues. We should always be able to fetch the section.
                return sectionProvider.makeEmptyLayoutSection()
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
            let isTopSitesRefreshEnabled = featureFlags.isFeatureEnabled(.hntTopSitesVisualRefresh, checking: .buildOnly)
            let cellType: ReusableCell.Type = isTopSitesRefreshEnabled ? TopSiteCell.self : LegacyTopSiteCell.self

            guard let topSiteCell = collectionView?.dequeueReusableCell(cellType: cellType, for: indexPath) else {
                return UICollectionViewCell()
            }

            if let topSiteCell = topSiteCell as? TopSiteCell {
                topSiteCell.configure(site, position: indexPath.row, theme: currentTheme, textColor: textColor)
                return topSiteCell
            } else if let legacyTopSiteCell = topSiteCell as? LegacyTopSiteCell {
                legacyTopSiteCell.configure(site, position: indexPath.row, theme: currentTheme, textColor: textColor)
                return legacyTopSiteCell
            }

            return UICollectionViewCell()

        case .topSiteEmpty:
            guard let emptyCell = collectionView?.dequeueReusableCell(cellType: EmptyTopSiteCell.self, for: indexPath) else {
                return UICollectionViewCell()
            }

            emptyCell.applyTheme(theme: currentTheme)
            return emptyCell

        case .searchBar:
            guard let searchBar = collectionView?.dequeueReusableCell(
                cellType: SearchBarCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            searchBar.applyTheme(theme: currentTheme)
            return searchBar

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
                    guard let self else { return }
                    self.navigateToNewTab(with: url)
                    self.sendItemActionWithTelemetryExtras(item: item, actionType: .didSelectItem)
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

    // MARK: - Screenshotable

    func screenshot(bounds: CGRect) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        return renderer.image { context in
            themeManager.getCurrentTheme(for: windowUUID).colors.layer1.setFill()
            context.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
            // Draw the wallpaper separately, so the potential safe area coordinates is filled with the
            // wallpaper
            wallpaperView.drawHierarchy(
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: bounds.width,
                    height: bounds.height
                ),
                afterScreenUpdates: false
            )

            view.drawHierarchy(
                in: CGRect(
                    x: bounds.origin.x,
                    y: -bounds.origin.y,
                    width: bounds.width,
                    height: collectionView?.frame.height ?? 0.0
                ),
                afterScreenUpdates: false
            )
        }
    }

    func screenshot(quality: CGFloat) -> UIImage? {
        return screenshot(bounds: view.bounds)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        store.dispatchLegacy(
            HomepageAction(
                showiPadSetup: shouldUseiPadSetup(),
                windowUUID: windowUUID,
                actionType: HomepageActionType.traitCollectionDidChange
            )
        )
    }

    // MARK: Tap Gesture Recognizer
    private func addTapGestureRecognizerToDismissKeyboard() {
        // We want any interaction with the homepage to dismiss the keyboard, including taps
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func dismissKeyboard() {
        let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
        store.dispatchLegacy(action)
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
        store.dispatchLegacy(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.settings(.homePage)),
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnCustomizeHomepageButton
            )
        )
    }

    private func navigateToPocketLearnMore() {
        store.dispatchLegacy(
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
        store.dispatchLegacy(
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
        store.dispatchLegacy(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.bookmarksPanel),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnBookmarksShowMoreButton
            )
        )
    }

    private func dispatchNavigationBrowserAction(with destination: NavigationDestination, actionType: ActionType) {
        store.dispatchLegacy(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: self.windowUUID,
                actionType: actionType
            )
        )
    }

    private func dispatchOpenPocketAction(at index: Int, actionType: ActionType) {
        let config = OpenPocketTelemetryConfig(isZeroSearch: homepageState.isZeroSearch, position: index)
        store.dispatchLegacy(
            PocketAction(
                telemetryConfig: config,
                windowUUID: self.windowUUID,
                actionType: actionType
            )
        )
    }

    private func dispatchTopSitesAction(at index: Int, config: TopSiteConfiguration, actionType: ActionType) {
        let config = TopSitesTelemetryConfig(
            isZeroSearch: homepageState.isZeroSearch,
            position: index,
            topSiteConfiguration: config
        )
        store.dispatchLegacy(
            TopSitesAction(
                telemetryConfig: config,
                windowUUID: self.windowUUID,
                actionType: actionType
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
        dispatchDidSelectCardItemAction(with: item)
        switch item {
        case .topSite(let config, _):
            let destination = NavigationDestination(
                .link,
                url: config.site.url.asURL,
                isGoogleTopSite: config.isGoogleURL,
                visitType: .link
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
            dispatchTopSitesAction(
                at: indexPath.item,
                config: config,
                actionType: TopSitesActionType.tapOnHomepageTopSitesCell
            )
        case .jumpBackIn(let config):
            store.dispatchLegacy(
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
        default:
            return
        }
    }

    /// Sends telemetry data associated with tapping on a card item. The jump back in synced card item
    /// is handled differently due to how tapping is handled for the cell. See `onOpenSyncedTabAction` in this file.
    private func dispatchDidSelectCardItemAction(with item: HomepageItem) {
        if case .jumpBackInSyncedTab = item { return }
        sendItemActionWithTelemetryExtras(item: item, actionType: .didSelectItem)
    }

    /// Sends generic telemetry extras to middleware, sends additional extras `topSitesTelemetryConfig` for sponsored sites
    private func sendItemActionWithTelemetryExtras(
        item: HomepageItem,
        actionType: HomepageActionType,
        topSitesTelemetryConfig: TopSitesTelemetryConfig? = nil
    ) {
        let telemetryExtras = HomepageTelemetryExtras(
            itemType: item.telemetryItemType,
            topSitesTelemetryConfig: topSitesTelemetryConfig
        )
        store.dispatchLegacy(
            HomepageAction(
                telemetryExtras: telemetryExtras,
                windowUUID: windowUUID,
                actionType: actionType
            )
        )
    }

    /// Used to track impressions. If the user has already seen the item on the homepage, we only record the impression once.
    /// We want to track at initial seen as well as when users scrolls.
    /// A throttle is added in order to capture what the users has seen. When we scroll to top programmatically,
    /// the impressions were being tracked, but to match user's perspective, we add a throttle to delay.
    /// Time complexity: O(n) due to iterating visible items.
    private func trackVisibleItemImpressions() {
        trackingImpressionsThrottler.throttle { [weak self] in
            guard let self else { return }
            guard let collectionView else {
                logger.log(
                    "Homepage collectionview should not have been nil, unable to track impression",
                    level: .warning,
                    category: .homepage
                )
                return
            }
            for indexPath in collectionView.indexPathsForVisibleItems {
                guard let section = dataSource?.sectionIdentifier(for: indexPath.section),
                      let item = dataSource?.itemIdentifier(for: indexPath) else { continue }
                handleTrackingImpressions(for: section, with: item, at: indexPath.item)
            }
        }
    }

    /// We want to capture generic section impressions,
    /// but we also need to handle capturing individual sponsored tiles impressions
    private func handleTrackingImpressions(for section: HomepageSection, with item: HomepageItem, at index: Int) {
        handleTrackingTopSitesImpression(for: item, at: index)
        handleTrackingSectionImpression(for: section, with: item)
    }

    private func handleTrackingTopSitesImpression(for item: HomepageItem, at index: Int) {
        guard !alreadyTrackedTopSites.contains(item) else { return }
        alreadyTrackedTopSites.insert(item)
        guard case .topSite(let config, _) = item else { return }
        dispatchTopSitesAction(at: index, config: config, actionType: TopSitesActionType.topSitesSeen)
    }

    private func handleTrackingSectionImpression(for section: HomepageSection, with item: HomepageItem) {
        guard !alreadyTrackedSections.contains(section) else { return }
        alreadyTrackedSections.insert(section)
        sendItemActionWithTelemetryExtras(item: item, actionType: HomepageActionType.sectionSeen)
    }

    private func resetTrackedObjects() {
        alreadyTrackedSections.removeAll()
        alreadyTrackedTopSites.removeAll()
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

    private var canContextHintBePresented: Bool {
        return presentedViewController == nil && homepageState.isZeroSearch
    }

    @objc
    private func presentContextualHint(with contextualHintViewController: ContextualHintViewController) {
        guard canContextHintBePresented else { return }
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
}
