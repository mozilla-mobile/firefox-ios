// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux
import MenuKit
import SiteImageView

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
        static let hintViewHeight: CGFloat = 140
        static let hintViewMargin: CGFloat = 20
    }
    typealias SubscriberStateType = MainMenuState

    // MARK: - UI/UX elements
    private lazy var menuContent: MenuMainView = .build()
    private var hintView: ContextualHintView = .build { view in
        view.isAccessibilityElement = true
    }
    private var hintViewHeightConstraint: NSLayoutConstraint?

    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var coordinator: MainMenuCoordinator?

    private let windowUUID: WindowUUID
    private let profile: Profile
    private var menuState: MainMenuState
    private let logger: Logger

    let viewProvider: ContextualHintViewProvider

    var currentWindowUUID: UUID? { return windowUUID }

    private var isPad: Bool {
        traitCollection.verticalSizeClass == .regular &&
        !(UIDevice.current.userInterfaceIdiom == .phone)
    }

    // Used to save the last screen orientation
    private var lastOrientation: UIDeviceOrientation

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
        self.lastOrientation = UIDevice.current.orientation
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        subscribeToRedux()
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.didInstantiateView
            )
        )
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
                    actionType: MainMenuActionType.tapCloseMenu,
                    currentTabInfo: menuState.currentTabInfo
                )
            )
        }

        menuContent.accountHeaderView.mainButtonCallback = { [weak self] in
            guard let self else { return }
            store.dispatch(
                MainMenuAction(
                    windowUUID: self.windowUUID,
                    actionType: MainMenuActionType.tapNavigateToDestination,
                    navigationDestination: MenuNavigationDestination(.syncSignIn),
                    currentTabInfo: menuState.currentTabInfo
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
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            // We should dismiss CFR when device is rotating
            if UIDevice.current.orientation != lastOrientation {
                lastOrientation = UIDevice.current.orientation
                self.adjustLayout(isDeviceRotating: true)
            } else {
                self.adjustLayout()
            }
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
            if isPad {
                NSLayoutConstraint.activate([
                    hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.hintViewMargin * 4),
                    hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.hintViewMargin * 4),
                    hintView.topAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                                  constant: UX.hintViewMargin)
                ])
            } else {
                NSLayoutConstraint.activate([
                    hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.hintViewMargin),
                    hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.hintViewMargin),
                    hintView.bottomAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                                     constant: -UX.hintViewMargin)
                ])
            }
            hintViewHeightConstraint = hintView.heightAnchor.constraint(equalToConstant: UX.hintViewHeight)
            hintViewHeightConstraint?.isActive = true
        }
        hintView.layer.cornerRadius = UX.hintViewCornerRadius
        hintView.layer.masksToBounds = true
        adjustLayout()
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

        if let accountData = menuState.accountData {
            updateHeaderWith(accountData: accountData, icon: menuState.accountIcon)
            setupAccessibilityIdentifiers(mainButtonA11yLabel: accountData.title)
        }

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

    private func updateHeaderWith(accountData: AccountData, icon: UIImage?) {
        menuContent.accountHeaderView.setupDetails(subtitle: accountData.subtitle ?? "",
                                                   title: accountData.title,
                                                   icon: icon,
                                                   warningIcon: accountData.warningIcon,
                                                   theme: themeManager.getCurrentTheme(for: windowUUID))
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

    private func setupAccessibilityIdentifiers(
        mainButtonA11yLabel: String = .MainMenu.Account.AccessibilityLabels.MainButton) {
        menuContent.setupAccessibilityIdentifiers(
            closeButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.CloseButton,
            closeButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.closeButton,
            mainButtonA11yLabel: mainButtonA11yLabel,
            mainButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.mainButton,
            menuA11yId: AccessibilityIdentifiers.MainMenu.mainMenu,
            menuA11yLabel: .MainMenu.TabsSection.AccessibilityLabels.MainMenu)
    }

    private func adjustLayout(isDeviceRotating: Bool = false) {
        menuContent.accountHeaderView.adjustLayout()
        if isDeviceRotating {
            hintView.removeFromSuperview()
        } else {
            if let screenHeight = view.window?.windowScene?.screen.bounds.height {
                let maxHeight: CGFloat = if isPad {
                    view.frame.height / 2
                } else {
                    screenHeight - view.frame.height - UX.hintViewMargin * 4
                }
                let height = min(UIFontMetrics.default.scaledValue(for: UX.hintViewHeight), maxHeight)
                let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
                hintViewHeightConstraint?.constant =
                contentSizeCategory.isAccessibilityCategory ? height : UX.hintViewHeight
            }
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func shouldDisplayHintView() -> Bool {
        // Don't display CFR in landscape mode for iPhones
        if UIDevice.current.isIphoneLandscape {
            return false
        }

        // Don't display CFR for fresh installs for users that never saw before the photon main menu
        if InstallType.get() == .fresh {
            if let photonMainMenuShown = profile.prefs.boolForKey(PrefsKeys.PhotonMainMenuShown),
               photonMainMenuShown {
                return viewProvider.shouldPresentContextualHint()
            }
            viewProvider.markContextualHintPresented()
            return false
        }
        return viewProvider.shouldPresentContextualHint()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.dispatch(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.menuDismissed,
                currentTabInfo: menuState.currentTabInfo
            )
        )
        coordinator?.removeCoordinatorFromParent()
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
