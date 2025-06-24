// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux

import enum MozillaAppServices.VisitType

protocol RemoteTabsPanelDelegate: AnyObject {
    func presentFirefoxAccountSignIn()
    func presentFxAccountSettings()
}

protocol RemoteTabsClientAndTabsDataSourceDelegate: AnyObject {
    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType)
}

class RemoteTabsPanel: UIViewController,
                       Themeable,
                       RemoteTabsClientAndTabsDataSourceDelegate,
                       RemoteTabsEmptyViewDelegate,
                       StoreSubscriber,
                       FeatureFlaggable,
                       TabTrayThemeable {
    typealias SubscriberStateType = RemoteTabsPanelState

    // MARK: - Properties

    private(set) var state: RemoteTabsPanelState
    var tableViewController: RemoteTabsTableViewController
    weak var remoteTabsDelegate: RemoteTabsPanelDelegate?

    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    private let windowUUID: WindowUUID
    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    private lazy var statusBarBackground: UIView = .build()

    // MARK: - Initializer

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.state = RemoteTabsPanelState(windowUUID: windowUUID)
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.tableViewController = RemoteTabsTableViewController(state: state, windowUUID: windowUUID)

        super.init(nibName: nil, bundle: nil)

        self.tableViewController.remoteTabsPanel = self
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        unsubscribeFromRedux()
    }

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Actions

    func tableViewControllerDidPullToRefresh() {
        refreshTabs()
    }

    // MARK: - Internal Utilities

    private func refreshTabs(useCache: Bool = false) {
        // Ensure we do not already have a refresh in progress
        guard state.refreshState != .refreshing else { return }
        let actionType = useCache ?
            RemoteTabsPanelActionType.refreshTabsWithCache :
            RemoteTabsPanelActionType.refreshTabs
        let action = RemoteTabsPanelAction(windowUUID: windowUUID,
                                           actionType: actionType)
        store.dispatchLegacy(action)
    }

    // MARK: - View & Layout

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupLayout()
        subscribeToRedux()
        applyTheme()
    }

    private func setupLayout() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        tableViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(tableViewController)
        view.addSubview(tableViewController.view)
        tableViewController.didMove(toParent: self)

        if isTabTrayUIExperimentsEnabled {
            view.addSubview(statusBarBackground)

            NSLayoutConstraint.activate([
                tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

                statusBarBackground.topAnchor.constraint(equalTo: view.topAnchor),
                statusBarBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                statusBarBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                statusBarBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = retrieveTheme()
        view.backgroundColor = theme.colors.layer4
        tableViewController.tableView.backgroundColor = theme.colors.layer3
        tableViewController.tableView.separatorColor = theme.colors.borderPrimary
        statusBarBackground.backgroundColor = theme.colors.layer3
    }

    var shouldUsePrivateOverride: Bool {
        return featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
    }

    var shouldBeInPrivateTheme: Bool {
        return false
    }

    // MARK: - TabTrayThemeable

    func retrieveTheme() -> Theme {
        if shouldUsePrivateOverride {
            return themeManager.resolvedTheme(with: false)
        } else {
            return themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.colors.layer4
        tableViewController.tableView.backgroundColor = theme.colors.layer3
        tableViewController.tableView.separatorColor = theme.colors.borderPrimary
        statusBarBackground.backgroundColor = theme.colors.layer3
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let showScreenAction = ScreenAction(windowUUID: windowUUID,
                                            actionType: ScreenActionType.showScreen,
                                            screen: .remoteTabsPanel)
        store.dispatchLegacy(showScreenAction)

        let didAppearAction = RemoteTabsPanelAction(windowUUID: windowUUID,
                                                    actionType: RemoteTabsPanelActionType.panelDidAppear)
        store.dispatchLegacy(didAppearAction)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return RemoteTabsPanelState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .remoteTabsPanel)
        store.dispatchLegacy(action)
    }

    func newState(state: RemoteTabsPanelState) {
        ensureMainThread { [weak self] in
            guard let self else { return }

            self.state = state
            tableViewController.newState(state: state)
        }
    }

    // MARK: - RemoteTabsClientAndTabsDataSourceDelegate
    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType) {
        handleOpenSelectedURL(url)
    }

    func remoteTabsClientAndTabsDataSourceDidCloseURL(deviceId: String, url: URL) {
        handleCloseRemoteTab(deviceId, url: url)
    }

    func remoteTabsClientAndTabsDataSourceDidUndo(deviceId: String, url: URL) {
        handleUndoCloseTab(deviceId, url: url)
    }

    func remoteTabsClientAndTabsDataSourceDidTabCommandsFlush(deviceId: String) {
        handleTabCommandsFlush(deviceId)
    }

    // MARK: - RemotePanelDelegate
    func remotePanelDidRequestToSignIn() {
        remoteTabsDelegate?.presentFirefoxAccountSignIn()
    }

    func presentFxAccountSettings() {
        remoteTabsDelegate?.presentFxAccountSettings()
    }

    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        handleOpenSelectedURL(url)
    }

    private func handleOpenSelectedURL(_ url: URL) {
        let action = RemoteTabsPanelAction(url: url,
                                           windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.openSelectedURL)
        store.dispatchLegacy(action)
    }

    private func handleCloseRemoteTab(_ deviceId: String, url: URL) {
        let action = RemoteTabsPanelAction(url: url,
                                           targetDeviceId: deviceId,
                                           windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.closeSelectedRemoteURL)
        store.dispatchLegacy(action)
        // Once we add the tab to the command queue, the rust tab store will start removing it from
        // the list, so refresh the tabs
        refreshTabs(useCache: true)
    }

    private func handleUndoCloseTab(_ deviceId: String, url: URL) {
        let action = RemoteTabsPanelAction(url: url,
                                           targetDeviceId: deviceId,
                                           windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.undoCloseSelectedRemoteURL)
        store.dispatchLegacy(action)

        refreshTabs(useCache: true)
    }

    private func handleTabCommandsFlush(_ deviceId: String) {
        let action = RemoteTabsPanelAction(targetDeviceId: deviceId,
                                           windowUUID: windowUUID,
                                           actionType: RemoteTabsPanelActionType.flushTabCommands)
        store.dispatchLegacy(action)

        refreshTabs(useCache: true)
    }
}
