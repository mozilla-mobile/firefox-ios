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
                                      Themeable,
                                      DismissalNotifiable {
    struct UX {
        static let shortcutsSectionTopInset: CGFloat = 24
    }

    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: ShortcutsLibraryDiffableDataSource?
    private var shortcutsLibraryState: ShortcutsLibraryState
    private var recordTelemetryOnDisappear = true

    private var currentTheme: Theme {
        themeManager.getCurrentTheme(for: windowUUID)
    }

    // MARK: - Private constants
    private let logger: Logger

    // MARK: - Private variables
    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
    }()

    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: Initializers
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
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            logger.log(
                "MainMenuViewController was not deallocated on the main thread. Redux was not cleaned up.",
                level: .fatal,
                category: .lifecycle
            )
            assertionFailure("The view controller was not deallocated on the main thread. Redux was not cleaned up.")
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
    }

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .FirefoxHomepage.Shortcuts.Library.Title

        configureCollectionView()
        setupLayout()
        configureDataSource()

        store.dispatch(
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(
            ShortcutsLibraryAction(
                windowUUID: windowUUID,
                actionType: ShortcutsLibraryActionType.viewDidAppear
            )
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if recordTelemetryOnDisappear {
            store.dispatch(
                ShortcutsLibraryAction(
                    windowUUID: windowUUID,
                    actionType: ShortcutsLibraryActionType.viewDidDisappear)
            )
        }
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .shortcutsLibrary
        )
        store.dispatch(action)

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
        store.dispatch(action)
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
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

        collectionView.addGestureRecognizer(longPressRecognizer)
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
            let cellType: ReusableCell.Type = TopSiteCell.self

            guard let topSiteCell = collectionView?.dequeueReusableCell(cellType: cellType, for: indexPath) else {
                return UICollectionViewCell()
            }

            if let topSiteCell = topSiteCell as? TopSiteCell {
                topSiteCell.configure(site, position: indexPath.row, theme: currentTheme, textColor: nil)
                return topSiteCell
            }

            return UICollectionViewCell()
        }
    }

    private func navigateToContextMenu(for item: ShortcutsLibraryItem, sourceView: UIView? = nil) {
        guard case let .shortcut(config) = item else { return }

        let configuration = ContextMenuConfiguration(
            site: config.site,
            menuType: .shortcut,
            sourceView: sourceView,
            toastContainer: self.view
        )
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.contextMenu, contextMenuConfiguration: configuration),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.longPressOnCell
            )
        )
    }

    func showOpenedNewTabToast(tab: Tab) {
        let viewModel = ButtonToastViewModel(labelText: ToastType.openNewTab.title,
                                             buttonText: ToastType.openNewTab.buttonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: currentTheme,
                                completion: { buttonPressed in
            if buttonPressed {
                store.dispatch(
                    ShortcutsLibraryAction(
                        tab: tab,
                        windowUUID: self.windowUUID,
                        actionType: ShortcutsLibraryActionType.switchTabToastButtonTapped
                    )
                )
            }
        })

        toast.showToast(viewController: self,
                        delay: Toast.UX.toastDelayBefore,
                        duration: Toast.UX.toastDismissAfter) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Toast.UX.toastSidePadding),
                toast.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Toast.UX.toastSidePadding),
                toast.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ]
        }
        // Offset the toast by its height to prepare for slide-in animation
        toast.transform = CGAffineTransform(translationX: 0, y: toast.frame.height)
        UIView.animate(
            withDuration: ButtonToast.UX.animationDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                toast.transform = .identity
            },
            completion: nil
        )
    }

    // MARK: - Selectors
    @objc
    private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView?.indexPathForItem(at: point),
              let item = dataSource?.itemIdentifier(for: indexPath),
              let sourceView = collectionView?.cellForItem(at: indexPath)
        else {
            self.logger.log(
                "Context menu handling skipped: No valid indexPath, item, section or sourceView found at \(point)",
                level: .debug,
                category: .shortcutsLibrary
            )
            return
        }

        navigateToContextMenu(for: item, sourceView: sourceView)
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else {
            self.logger.log(
                "Item selected at \(indexPath) but does not navigate anywhere",
                level: .debug,
                category: .shortcutsLibrary
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

        recordTelemetryOnDisappear = false

        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: destination,
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnCell
            )
        )
        store.dispatch(
            ShortcutsLibraryAction(
                windowUUID: windowUUID,
                actionType: ShortcutsLibraryActionType.tapOnShortcutCell
            )
        )
    }

    // MARK: - DismissalNotifiable

    func willBeDismissed(reason: DismissalReason) {
        recordTelemetryOnDisappear = false
    }
}
