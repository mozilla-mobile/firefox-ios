// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import Storage
import Redux
import UIKit

import enum MozillaAppServices.VisitType

class LegacyHomepageViewController:
    UIViewController,
    FeatureFlaggable,
    Themeable,
    ContentContainable,
    SearchBarLocationProvider {
    // MARK: - Typealiases

    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - Operational Variables

    weak var homePanelDelegate: HomePanelDelegate?
    weak var libraryPanelDelegate: LibraryPanelDelegate?

    weak var browserNavigationHandler: BrowserNavigationHandler? {
        didSet {
            contextMenuHelper.browserNavigationHandler = browserNavigationHandler
        }
    }

    weak var statusBarScrollDelegate: StatusBarScrollDelegate?

    private var viewModel: HomepageViewModel
    private var contextMenuHelper: HomepageContextMenuHelper
    private var tabManager: TabManager
    private var overlayManager: OverlayModeManager
    private var userDefaults: UserDefaultsInterface
    private lazy var wallpaperView: LegacyWallpaperBackgroundView = .build { _ in }
    private var wallpaperViewTopConstraint: NSLayoutConstraint?
    private var jumpBackInContextualHintViewController: ContextualHintViewController
    private var syncTabContextualHintViewController: ContextualHintViewController
    private var collectionView: UICollectionView?
    private var lastContentOffsetY: CGFloat = 0
    private var logger: Logger
    private let viewWillAppearEventThrottler = Throttler(seconds: 0.5)

    var windowUUID: WindowUUID { return tabManager.windowUUID }
    var currentWindowUUID: UUID? { return windowUUID }

    var contentType: ContentType = .legacyHomepage

    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?

    // Content stack views contains collection view.
    lazy var contentStackView: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
    }

    var currentTab: Tab? {
        return tabManager.selectedTab
    }

    // MARK: - Initializers
    init(profile: Profile,
         isZeroSearch: Bool = false,
         toastContainer: UIView,
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         userDefaults: UserDefaultsInterface = UserDefaults.standard,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.overlayManager = overlayManager
        self.tabManager = tabManager
        self.userDefaults = userDefaults
        let isPrivate = tabManager.selectedTab?.isPrivate ?? true
        self.viewModel = HomepageViewModel(profile: profile,
                                           isPrivate: isPrivate,
                                           tabManager: tabManager,
                                           theme: themeManager.getCurrentTheme(for: tabManager.windowUUID))

        let jumpBackInContextualViewProvider = ContextualHintViewProvider(forHintType: .jumpBackIn,
                                                                          with: viewModel.profile)
        self.jumpBackInContextualHintViewController = ContextualHintViewController(
            with: jumpBackInContextualViewProvider, windowUUID: tabManager.windowUUID
        )
        let syncTabContextualViewProvider = ContextualHintViewProvider(
            forHintType: .jumpBackInSyncedTab,
            with: viewModel.profile
        )
        self.syncTabContextualHintViewController =
        ContextualHintViewController(with: syncTabContextualViewProvider, windowUUID: tabManager.windowUUID)
        self.contextMenuHelper = HomepageContextMenuHelper(
            profile: profile,
            viewModel: viewModel,
            toastContainer: toastContainer
        )

        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
        viewModel.isZeroSearch = isZeroSearch

        contextMenuHelper.delegate = self
        contextMenuHelper.getPopoverSourceRect = { [weak self] popoverView in
            guard let self = self else { return CGRect() }
            return self.getPopoverSourceRect(sourceView: popoverView)
        }

        setupNotifications(forObserver: self,
                           observing: [.HomePanelPrefsChanged,
                                       .TabsPrivacyModeChanged,
                                       .WallpaperDidChange])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureWallpaperView()
        configureContentStackView()
        configureCollectionView()

        // Delay setting up the view model delegate to ensure the views have been configured first
        viewModel.delegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        setupSectionsAction()
        reloadView()

        listenForThemeChange(view)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO: FXIOS-9428 - Need to fix issue where viewWillAppear is called twice so we can remove the throttle workaround
        // This can then be moved back inside the `viewModel.recordViewAppeared()`
        viewWillAppearEventThrottler.throttle {
            Experiments.events.recordEvent(BehavioralTargetingEvent.homepageViewed)
        }

        notificationCenter.post(name: .ShowHomepage, withUserInfo: windowUUID.userInfo)
        notificationCenter.post(name: .HistoryUpdated)

        applyTheme()
        reloadView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // FXIOS-9428 - Record telemetry in viewDidAppear since viewWillAppear is sometimes triggered twice
        viewModel.recordViewAppeared()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.displayWallpaperSelector()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
        viewModel.recordViewDisappeared()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        jumpBackInContextualHintViewController.stopTimer()
        syncTabContextualHintViewController.stopTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        wallpaperView.updateImageForOrientationChange()

        // Note: Saving the newSize for using it, later, in traitCollectionDidChange
        // because view.frame.size will provide the current size, not the newest one.
        viewModel.newSize = size
        if UIDevice.current.userInterfaceIdiom == .pad {
            reloadOnRotation(newSize: size)
        }

        coordinator.animate { sin_ in
            let wallpaperTopConstant: CGFloat = UIWindow.keyWindow?.safeAreaInsets.top ?? self.statusBarFrame?.height ?? 0
            self.wallpaperViewTopConstraint?.constant = -wallpaperTopConstant
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            reloadOnRotation(newSize: viewModel.newSize ?? view.frame.size)
        }

        updateToolbarStateTraitCollectionIfNecessary(traitCollection)
    }

    /// When the trait collection changes the top taps display might have to change
    /// This requires an update of the toolbars.
    private func updateToolbarStateTraitCollectionIfNecessary(_ newCollection: UITraitCollection) {
        let showTopTabs = ToolbarHelper().shouldShowTopTabs(for: newCollection)

        // Only dispatch action when the value of top tabs being shown is different from what is saved in the state
        // to avoid having the toolbar re-displayed
        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID),
              toolbarState.isShowingTopTabs != showTopTabs
        else { return }

        let action = ToolbarAction(
            isShowingTopTabs: showTopTabs,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.traitCollectionDidChange
        )
        store.dispatch(action)
    }

    // MARK: - Layout

    func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds,
                                              collectionViewLayout: createLayout())

        HomepageSectionType.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }
        collectionView.register(LegacyLabelButtonHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: LegacyLabelButtonHeaderView.cellIdentifier)
        collectionView.register(PocketFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: PocketFooterView.cellIdentifier)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.addGestureRecognizer(longPressRecognizer)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView
        collectionView.addInteraction(UIContextMenuInteraction(delegate: self))
        contentStackView.addArrangedSubview(collectionView)

        self.collectionView = collectionView
    }

    func configureContentStackView() {
        view.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func configureWallpaperView() {
        view.addSubview(wallpaperView)

        // Constraint so wallpaper appears under the status bar
        let wallpaperTopConstant: CGFloat = UIWindow.keyWindow?.safeAreaInsets.top ?? statusBarFrame?.height ?? 0
        wallpaperViewTopConstraint = wallpaperView.topAnchor.constraint(equalTo: view.topAnchor,
                                                                        constant: -wallpaperTopConstant)

        wallpaperViewTopConstraint?.isActive = true
        NSLayoutConstraint.activate([
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.sendSubviewToBack(wallpaperView)
    }

    func createLayout() -> UICollectionViewLayout {
        // swiftlint: disable line_length
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment)
            -> NSCollectionLayoutSection? in
        // swiftlint: enable line_length
            guard let self,
                  let viewModel = self.viewModel.getSectionViewModel(shownSection: sectionIndex),
                  viewModel.shouldShow
            // Returning a default section to prevent the app to crash with invalid section definition
            else {
                let shownSection = self?.viewModel.shownSections[safe: sectionIndex]
                self?.logger.log("The current section index: \(sectionIndex) didn't load a valid section. The associated section type if present is: \(String(describing: shownSection))",
                                 level: .fatal,
                                 category: .legacyHomepage)
                return Self.makeEmptyLayoutSection()
            }
            logger.log(
                "Section \(viewModel.sectionType) is going to show",
                level: .debug,
                category: .legacyHomepage
            )
            return viewModel.section(
                for: layoutEnvironment.traitCollection,
                size: self.view.frame.size
            )
        }
        return layout
    }

    // making the method static so in the create layout we return always a valid layout
    // even when self is nil to avoid app crash
    private static func makeEmptyLayoutSection() -> NSCollectionLayoutSection {
        let zeroLayoutSize = NSCollectionLayoutSize(widthDimension: .absolute(0.0),
                                                    heightDimension: .absolute(0.0))
        let emptyGroup = NSCollectionLayoutGroup.horizontal(layoutSize: zeroLayoutSize,
                                                            subitems: [NSCollectionLayoutItem(layoutSize: zeroLayoutSize)])
        return NSCollectionLayoutSection(group: emptyGroup)
    }

    // MARK: Long press

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc
    fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let collectionView,
              let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler
        else { return }

        viewModel.handleLongPress(with: collectionView, indexPath: indexPath)
    }

    // MARK: - Helpers

    /// Configure isZeroSearch
    /// - Parameter isZeroSearch: IsZeroSearch is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar. Inline is false when
    /// it's the zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    /// This needs to be set properly for telemetry and the contextual pop overs that appears on homepage
    func configure(isZeroSearch: Bool) {
        viewModel.isZeroSearch = isZeroSearch
    }

    /// On iPhone, we call reloadOnRotation when the trait collection has changed, to ensure calculation is
    /// done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We reloadOnRotation from viewWillTransition in that case.
    private func reloadOnRotation(newSize: CGSize) {
        logger.log("Reload on rotation to new size \(newSize)", level: .info, category: .legacyHomepage)

        if presentedViewController as? PhotonActionSheet != nil {
            presentedViewController?.dismiss(animated: false, completion: nil)
        }

        // Force the entire collection view to re-layout
        viewModel.refreshData(for: traitCollection, size: newSize)
        collectionView?.reloadData()
        collectionView?.collectionViewLayout.invalidateLayout()

        // This pushes a reload to the end of the main queue after all the work associated with
        // rotating has been completed. This is important because some of the cells layout are
        // based on the screen state
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

    private func adjustPrivacySensitiveSections(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let isPrivate = dict[Tab.privateModeKey] as? Bool
        else { return }

        let privacySectionState = isPrivate ? "Removing": "Adding"
        logger.log("\(privacySectionState) privacy sensitive sections", level: .info, category: .legacyHomepage)
        viewModel.isPrivate = isPrivate
        reloadView()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        viewModel.theme = theme
        view.backgroundColor = theme.colors.layer1
    }

    // called when the homepage is displayed to make sure it's scrolled to top
    func scrollToTop(animated: Bool = false) {
        guard let collectionView else { return }

        collectionView.setContentOffset(.zero, animated: animated)
        handleScroll(collectionView, isUserInteraction: false)
    }

    @objc
    private func dismissKeyboard() {
        /* homepage and error page, both are "internal" url, making
           topsites on homepage inaccessible from error page
           when address bar is selected hence using "about/home".
        */
        if currentTab?.lastKnownUrl?.absoluteString.hasPrefix("\(InternalURL.baseUrl)/\(AboutHomeHandler.path)") ?? false {
            overlayManager.cancelEditing(shouldCancelLoading: false)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
        handleToolbarStateOnScroll()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScroll(scrollView, isUserInteraction: true)
    }

    private func handleToolbarStateOnScroll() {
        guard featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly) else { return }
        // When the user scrolls the homepage (not overlaid on a webpage when searching) we cancel edit mode
        if let selectedTab = tabManager.selectedTab,
           selectedTab.isFxHomeTab,
           selectedTab.url?.displayURL == nil {
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
            store.dispatch(action)
            // On a website we just dismiss the keyboard
        } else {
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.hideKeyboard)
            store.dispatch(action)
        }
    }

    private func handleScroll(_ scrollView: UIScrollView, isUserInteraction: Bool) {
        // We only handle status bar overlay alpha if there's a wallpaper applied on the homepage
        if WallpaperManager().currentWallpaper.hasImage {
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            statusBarScrollDelegate?.scrollViewDidScroll(scrollView,
                                                         statusBarFrame: statusBarFrame,
                                                         theme: theme)
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

    private func showSiteWithURLHandler(_ url: URL, isGoogleTopSite: Bool = false) {
        let visitType = VisitType.bookmark
        // Called from top sites, pocket, learn more in pocket section
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
    }

    func displayWallpaperSelector() {
        let wallpaperManager = WallpaperManager(userDefaults: userDefaults)
        guard !overlayManager.inOverlayMode,
              wallpaperManager.canOnboardingBeShown(using: viewModel.profile),
              canModalBePresented
        else { return }

        let viewModel = WallpaperSelectorViewModel(wallpaperManager: wallpaperManager)
        let viewController = WallpaperSelectorViewController(viewModel: viewModel, windowUUID: windowUUID)
        var bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.closeButton
        )
        bottomSheetViewModel.shouldDismissForTapOutside = false
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController,
            windowUUID: windowUUID
        )

        self.present(bottomSheetVC, animated: false, completion: nil)
        userDefaults.set(true, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
    }

    // Check if we already present something on top of the homepage, if the homepage is actually
    // being shown to the user and if the page is shown from a loaded webpage (zero search).
    private var canModalBePresented: Bool {
        return presentedViewController == nil && viewModel.isZeroSearch
    }

    // MARK: - Contextual hint

    private func prepareJumpBackInContextualHint(onView headerView: LegacyLabelButtonHeaderView) {
        guard jumpBackInContextualHintViewController.shouldPresentHint(),
              !viewModel.shouldDisplayHomeTabBanner,
              !headerView.frame.isEmpty,
              let collectionView
        else { return }

        // Calculate label header view frame to add as source rect for CFR
        var rect = headerView.convert(headerView.titleLabel.frame, to: collectionView)
        rect = collectionView.convert(rect, to: view)

        jumpBackInContextualHintViewController.configure(
            anchor: view,
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                guard let self else { return }
                self.presentContextualHint(contextualHintViewController: self.jumpBackInContextualHintViewController)
            },
            sourceRect: rect,
            andActionForButton: { [weak self] in self?.openInactiveTabsSettings() },
            overlayState: overlayManager)
    }

    private func prepareSyncedTabContextualHint(onCell cell: LegacySyncedTabCell) {
        guard syncTabContextualHintViewController.shouldPresentHint()
        else {
            syncTabContextualHintViewController.unconfigure()
            return
        }

        syncTabContextualHintViewController.configure(
            anchor: cell.getContextualHintAnchor(),
            withArrowDirection: .down,
            andDelegate: self,
            presentedUsing: { [weak self] in
                guard let self else { return }
                self.presentContextualHint(contextualHintViewController: self.syncTabContextualHintViewController)
            },
            overlayState: overlayManager)
    }

    @objc
    private func presentContextualHint(contextualHintViewController: ContextualHintViewController) {
        guard viewModel.viewAppeared, canModalBePresented else {
            contextualHintViewController.stopTimer()
            return
        }
        contextualHintViewController.isPresenting = true
        present(contextualHintViewController, animated: true, completion: nil)

        UIAccessibility.post(notification: .layoutChanged, argument: contextualHintViewController)
    }
}

