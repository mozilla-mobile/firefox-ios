// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

class StoriesFeedViewController: UIViewController,
                                 StoreSubscriber,
                                 Themeable {
    // MARK: - Private variables
    private var storiesFeedState: StoriesFeedState

    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: - Private constants
    private let logger: Logger

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
        self.storiesFeedState = StoriesFeedState(windowUUID: windowUUID)

        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        store.dispatchLegacy(
            StoriesFeedAction(
                windowUUID: windowUUID,
                actionType: StoriesFeedActionType.initialize
            )
        )

        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar(animated: animated)
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .storiesFeed
        )
        store.dispatchLegacy(action)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return StoriesFeedState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })
    }

    func newState(state: StoriesFeedState) {
        self.storiesFeedState = state
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .storiesFeed
        )
        store.dispatchLegacy(action)
    }

    // MARK: Helper functions
    private func setupNavigationBar(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = .FirefoxHomepage.Pocket.TopStories.TopStoriesViewTitle
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }
}
