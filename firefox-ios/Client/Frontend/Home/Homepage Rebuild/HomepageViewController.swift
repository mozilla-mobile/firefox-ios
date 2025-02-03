// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared

final class HomepageViewController: UIViewController,
                                    UICollectionViewDelegate,
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
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         overlayManager: OverlayModeManager,
         statusBarScrollDelegate: StatusBarScrollDelegate? = nil,
         toastContainer: UIView,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.overlayManager = overlayManager
        self.statusBarScrollDelegate = statusBarScrollDelegate
        self.toastContainer = toastContainer
        self.logger = logger
        homepageState = HomepageState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification,
                                                          .FirefoxAccountChanged,
                                                          .PrivateDataClearedHistory,
                                                          .ProfileDidFinishSyncing,
                                                          .TopSitesUpdated,
                                                          .DefaultSearchEngineUpdated])
        subscribeToRedux()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
        notificationCenter.removeObserver(self)
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
                showiPadSetup: shouldUseiPadSetup(),
                windowUUID: windowUUID,
                actionType: HomepageActionType.initialize
            )
        )

        listenForThemeChange(view)
        applyTheme()
        addTapGestureRecognizerToDismissKeyboard()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        wallpaperView.updateImageForOrientationChange()
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
        let tiles = TopSitesDimensionCalculator.numberOfTilesPerRow(
            availableWidth: availableWidth,
            leadingInset: HomepageSectionLayoutProvider.UX.leadingInset(
                traitCollection: traitCollection
            )
        )
        return tiles
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
        dataSource?.updateSnapshot(state: state, numberOfCellsPerRow: numberOfTilesPerRow(for: availableWidth))
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

            headerCell.configure(headerState: state) { [weak self] in
                self?.toggleHomepageMode()
            }

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

        case .jumpBackIn(let state):
            guard let jumpBackInCell = collectionView?.dequeueReusableCell(
                cellType: JumpBackInCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            jumpBackInCell.configure(state: state, theme: currentTheme)
            return jumpBackInCell

        case .bookmark(let state):
            guard let bookmarksCell = collectionView?.dequeueReusableCell(
                cellType: BookmarksCell.self,
                for: indexPath
            ) else {
                return UICollectionViewCell()
            }
            bookmarksCell.configure(state: state, theme: currentTheme)
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
                "Item selected at \(point) but does not navigate to context menu",
                level: .debug,
                category: .homepage
            )
            return
        }
        navigateToContextMenu(for: section, and: item, sourceView: sourceView)
    }

    // MARK: Dispatch Actions
    private func toggleHomepageMode() {
        store.dispatch(
            HeaderAction(
                windowUUID: windowUUID,
                actionType: HeaderActionType.toggleHomepageMode
            )
        )
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
                navigationDestination: NavigationDestination(.link, url: homepageState.pocketState.footerURL),
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
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(
                        .link,
                        url: state.site.url.asURL,
                        isGoogleTopSite: state.isGoogleURL
                    ),
                    windowUUID: self.windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
        case .pocket(let story):
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(.link, url: story.url),
                    windowUUID: self.windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
        case .pocketDiscover(let item):
            store.dispatch(
                NavigationBrowserAction(
                    navigationDestination: NavigationDestination(
                        .link,
                        url: item.url
                    ),
                    windowUUID: self.windowUUID,
                    actionType: NavigationBrowserActionType.tapOnCell
                )
            )
        default:
            return
        }
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
        case .ProfileDidFinishSyncing,
                .PrivateDataClearedHistory,
                .FirefoxAccountChanged,
                .TopSitesUpdated,
                .DefaultSearchEngineUpdated:
            store.dispatch(
                TopSitesAction(
                    windowUUID: self.windowUUID,
                    actionType: TopSitesActionType.fetchTopSites
                )
            )
        default: break
        }
    }
}