// MARK: - CollectionView Data Source

extension LegacyHomepageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = UICollectionReusableView()
        if kind == UICollectionView.elementKindSectionHeader {
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LegacyLabelButtonHeaderView.cellIdentifier,
                for: indexPath) as? LegacyLabelButtonHeaderView else { return reusableView }
            guard let sectionViewModel = viewModel.getSectionViewModel(shownSection: indexPath.section)
            else { return reusableView }

            // Configure header only if section is shown
            // swiftlint:disable line_length
            let headerViewModel = sectionViewModel.shouldShow ? sectionViewModel.headerViewModel : LabelButtonHeaderViewModel.emptyHeader
            // swiftlint:enable line_length
            headerView.configure(viewModel: headerViewModel,
                                 theme: themeManager.getCurrentTheme(for: windowUUID))

            // Jump back in header specific setup
            if sectionViewModel.sectionType == .jumpBackIn {
                self.viewModel.jumpBackInViewModel.sendImpressionTelemetry()
                // Moving called after header view gets configured
                // and delaying to wait for header view layout readjust
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.prepareJumpBackInContextualHint(onView: headerView)
                }
            }
            return headerView
        }

        if kind == UICollectionView.elementKindSectionFooter {
            guard let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PocketFooterView.cellIdentifier,
                for: indexPath) as? PocketFooterView else { return reusableView }
            footerView.onTapLearnMore = {
                guard let learnMoreURL = SupportUtils.URLForPocketLearnMore else {
                    self.logger.log("Failed to retrieve learn more URL from SupportUtils.URLForPocketLearnMore",
                                    level: .debug,
                                    category: .legacyHomepage)
                    return
                }
                self.showSiteWithURLHandler(learnMoreURL)
            }
            footerView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            return footerView
        }
        return reusableView
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.shouldReloadView { reloadView() }
        return viewModel.shownSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getSectionViewModel(shownSection: section)?.numberOfItemsInSection() ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let viewModel = viewModel.getSectionViewModel(
            shownSection: indexPath.section
        ) as? HomepageSectionHandler else {
            return UICollectionViewCell()
        }

        return viewModel.configure(collectionView, at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel.getSectionViewModel(
            shownSection: indexPath.section
        ) as? HomepageSectionHandler else { return }
        viewModel.didSelectItem(
            at: indexPath,
            homePanelDelegate: homePanelDelegate,
            libraryPanelDelegate: libraryPanelDelegate
        )
    }
}

