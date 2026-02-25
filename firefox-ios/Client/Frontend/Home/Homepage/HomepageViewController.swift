// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared
import Storage

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

    // MARK: - Themeable variables
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }
    weak var termsOfUseDelegate: TermsOfUseDelegate?

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
    // Tracks which tab the shared homepage instance is currently representing.
    private var activeTabUUID: TabUUID?

    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }

    private let jumpBackInContextualHintViewController: ContextualHintViewController
    private let syncTabContextualHintViewController: ContextualHintViewController
    private var homepageState: HomepageState
    private var lastContentOffsetY: CGFloat = 0
    private var didFinishFirstLayout = false

    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    private var availableWidth: CGFloat {
        return view.frame.size.width
    }

    // MARK: - Private constants
    private let tabManager: TabManager
    private let overlayManager: OverlayModeManager
    private let logger: Logger
    private let toastContainer: UIView

    // Telemetry related
    private var alreadyTrackedSections = Set<HomepageSection>()
    private var alreadyTrackedTopSites = Set<HomepageItem>()
    private let trackingImpressionsThrottler: MainThreadThrottlerProtocol

    // MARK: - Initializers
    init(windowUUID: WindowUUID,
         profile: Profile = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         statusBarScrollDelegate: StatusBarScrollDelegate? = nil,
         toastContainer: UIView,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         throttler: MainThreadThrottlerProtocol = MainThreadThrottler(seconds: 0.5)
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tabManager = tabManager
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
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure("AddressBarPanGestureHandler was not deallocated on the main thread. Observer was not removed")
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
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

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        addTapGestureRecognizerToDismissKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activeTabUUID = tabManager.selectedTab?.tabUUID
        /// Used as a trigger for showing a microsurvey based on viewing the homepage
        Experiments.events.recordEvent(BehavioralTargetingEvent.homepageViewed)
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewWillAppear
            )
        )
        termsOfUseDelegate?.showTermsOfUse(context: .homepageOpened)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewDidAppear
            )
        )
        trackVisibleItemImpressions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopCFRsTimer()
        saveVerticalScrollOffset()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetTrackedObjects()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        /// FXIOS-13970: Legacy homepage layout was appearing blank on iOS 15. The root cause was from applying the diffable
        /// data source snapshot before the view had finished it's first layout pass, causing the snapshot to be ignored.
        /// This issue seems to be resolved by the SDK on later iOS versions
        if !didFinishFirstLayout {
            didFinishFirstLayout = true
            store.dispatch(
                HomepageAction(
                    numberOfTopSitesPerRow: numberOfTilesPerRow(for: availableWidth),
                    showiPadSetup: shouldUseiPadSetup(),
                    windowUUID: windowUUID,
                    actionType: HomepageActionType.initialize
                )
            )
        }

        let numberOfTilesPerRow = numberOfTilesPerRow(for: availableWidth)
        guard homepageState.topSitesState.numberOfTilesPerRow != numberOfTilesPerRow else { return }

        store.dispatch(
            HomepageAction(
                numberOfTopSitesPerRow: numberOfTilesPerRow,
                windowUUID: windowUUID,
                actionType: HomepageActionType.viewDidLayoutSubviews
            )
        )
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

    // Called when the homepage is displayed to make sure it's vertical scroll position is persisted.
    // If no scroll position exists for tab, scroll the homepage to the top
    func restoreVerticalScrollOffset() {
        activeTabUUID = tabManager.selectedTab?.tabUUID
        guard let activeTabUUID, isHomepageStoriesScrollDirectionCustomized,
              let homepageScrollOffset = tabManager.getTabForUUID(uuid: activeTabUUID)?.homepageScrollOffset
        else {
            scrollToTop()
            return
        }
        collectionView?.contentOffset.y = homepageScrollOffset
    }

    func scrollToTop(animated: Bool = false) {
        if let collectionView = collectionView {
            collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.adjustedContentInset.top), animated: animated)
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
        saveVerticalScrollOffset()
        trackVisibleItemImpressions()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        saveVerticalScrollOffset()
        trackVisibleItemImpressions()
    }

    private func saveVerticalScrollOffset() {
        guard let activeTabUUID, let tab = tabManager.getTabForUUID(uuid: activeTabUUID) else { return }
        tab.homepageScrollOffset = collectionView?.contentOffset.y
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

        // We only want to proceed if content exceeds the frame (aka scrollable),
        // otherwise we will spamming the redux action (GeneralBrowserMiddlewareAction) below
        guard scrollView.contentSize.height > scrollView.frame.height else { return }

        // this action controls the address toolbar's border position, and to prevent spamming redux with actions for every
        // change in content offset, we keep track of lastContentOffsetY to know if the border needs to be updated
        // The logic detects whether there is a transition across the top of the view
        // where scrollView.contentOffset.y is zero.
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
        wallpaperView.wallpaperState = state.wallpaperState

        // TODO: - FXIOS-13346 / FXIOS-13343 - fix collection view being reloaded all the time also when data don't change
        // this is a quick workaround to avoid blocking the main thread by calling apply snapshot many times.
        if homepageState != state {
            dataSource?.updateSnapshot(
                state: state,
                jumpBackInDisplayConfig: getJumpBackInDisplayConfig()
            )
        }

        // FXIOS-11523 - Trigger impression when user opens homepage view new tab + scroll to top
        if state.shouldTriggerImpression {
            resetTrackedObjects()
            trackVisibleItemImpressions()
        }
        self.homepageState = state
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
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
        // Per design requirement, set spacing on top. We may want to revisit this spacing when implement liquid glass.
        collectionView.contentInset = UIEdgeInsets(
            top: HomepageSectionLayoutProvider.UX.topSpacing,
            left: 0,
            bottom: 0,
            right: 0
        )
        collectionView.scrollIndicatorInsets = collectionView.contentInset
        self.collectionView = collectionView

        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider = HomepageSectionLayoutProvider(windowUUID: windowUUID)
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
                with: environment
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
            return configuredCell(cellType: HomepageHeaderCell.self, at: indexPath) { cell in
                cell.configure(headerState: state)
                cell.applyTheme(theme: currentTheme)
            }
        case .privacyNotice:
            return configuredCell(cellType: PrivacyNoticeCell.self, at: indexPath) { cell in
                configurePrivacyNoticeCell(cell: cell)
            }
        case .messageCard(let config):
            return configuredCell(cellType: HomepageMessageCardCell.self, at: indexPath) { cell in
                cell.configure(with: config, windowUUID: windowUUID, theme: currentTheme)
            }
        case .topSite(let site, let textColor):
            return configuredCell(cellType: TopSiteCell.self, at: indexPath) { cell in
                cell.configure(site, position: indexPath.row, theme: currentTheme, textColor: textColor)
            }
        case .topSiteEmpty:
            return configuredCell(cellType: EmptyTopSiteCell.self, at: indexPath) { cell in
                cell.applyTheme(theme: currentTheme)
            }
        case .searchBar:
            return configuredCell(cellType: SearchBarCell.self, at: indexPath) { cell in
                cell.applyTheme(theme: currentTheme)
            }
        case .jumpBackIn(let tab):
            return configuredCell(cellType: JumpBackInCell.self, at: indexPath) { cell in
                cell.configure(config: tab, theme: currentTheme)
            }
        case .jumpBackInSyncedTab(let config):
            return configureSyncedTabCell(config, item: item, at: indexPath)
        case .bookmark(let item):
            return configuredCell(cellType: BookmarksCell.self, at: indexPath) { cell in
                cell.configure(config: item, theme: currentTheme)
            }
        case .merino(let story):
            return configureMerinoCell(story, at: indexPath)
        case .spacer:
            return configuredCell(cellType: HomepageSpacerCell.self, at: indexPath) { _ in }
        }
    }

    private func configuredCell<T: UICollectionViewCell & ReusableCell>(
        cellType: T.Type,
        at indexPath: IndexPath,
        configure: (T) -> Void
    ) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(cellType: cellType, for: indexPath) else {
            return UICollectionViewCell()
        }
        configure(cell)
        return cell
    }

    private func configurePrivacyNoticeCell(cell: PrivacyNoticeCell) {
        cell.configure(theme: currentTheme,
                       closeButtonAction: { [weak self] in
                           self?.dispatchPrivacyNoticeCloseButtonTapped()
                       },
                       linkAction: { [weak self] url in
                           self?.dispatchPrivacyNoticeLinkTapped(url: url)
                       }
        )
    }

    private func configureSyncedTabCell(
        _ config: JumpBackInSyncedTabConfiguration,
        item: HomepageItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        return configuredCell(cellType: SyncedTabCell.self, at: indexPath) { cell in
            cell.configure(
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
            prepareSyncedTabContextualHint(onCell: cell)
        }
    }

    private func configureMerinoCell(
        _ story: MerinoStoryConfiguration,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        let shouldShowStoriesFeedCell = isHomepageStoriesScrollDirectionCustomized
            && UIDevice.current.userInterfaceIdiom == .phone
        let position = indexPath.item + 1
        let currentSection = dataSource?.snapshot().sectionIdentifiers[indexPath.section] ?? .pocket(.clear)
        let totalCount = dataSource?.snapshot().numberOfItems(inSection: currentSection)

        if shouldShowStoriesFeedCell {
            return configuredCell(cellType: StoriesFeedCell.self, at: indexPath) { cell in
                cell.configure(story: story, theme: currentTheme, position: position, totalCount: totalCount)
            }
        }

        return configuredCell(cellType: StoryCell.self, at: indexPath) { cell in
            cell.configure(story: story, theme: currentTheme, position: position, totalCount: totalCount)
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
        case .topSites(let textColor, _, _):
            sectionLabelCell.configure(
                state: homepageState.topSitesState.sectionHeaderState,
                moreButtonAction: { [weak self] _ in
                    self?.navigateToShortcutsLibrary()
                },
                textColor: textColor,
                theme: currentTheme
            )
            return sectionLabelCell
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
                state: homepageState.merinoState.sectionHeaderState,
                moreButtonAction: { [weak self] _ in
                    self?.navigateToStoriesFeed()
                },
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
        store.dispatch(
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
            navigateToContextMenu(for: item, sourceView: sourceView)
        }
    }

    private func navigateToPocketLearnMore() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(
                    .link,
                    url: homepageState.merinoState.footerURL,
                    visitType: .link
                ),
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnLink
            )
        )
    }

    private func navigateToContextMenu(for item: HomepageItem, sourceView: UIView? = nil) {
        let configuration = ContextMenuConfiguration(
            site: getSiteForContextMenu(for: item),
            menuType: MenuType(homepageItem: item),
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

    private func navigateToShortcutsLibrary() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.shortcutsLibrary),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnShortcutsShowAllButton
            )
        )
    }

    private func navigateToStoriesFeed() {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.storiesFeed),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnAllStoriesButton
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
        let config = OpenPocketTelemetryConfig(isZeroSearch: homepageState.isZeroSearch, position: index)
        store.dispatch(
            MerinoAction(
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
        store.dispatch(
            TopSitesAction(
                telemetryConfig: config,
                windowUUID: self.windowUUID,
                actionType: actionType
            )
        )
    }

    private func dispatchPrivacyNoticeCloseButtonTapped() {
        store.dispatch(
            HomepageAction(
                windowUUID: self.windowUUID,
                actionType: HomepageActionType.privacyNoticeCloseButtonTapped
            )
        )
    }

    private func dispatchPrivacyNoticeLinkTapped(url: URL) {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.privacyNoticeLink(url)),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnPrivacyNoticeLink
            )
        )
    }

    private func getSiteForContextMenu(for item: HomepageItem) -> Site? {
        switch item {
        case .topSite(let state, _):
            return state.site
        case .jumpBackIn(let config):
            return Site.createBasicSite(url: config.siteURL, title: config.titleText)
        case .jumpBackInSyncedTab(let config):
            return Site.createBasicSite(url: config.url.absoluteString, title: config.titleText)
        case .bookmark(let state):
            return Site.createBasicSite(url: state.site.url, title: state.site.title)
        case .merino(let state):
            return Site.createBasicSite(url: state.url?.absoluteString ?? "", title: state.title)
        default:
            return nil
        }
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
        case .searchBar:
            dispatchNavigationBrowserAction(
                with: NavigationDestination(.homepageZeroSearch),
                actionType: NavigationBrowserActionType.tapOnHomepageSearchBar
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
        case .merino(let story):
            let destination = NavigationDestination(
                .link,
                url: story.url,
                visitType: .link
            )
            dispatchNavigationBrowserAction(with: destination, actionType: NavigationBrowserActionType.tapOnCell)
            dispatchOpenPocketAction(at: indexPath.item, actionType: MerinoActionType.tapOnHomepageMerinoCell)
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
        store.dispatch(
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
        trackingImpressionsThrottler.throttle { [self] in
            ensureMainThread {
                guard let collectionView = self.collectionView else {
                    self.logger.log(
                        "Homepage collectionview should not have been nil, unable to track impression",
                        level: .warning,
                        category: .homepage
                    )
                    return
                }
                for indexPath in collectionView.indexPathsForVisibleItems {
                    guard let section = self.dataSource?.sectionIdentifier(for: indexPath.section),
                          let item = self.dataSource?.itemIdentifier(for: indexPath) else { continue }
                    self.handleTrackingImpressions(for: section, with: item, at: indexPath.item)
                }
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
