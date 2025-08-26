// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

class ShortcutsLibraryViewController: UIViewController,
                                      UICollectionViewDelegate,
                                      FeatureFlaggable,
                                      StoreSubscriber,
                                      Themeable {
    struct UX {
        static let shortcutsSectionTopInset: CGFloat = 24
    }

    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: ShortcutsLibraryDiffableDataSource?
    private var shortcutsLibraryState: ShortcutsLibraryState

    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    // MARK: - Private constants
    private let logger: Logger

    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.shortcutsLibraryState = ShortcutsLibraryState(windowUUID: windowUUID)

        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .FirefoxHomepage.Shortcuts.Library.Title

        configureCollectionView()
        setupLayout()
        configureDataSource()

        store.dispatchLegacy(
            ShortcutsLibraryAction(
                windowUUID: windowUUID,
                actionType: ShortcutsLibraryActionType.initialize
            )
        )

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .shortcutsLibrary
        )
        store.dispatchLegacy(action)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return ShortcutsLibraryState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })
    }

    func newState(state: ShortcutsLibraryState) {
        self.shortcutsLibraryState = state

        dataSource?.updateSnapshot(state: state)
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .shortcutsLibrary
        )
        store.dispatchLegacy(action)
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
    }

    // MARK: - Setup + Layout
    private func setupLayout() {
        guard let collectionView else {
            logger.log(
                "ShortcutsLibrary collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .shortcutsLibrary
            )
            return
        }

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureCollectionView() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())

        ShortcutsLibraryItem.cellTypes.forEach {
            collectionView.register($0, forCellWithReuseIdentifier: $0.cellIdentifier)
        }

        collectionView.backgroundColor = .clear
        collectionView.delegate = self

        self.collectionView = collectionView

        view.addSubview(collectionView)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self ](sectionIndex, environment)
            -> NSCollectionLayoutSection? in
            guard let self else { return nil }
            let homepageState = store.state.screenState(HomepageState.self, for: .homepage, window: windowUUID)
            let numberOfTilesPerRow = homepageState?.topSitesState.numberOfTilesPerRow ?? 4
            let section = TopSitesSectionLayoutProvider.createTopSitesSectionLayout(
                for: environment.traitCollection,
                numberOfTilesPerRow: numberOfTilesPerRow
            )
            section.contentInsets.top = UX.shortcutsSectionTopInset
            return section
        }
        return layout
    }

    private func configureDataSource() {
        guard let collectionView else {
            logger.log(
                "ShortcutsLibrary collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .shortcutsLibrary
            )
            return
        }

        dataSource = ShortcutsLibraryDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.configureCell(for: item, at: indexPath)
        }
    }

    private func configureCell(
        for item: ShortcutsLibraryItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch item {
        case .shortcut(let site):
            let isTopSitesRefreshEnabled = featureFlags.isFeatureEnabled(.hntTopSitesVisualRefresh, checking: .buildOnly)
            let cellType: ReusableCell.Type = isTopSitesRefreshEnabled ? TopSiteCell.self : LegacyTopSiteCell.self

            guard let topSiteCell = collectionView?.dequeueReusableCell(cellType: cellType, for: indexPath) else {
                return UICollectionViewCell()
            }

            if let topSiteCell = topSiteCell as? TopSiteCell {
                topSiteCell.configure(site, position: indexPath.row, theme: currentTheme, textColor: nil)
                return topSiteCell
            } else if let legacyTopSiteCell = topSiteCell as? LegacyTopSiteCell {
                legacyTopSiteCell.configure(site, position: indexPath.row, theme: currentTheme, textColor: nil)
                return legacyTopSiteCell
            }

            return UICollectionViewCell()
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

        guard case let .shortcut(config) = item else { return }
        let destination = NavigationDestination(
            .link,
            url: config.site.url.asURL,
            isGoogleTopSite: config.isGoogleURL,
            visitType: .link
        )

        store.dispatchLegacy(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: self.windowUUID,
                actionType: NavigationBrowserActionType.tapOnCell
            )
        )
    }
}