// MARK: - Actions Handling

private extension LegacyHomepageViewController {
    // Setup all the tap and long press actions on cells in each sections
    private func setupSectionsAction() {
        // Header view
        viewModel.headerViewModel.onTapAction = { _ in
            // No action currently set if the logo button is tapped.
        }

        // Message card
        viewModel.messageCardViewModel.dismissClosure = { [weak self] in
            self?.reloadView()
        }

        // Top sites
        viewModel.topSiteViewModel.tilePressedHandler = { [weak self] site, isGoogle in
            guard let url = site.url.asURL else { return }
            self?.showSiteWithURLHandler(url, isGoogleTopSite: isGoogle)
        }

        viewModel.topSiteViewModel.tileLongPressedHandler = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(
                for: site,
                with: sourceView,
                sectionType: .topSites
            )
        }

        // Bookmarks
        viewModel.bookmarksViewModel.headerButtonAction = { [weak self] button in
            self?.openBookmarks(button)
        }

        viewModel.bookmarksViewModel.onLongPressTileAction = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(
                for: site,
                with: sourceView,
                sectionType: .bookmarks
            )
        }

        // Jumpback in
        viewModel.jumpBackInViewModel.headerButtonAction = { [weak self] button in
            self?.openTabTray(button)
        }

        viewModel.jumpBackInViewModel.onLongPressTileAction = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(
                for: site,
                with: sourceView,
                sectionType: .bookmarks
            )
        }

        viewModel.jumpBackInViewModel.syncedTabsShowAllAction = { [weak self] in
            self?.homePanelDelegate?.homePanelDidRequestToOpenTabTray(focusedSegment: .syncedTabs)

            var extras: [String: String]?
            if let isZeroSearch = self?.viewModel.isZeroSearch {
                extras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionSyncedTabShowAll,
                                         extras: extras)
        }

        viewModel.jumpBackInViewModel.openSyncedTabAction = { [weak self] tabURL in
            self?.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(
                tabURL,
                isPrivate: false,
                selectNewTab: true
            )

            var extras: [String: String]?
            if let isZeroSearch = self?.viewModel.isZeroSearch {
                extras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
            }
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionSyncedTabOpened,
                                         extras: extras)
        }

        viewModel.jumpBackInViewModel.prepareContextualHint = { [weak self] syncedTabCell in
            self?.prepareSyncedTabContextualHint(onCell: syncedTabCell)
        }

        // History highlights
        viewModel.historyHighlightsViewModel.onTapItem = { [weak self] highlight in
            guard let url = highlight.siteUrl else {
                self?.openHistoryHighlightsSearchGroup(item: highlight)
                return
            }

            self?.homePanelDelegate?.homePanel(didSelectURL: url,
                                               visitType: .link,
                                               isGoogleTopSite: false)
        }

        viewModel.historyHighlightsViewModel
            .historyHighlightLongPressHandler = { [weak self] (highlightItem, sourceView) in
                self?.contextMenuHelper.presentContextMenu(for: highlightItem,
                                                           with: sourceView,
                                                           sectionType: .historyHighlights)
            }

        viewModel.historyHighlightsViewModel.headerButtonAction = { [weak self] button in
            self?.openHistory(button)
        }

        // Pocket
        viewModel.pocketViewModel.onTapTileAction = { [weak self] url in
            self?.showSiteWithURLHandler(url)
        }

        viewModel.pocketViewModel.onLongPressTileAction = { [weak self] (site, sourceView) in
            self?.contextMenuHelper.presentContextMenu(for: site, with: sourceView, sectionType: .pocket)
        }

        // Customize home
        viewModel.customizeButtonViewModel.onTapAction = { [weak self] _ in
            self?.openCustomizeHomeSettings()
        }
    }

    private func openHistoryHighlightsSearchGroup(item: HighlightItem) {
        guard let groupItem = item.group else { return }

        var groupedSites = [Site]()
        for item in groupItem {
            groupedSites.append(buildSite(from: item))
        }
        let groupSite = ASGroup<Site>(searchTerm: item.displayTitle, groupedItems: groupedSites, timestamp: Date.now())

        let asGroupListViewModel = SearchGroupedItemsViewModel(asGroup: groupSite, presenter: .recentlyVisited)
        let asGroupListVC = SearchGroupedItemsViewController(
            viewModel: asGroupListViewModel,
            profile: viewModel.profile,
            windowUUID: windowUUID
        )

        let dismissableController: DismissableNavigationViewController
        dismissableController = DismissableNavigationViewController(rootViewController: asGroupListVC)

        self.present(dismissableController, animated: true, completion: nil)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .historyHighlightsGroupOpen,
                                     extras: nil)

        asGroupListVC.libraryPanelDelegate = libraryPanelDelegate
    }

    private func buildSite(from highlight: HighlightItem) -> Site {
        let itemURL = highlight.urlString ?? ""
        return Site.createBasicSite(url: itemURL, title: highlight.displayTitle)
    }

    func openTabTray(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenTabTray(withFocusedTab: nil)

        if sender.accessibilityIdentifier == a11y.MoreButtons.jumpBackIn {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .jumpBackInSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openBookmarks(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)

        if sender.accessibilityIdentifier == a11y.MoreButtons.bookmarks {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .bookmarkSectionShowAll,
                                         extras: TelemetryWrapper.getOriginExtras(isZeroSearch: viewModel.isZeroSearch))
        }
    }

    func openHistory(_ sender: UIButton) {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)

        if sender.accessibilityIdentifier == a11y.MoreButtons.historyHighlights {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .firefoxHomepage,
                                         value: .historyHighlightsShowAll)
        }
    }

    func openCustomizeHomeSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .homePage)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .firefoxHomepage,
                                     value: .customizeHomepageButton)
    }

    func openInactiveTabsSettings() {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: .browser)
    }

    func getPopoverSourceRect(sourceView: UIView?) -> CGRect {
        let cellRect = sourceView?.frame ?? .zero
        let cellFrameInSuperview = self.collectionView?.convert(cellRect, to: self.collectionView) ?? .zero

        return CGRect(origin: CGPoint(x: cellFrameInSuperview.size.width / 2,
                                      y: cellFrameInSuperview.height / 2),
                      size: .zero)
    }
}

