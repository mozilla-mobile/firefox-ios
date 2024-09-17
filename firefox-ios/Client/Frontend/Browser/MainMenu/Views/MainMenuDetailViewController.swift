// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MenuKit
import Redux
import UIKit

class MainMenuDetailViewController: UIViewController,
                                    MainMenuDetailNavigationHandler,
                                    MenuTableViewDataDelegate,
                                    Notifiable,
                                    StoreSubscriber {
    typealias StoreSubscriberType = MainMenuDetailsState

    // MARK: - UI/UX elements
    private lazy var submenuContent: MenuDetailView = .build()

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var coordinator: MainMenuCoordinator?

    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }
    var submenuState: MainMenuDetailsState

    var submenuData: [MenuSection]

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        with data: [MenuSection],
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.submenuData = data
        self.submenuState = MainMenuDetailsState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupTableView()
        submenuContent.setupHeaderNavigation(from: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
        submenuContent.applyTheme(theme: theme)
    }

    private func setupView() {
        view.addSubview(submenuContent)

        NSLayoutConstraint.activate([
            submenuContent.topAnchor.constraint(equalTo: view.topAnchor),
            submenuContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            submenuContent.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            submenuContent.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTableView() {
        reloadTableView(with: submenuData)
    }

    // MARK: - Redux
    func subscribeToRedux() {
        store.dispatch(
            ScreenAction(windowUUID: windowUUID,
                         actionType: ScreenActionType.showScreen,
                         screen: .mainMenuDetails)
        )

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return MainMenuDetailsState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .mainMenu)
        store.dispatch(action)
    }

    func newState(state: MainMenuDetailsState) {
        submenuState = state

        reloadTableView(with: submenuState.menuElements)
    }

    // MARK: - TableViewDelegates
    func reloadTableView(with data: [MenuSection]) {
        submenuContent.reloadTableView(with: data)
    }

    // MARK: - MainMenuDetailNavigationHandler
    func backToMainView() {
        coordinator?.dismissDetailViewController()
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) { }
}
