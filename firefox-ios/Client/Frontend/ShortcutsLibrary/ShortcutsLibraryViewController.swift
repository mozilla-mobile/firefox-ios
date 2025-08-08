// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

class ShortcutsLibraryViewController: UIViewController,
                                      UICollectionViewDelegate,
                                      StoreSubscriber,
                                      Themeable {
    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: ShortcutsLibraryDiffableDataSource?
    private var shortcutsLibraryState: ShortcutsLibraryState

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
         logger: Logger = DefaultLogger.shared,
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

        dataSource?.updateSnapshot(
            state: state,
        )
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
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

        collectionView.backgroundColor = .lightGray
        collectionView.delegate = self

        self.collectionView = collectionView

        view.addSubview(collectionView)
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
            return UICollectionViewCell()
        }
    }
}
