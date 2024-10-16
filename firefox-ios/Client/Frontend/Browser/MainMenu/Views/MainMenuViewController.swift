// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux
import MenuKit

class MainMenuViewController: UIViewController,
                              UIAdaptivePresentationControllerDelegate,
                              UISheetPresentationControllerDelegate,
                              UIScrollViewDelegate,
                              MenuTableViewDataDelegate,
                              Themeable,
                              Notifiable,
                              StoreSubscriber,
                              FeatureFlaggable {
    private struct UX {
        static let hintViewCornerRadius: CGFloat = 20
        static let hintViewHeight: CGFloat = 120
        static let hintViewMargin: CGFloat = 20
    }
    typealias SubscriberStateType = MainMenuState

    // MARK: - UI/UX elements
    private lazy var menuContent: MenuMainView = .build()

    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var coordinator: MainMenuCoordinator?

    private let windowUUID: WindowUUID
    private let profile: Profile
    private var menuState: MainMenuState
    private let logger: Logger

    private var hintView: ContextualHintView = .build()

    let viewProvider: ContextualHintViewProvider

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        profile: Profile,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.profile = profile
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger
        menuState = MainMenuState(windowUUID: windowUUID)
        viewProvider = ContextualHintViewProvider(forHintType: .mainMenu,
                                                  with: profile)
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle & setup
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self

        setupView()
        setupTableView()
        listenForThemeChange(view)
        store.dispatch(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.viewDidLoad
            )
        )

        menuContent.accountHeaderView.closeButtonCallback = { [weak self] in
            guard let self else { return }
            store.dispatch(
                MainMenuAction(
                    windowUUID: self.windowUUID,
                    actionType: MainMenuActionType.closeMenu
                )
            )
        }

    // private func syncMenuButton() -> PhotonRowActions? {
    //     let action: (SingleActionViewModel) -> Void = { [weak self] action in
    //         let fxaParams = FxALaunchParams(entrypoint: .browserMenu, query: [:])
    //         let parameters = FxASignInViewParameters(launchParameters: fxaParams,
    //                                                  flowType: .emailLoginFlow,
    //                                                  referringPage: .appMenu)
    //         self?.delegate?.showSignInView(fxaParameters: parameters)
    //         TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
    //     }
    //
    //     let rustAccount = RustFirefoxAccounts.shared
    //     let needsReAuth = rustAccount.accountNeedsReauth()
    //
    //     guard let userProfile = rustAccount.userProfile else {
    //         return SingleActionViewModel(title: .LegacyAppMenu.SyncAndSaveData,
    //                                      iconString: StandardImageIdentifiers.Large.sync,
    //                                      tapHandler: action).items
    //     }
    //
    //     let title: String = {
    //         if rustAccount.accountNeedsReauth() {
    //             return .FxAAccountVerifyPassword
    //         }
    //         return userProfile.displayName ?? userProfile.email
    //     }()
    //
    //     let warningImage = StandardImageIdentifiers.Large.warningFill
    //     let avatarImage = StandardImageIdentifiers.Large.avatarCircle
    //     let iconString = needsReAuth ? warningImage : avatarImage
    //
    //     var iconURL: URL?
    //     if let str = rustAccount.userProfile?.avatarUrl,
    //         let url = URL(string: str, invalidCharacters: false) {
    //         iconURL = url
    //     }
    //     let iconType: PhotonActionSheetIconType = needsReAuth ? .Image : .URL
    //     let syncOption = SingleActionViewModel(title: title,
    //                                            iconString: iconString,
    //                                            iconURL: iconURL,
    //                                            iconType: iconType,
    //                                            needsIconActionableTint: needsReAuth,
    //                                            tapHandler: action).items
    //     return syncOption
    // }
        menuContent.accountHeaderView.mainButtonCallback = { [weak self] in
            guard let self else { return }
            store.dispatch(
                MainMenuAction(
                    windowUUID: self.windowUUID,
                    actionType: MainMenuActionType.closeMenuAndNavigateToDestination,
                    navigationDestination: MenuNavigationDestination(
                        .syncSignIn,
                        fxaSingInViewParameters: FxASignInViewParameters(
                            launchParameters: FxALaunchParams(
                                entrypoint: .browserMenu,
                                query: [:]
                            ),
                            flowType: .emailLoginFlow,
                            referringPage: .appMenu
                        )
                    )
                )
            )
        }

        setupAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateModalA11y()

        if shouldDisplayHintView() {
            setupHintView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hintView.removeFromSuperview()
    }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    // MARK: - UI setup
    private func setupTableView() {
        reloadTableView(with: menuState.menuElements)
    }

    private func setupView() {
        view.addSubview(menuContent)

        NSLayoutConstraint.activate([
            menuContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuContent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            menuContent.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuContent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        let icon = UIImage(named: StandardImageIdentifiers.Large.avatarCircle)?
            .withRenderingMode(.alwaysTemplate)
        menuContent.setupDetails(subtitle: .MainMenu.Account.SignedOutDescription,
                                 title: .MainMenu.Account.SignedOutTitle,
                                 icon: icon)
    }

    private func setupHintView() {
        var viewModel = ContextualHintViewModel(
            isActionType: viewProvider.isActionType,
            actionButtonTitle: viewProvider.getCopyFor(.action),
            title: viewProvider.getCopyFor(.title),
            description: viewProvider.getCopyFor(.description),
            arrowDirection: .unknown,
            closeButtonA11yLabel: .ContextualHints.ContextualHintsCloseAccessibility,
            actionButtonA11yId: AccessibilityIdentifiers.ContextualHints.actionButton
        )
        viewModel.closeButtonAction = { [weak self] _ in
            self?.hintView.removeFromSuperview()
        }
        hintView.configure(viewModel: viewModel)
        viewProvider.markContextualHintPresented()
        hintView.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(hintView)
            NSLayoutConstraint.activate([
                hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.hintViewMargin),
                hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.hintViewMargin),
                hintView.bottomAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                                 constant: -UX.hintViewMargin),
                hintView.heightAnchor.constraint(equalToConstant: UX.hintViewHeight)
            ])
        }
        hintView.layer.cornerRadius = UX.hintViewCornerRadius
        hintView.layer.masksToBounds = true
    }

    // MARK: - Redux
    func subscribeToRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.showScreen,
                screen: .mainMenu
            )
        )
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return MainMenuState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.closeScreen,
                screen: .mainMenu
            )
        )
    }

    func newState(state: MainMenuState) {
        menuState = state

        if menuState.currentSubmenuView != nil {
            coordinator?.showDetailViewController()
            return
        }

        if let navigationDestination = menuState.navigationDestination {
            coordinator?.navigateTo(navigationDestination, animated: true)
            return
        }

        if menuState.shouldDismiss {
            coordinator?.dismissMenuModal(animated: true)
            return
        }

        reloadTableView(with: menuState.menuElements)
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer3
        menuContent.applyTheme(theme: theme)
    }

    // MARK: - A11y
    // In iOS 15 modals with a large detent read content underneath the modal
    // in voice over. To prevent this we manually turn this off.
    private func updateModalA11y() {
        var currentDetent: UISheetPresentationController.Detent.Identifier? = getCurrentDetent(
            for: sheetPresentationController
        )

        if currentDetent == nil,
           let sheetPresentationController,
           let firstDetent = sheetPresentationController.detents.first {
            if firstDetent == .medium() {
                currentDetent = .medium
            } else if firstDetent == .large() {
                currentDetent = .large
            }
        }

        view.accessibilityViewIsModal = currentDetent == .large ? true : false
    }

    private func getCurrentDetent(
        for presentedController: UIPresentationController?
    ) -> UISheetPresentationController.Detent.Identifier? {
        guard let sheetController = presentedController as? UISheetPresentationController else { return nil }
        return sheetController.selectedDetentIdentifier
    }

    private func setupAccessibilityIdentifiers() {
        menuContent.setupAccessibilityIdentifiers(
            closeButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.CloseButton,
            closeButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.closeButton,
            mainButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.MainButton,
            mainButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.mainButton,
            menuA11yId: AccessibilityIdentifiers.MainMenu.mainMenu,
            menuA11yLabel: .MainMenu.TabsSection.AccessibilityLabels.MainMenu)
    }

    private func adjustLayout() {
        menuContent.accountHeaderView.adjustLayout()
    }

    private func shouldDisplayHintView() -> Bool {
        // 1. Present hint if it was not presented before,
        // 2. feature is enabled and
        // 3. is not fresh install
        if viewProvider.shouldPresentContextualHint() &&
            featureFlags.isFeatureEnabled(.menuRefactorHint, checking: .buildOnly) &&
            InstallType.get() != .fresh {
            return true
        }
        return false
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        coordinator?.dismissMenuModal(animated: true)
    }

    // MARK: - UISheetPresentationControllerDelegate
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        hintView.removeFromSuperview()
        updateModalA11y()
    }

    // MARK: - MenuTableViewDelegate
    func reloadTableView(with data: [MenuSection]) {
        menuContent.reloadTableView(with: data)
    }
}