// MARK: FirefoxHomeContextMenuHelperDelegate
extension LegacyHomepageViewController: HomepageContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool) {
        homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenSettings(at settingsPage: Route.SettingsSection) {
        homePanelDelegate?.homePanelDidRequestToOpenSettings(at: settingsPage)
    }

    func homePanelDidRequestBookmarkToast(urlString: String?, action: BookmarkAction) {
        homePanelDelegate?.homePanelDidRequestBookmarkToast(urlString: urlString, action: action)
    }
}

// MARK: - Status Bar Background

extension LegacyHomepageViewController {
    var statusBarFrame: CGRect? {
        guard let keyWindow = UIWindow.keyWindow else { return nil }

        return keyWindow.windowScene?.statusBarManager?.statusBarFrame
    }
}

// MARK: - Popover Presentation Delegate

extension LegacyHomepageViewController: UIPopoverPresentationControllerDelegate {
    // Dismiss the popover if the device is being rotated.
    // This is used by the Share UIActivityViewController action sheet on iPad
    func popoverPresentationController(
        _ popoverPresentationController: UIPopoverPresentationController,
        willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>,
        in view: AutoreleasingUnsafeMutablePointer<UIView>
    ) {
        // Do not dismiss if the popover is a CFR
        guard !jumpBackInContextualHintViewController.isPresenting &&
                !syncTabContextualHintViewController.isPresenting else { return }
        popoverPresentationController.presentedViewController.dismiss(animated: false, completion: nil)
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return true
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension LegacyHomepageViewController: UIContextMenuInteractionDelegate {
    // Handles iPad trackpad right clicks
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        let locationInCollectionView = interaction.location(in: collectionView)
        guard let collectionView,
              let indexPath = collectionView.indexPathForItem(at: locationInCollectionView),
              let viewModel = viewModel.getSectionViewModel(shownSection: indexPath.section) as? HomepageSectionHandler
        else { return nil }

        viewModel.handleLongPress(with: collectionView, indexPath: indexPath)
        return nil
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension LegacyHomepageViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}

// MARK: FirefoxHomeViewModelDelegate
extension LegacyHomepageViewController: HomepageViewModelDelegate {
    func reloadView() {
        ensureMainThread { [weak self] in
            guard let self else { return }

            self.viewModel.refreshData(for: self.traitCollection, size: self.view.frame.size)
            self.collectionView?.reloadData()
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.logger.log("Amount of sections shown is \(self.viewModel.shownSections.count)",
                            level: .debug,
                            category: .legacyHomepage)
        }
    }
}

// MARK: - Notifiable
extension LegacyHomepageViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            guard let self = self else { return }

            switch notification.name {
            case .TabsPrivacyModeChanged:
                guard windowUUID == notification.windowUUID else { return }
                self.adjustPrivacySensitiveSections(notification: notification)

            case .HomePanelPrefsChanged,
                    .WallpaperDidChange:
                self.reloadView()

            default: break
            }
        }
    }
}
