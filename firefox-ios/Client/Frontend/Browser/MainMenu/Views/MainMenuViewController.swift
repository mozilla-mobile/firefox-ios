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
                              Themeable,
                              Notifiable,
                              StoreSubscriber,
                              FeatureFlaggable {
    private struct UX {
        static let hintViewCornerRadius: CGFloat = 20
        static let hintViewHeight: CGFloat = 140
        static let hintViewMargin: CGFloat = 20
        static let backgroundAlpha: CGFloat = 0.8
        static let menuHeightTolerance: CGFloat = 30
    }
    typealias SubscriberStateType = MainMenuState

    // MARK: - UI/UX elements
    // Based on the isMenuRedesign flag, we have two versions of the menu
    private lazy var menuRedesignContent: MenuRedesignMainView = .build()
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

    var viewProvider: ContextualHintViewProvider?

    var currentWindowUUID: UUID? { return windowUUID }

    private var isPad: Bool {
        traitCollection.verticalSizeClass == .regular &&
        !(UIDevice.current.userInterfaceIdiom == .phone)
    }

    private var isMenuRedesign: Bool {
        return featureFlags.isFeatureEnabled(.menuRedesign, checking: .buildOnly)
    }

    private var isMenuDefaultBrowserBanner: Bool {
        return featureFlags.isFeatureEnabled(.menuDefaultBrowserBanner, checking: .buildOnly)
    }

    private var bannerShown: Bool {
        profile.prefs.boolForKey(PrefsKeys.defaultBrowserBannerShown) ?? false
    }

    private var hasBeenExpanded = false
    private var currentCustomMenuHeight = 0.0
    private var isBrowserDefault = false
    private var isPhoneLandscape = false

    private var isHomepage: Bool {
        guard let element = menuState.menuElements.first(where: { $0.isHomepage }) else { return false }
        return element.isHomepage
    }

    private var isExpanded: Bool {
        guard let element = menuState.menuElements.first(where: { $0.isExpanded ?? false }),
              let isExpanded = element.isExpanded else { return false }
        return isExpanded
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
        self.lastOrientation = UIDevice.current.orientation
        super.init(nibName: nil, bundle: nil)

        if isMenuRedesign {
            viewProvider = ContextualHintViewProvider(forHintType: .mainMenuRedesign,
                                                      with: profile)
        } else {
            viewProvider = ContextualHintViewProvider(forHintType: .mainMenu,
                                                      with: profile)
        }

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle & setup
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self

        subscribeToRedux()
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.didInstantiateView
            )
        )

        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.updateMenuAppearance
            )
        )

        if isMenuRedesign {
            setupRedesignView()
            setupMenuOrientation()
        } else {
            setupView()
        }
        setupTableView()
        listenForThemeChange(view)
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.viewDidLoad
            )
        )

        if isMenuRedesign {
            menuRedesignContent.siteProtectionHeader.closeButtonCallback = { [weak self] in
                self?.dispatchCloseMenuAction()
            }

            menuRedesignContent.onCalculatedHeight = { [weak self] height, isExpanded in
                let customHeight: CGFloat = self?.currentCustomMenuHeight ?? 0
                if (height > customHeight + UX.menuHeightTolerance) || (height < customHeight - UX.menuHeightTolerance) {
                    self?.currentCustomMenuHeight = height
                    if #available(iOS 16.0, *) {
                        let customDetent = UISheetPresentationController.Detent.custom { context in
                            return height
                        }
                        if isExpanded {
                            self?.sheetPresentationController?.animateChanges({
                                self?.sheetPresentationController?.detents = [customDetent]
                            })
                        } else {
                            self?.sheetPresentationController?.detents = [customDetent]
                        }
                    }
                }
            }

            menuRedesignContent.bannerButtonCallback = { [weak self] in
                self?.dispatchDefaultBrowserAction()
            }

            menuRedesignContent.closeBannerButtonCallback = { [weak self] in
                self?.profile.prefs.setBool(true, forKey: PrefsKeys.defaultBrowserBannerShown)
            }

            menuRedesignContent.siteProtectionHeader.siteProtectionsButtonCallback = { [weak self] in
                self?.dispatchSiteProtectionAction()
            }

            menuRedesignContent.closeButtonCallback = { [weak self] in
                self?.dispatchCloseMenuAction()
            }
        } else {
            menuContent.accountHeaderView.closeButtonCallback = { [weak self] in
                self?.dispatchCloseMenuAction()
            }

            menuContent.accountHeaderView.mainButtonCallback = { [weak self] in
                self?.dispatchSyncSignInAction()
            }
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

        if shouldDisplayHintView(isMenuRedesign: isMenuRedesign) {
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
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.updateMenuAppearance
            )
        )
        setupMenuOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            // We should dismiss CFR when device is rotating
            if UIDevice.current.orientation != self?.lastOrientation {
                self?.lastOrientation = UIDevice.current.orientation
                self?.adjustLayout(isDeviceRotating: true)
            } else {
                self?.adjustLayout()
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

    private func setupRedesignView() {
        view.addBlurEffectWithClearBackgroundAndClipping(using: .regular)
        view.addSubview(menuRedesignContent)

        NSLayoutConstraint.activate([
            menuRedesignContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuRedesignContent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            menuRedesignContent.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuRedesignContent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        menuRedesignContent.setupDetails(title: String(format: .MainMenu.HeaderBanner.Title, AppName.shortName.rawValue),
                                         subtitle: .MainMenu.HeaderBanner.Subtitle,
                                         image: UIImage(named: ImageIdentifiers.foxDefaultBrowser),
                                         isBannerFlagEnabled: isMenuDefaultBrowserBanner,
                                         isBrowserDefault: isBrowserDefault,
                                         bannerShown: bannerShown)
    }

    private func setupMenuOrientation() {
        menuRedesignContent.setupMenuMenuOrientation(isPhoneLandscape: isPhoneLandscape)
    }

    private func setupHintView() {
        guard let viewProvider else { return }
        var viewModel = ContextualHintViewModel(
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
        if isPad {
            view.addSubview(hintView)
            NSLayoutConstraint.activate([
                hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.hintViewMargin * 4),
                hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.hintViewMargin * 4)
            ])
            if isMenuRedesign {
                hintView.topAnchor.constraint(equalTo: menuRedesignContent.topAnchor,
                                              constant: UX.hintViewMargin).isActive = true
            } else {
                hintView.topAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                              constant: UX.hintViewMargin).isActive = true
            }
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first {
            window.addSubview(hintView)

            if UIScreen.main.bounds.height < UX.hintViewHeight + menuRedesignContent.frame.height {
                if isMenuRedesign {
                    hintView.topAnchor.constraint(equalTo: menuRedesignContent.topAnchor,
                                                  constant: UX.hintViewMargin).isActive = true
                } else {
                    hintView.topAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                                  constant: UX.hintViewMargin).isActive = true
                }
            } else {
                if isMenuRedesign {
                    hintView.bottomAnchor.constraint(equalTo: menuRedesignContent.topAnchor,
                                                     constant: -UX.hintViewMargin).isActive = true
                } else {
                    hintView.bottomAnchor.constraint(equalTo: menuContent.accountHeaderView.topAnchor,
                                                     constant: -UX.hintViewMargin).isActive = true
                }
            }
            NSLayoutConstraint.activate([
                hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.hintViewMargin),
                hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.hintViewMargin)
            ])
        }
        hintViewHeightConstraint = hintView.heightAnchor.constraint(equalToConstant: UX.hintViewHeight)
        hintViewHeightConstraint?.isActive = true
        hintView.layer.cornerRadius = UX.hintViewCornerRadius
        hintView.layer.masksToBounds = true
        adjustLayout()
    }

    // MARK: - Redux
    func subscribeToRedux() {
        store.dispatchLegacy(
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
        store.dispatchLegacy(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.closeScreen,
                screen: .mainMenu
            )
        )
    }

    func newState(state: MainMenuState) {
        menuState = state

        isBrowserDefault = menuState.isBrowserDefault
        isPhoneLandscape = menuState.isPhoneLandscape

        if let accountData = menuState.accountData {
            updateHeaderWith(accountData: accountData, icon: menuState.accountIcon)
            setupAccessibilityIdentifiers(mainButtonA11yLabel: accountData.title)
        }

        if let siteProtectionsData = menuState.siteProtectionsData {
            updateSiteProtectionsHeaderWith(siteProtectionsData: siteProtectionsData)
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

        changeDetentIfNecessary()
        removeHintViewIfNecessary()
        reloadTableView(with: menuState.menuElements)

        if menuState.moreCellTapped {
            let expandedHint = String.MainMenu.ToolsSection.AccessibilityLabels.ExpandedHint
            menuRedesignContent.announceAccessibility(expandedHint: expandedHint)
        }
    }

    private func dispatchCloseMenuAction() {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.tapCloseMenu,
                currentTabInfo: menuState.currentTabInfo
            )
        )
    }

    private func dispatchSyncSignInAction() {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.tapNavigateToDestination,
                navigationDestination: MenuNavigationDestination(.syncSignIn),
                currentTabInfo: menuState.currentTabInfo
            )
        )
    }

    private func dispatchSiteProtectionAction() {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.tapNavigateToDestination,
                navigationDestination: MenuNavigationDestination(.siteProtections),
                currentTabInfo: menuState.currentTabInfo
            )
        )
    }

    private func dispatchDefaultBrowserAction() {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.tapNavigateToDestination,
                navigationDestination: MenuNavigationDestination(.defaultBrowser),
                currentTabInfo: menuState.currentTabInfo
            )
        )
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        if isMenuRedesign {
            view.backgroundColor = theme.colors.layer3.withAlphaComponent(UX.backgroundAlpha)
            menuRedesignContent.applyTheme(theme: theme)
        } else {
            view.backgroundColor = theme.colors.layer3
            menuContent.applyTheme(theme: theme)
        }
    }

    private func updateHeaderWith(accountData: AccountData, icon: UIImage?) {
        if !isMenuRedesign {
            menuContent.accountHeaderView.setupDetails(subtitle: accountData.subtitle ?? "",
                                                       title: accountData.title,
                                                       icon: icon,
                                                       warningIcon: accountData.warningIcon,
                                                       theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    private func updateSiteProtectionsHeaderWith(siteProtectionsData: SiteProtectionsData) {
        var state = String.MainMenu.SiteProtection.ProtectionsOn
        var stateImage = StandardImageIdentifiers.Small.shieldCheckmarkFill
        var shouldUseRenderMode = false

        switch siteProtectionsData.state {
        case .notSecure:
            state = String.MainMenu.SiteProtection.ConnectionNotSecure
            stateImage = StandardImageIdentifiers.Small.shieldSlashFillMulticolor
        case .on:
            shouldUseRenderMode = true
        case .off:
            state = String.MainMenu.SiteProtection.ProtectionsOff
            stateImage = StandardImageIdentifiers.Small.shieldSlashFillMulticolor
        }

        menuRedesignContent.siteProtectionHeader.setupDetails(
            title: siteProtectionsData.title,
            subtitle: siteProtectionsData.subtitle,
            image: siteProtectionsData.image,
            state: state,
            stateImage: stateImage,
            shouldUseRenderMode: shouldUseRenderMode)
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
            if isMenuRedesign {
                menuRedesignContent.setupAccessibilityIdentifiers(
                    menuA11yId: AccessibilityIdentifiers.MainMenu.mainMenu,
                    menuA11yLabel: .MainMenu.TabsSection.AccessibilityLabels.MainMenu,
                    closeButtonA11yLabel: .MainMenu.AccessibilityLabels.CloseButton,
                    closeButtonA11yIdentifier: AccessibilityIdentifiers.MainMenu.HeaderView.closeButton,
                    siteProtectionHeaderIdentifier: AccessibilityIdentifiers.MainMenu.SiteProtectionsHeaderView.header,
                    headerBannerCloseButtonA11yIdentifier: AccessibilityIdentifiers.MainMenu.HeaderBanner.closeButton,
                    headerBannerCloseButtonA11yLabel: .MainMenu.AccessibilityLabels.DismissBanner)
            } else {
                menuContent.setupAccessibilityIdentifiers(
                    closeButtonA11yLabel: .MainMenu.Account.AccessibilityLabels.CloseButton,
                    closeButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.closeButton,
                    mainButtonA11yLabel: mainButtonA11yLabel,
                    mainButtonA11yId: AccessibilityIdentifiers.MainMenu.HeaderView.mainButton,
                    menuA11yId: AccessibilityIdentifiers.MainMenu.mainMenu,
                    menuA11yLabel: .MainMenu.TabsSection.AccessibilityLabels.MainMenu)
            }
    }

    private func adjustLayout(isDeviceRotating: Bool = false) {
        if !isMenuRedesign {
            menuContent.accountHeaderView.adjustLayout()
        }
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

    private func shouldDisplayHintView(isMenuRedesign: Bool) -> Bool {
        guard let viewProvider else { return false }

        // Don't display CFR in landscape mode for iPhones
        if UIDevice.current.isIphoneLandscape {
            return false
        }

        // Don't display CFR for fresh installs for users that never saw before the photon main menu
        if InstallType.get() == .fresh {
            if isMenuRedesign {
                viewProvider.markContextualHintPresented()
                return false
            } else {
                if let photonMainMenuShown = profile.prefs.boolForKey(PrefsKeys.PhotonMainMenuShown),
                   photonMainMenuShown {
                    return viewProvider.shouldPresentContextualHint()
                }
                viewProvider.markContextualHintPresented()
                return false
            }
        }

        if isMenuRedesign, isHomepage {
            return false
        }
        return viewProvider.shouldPresentContextualHint()
    }

    private func changeDetentIfNecessary() {
        // For iOS 16 or above we are using custom detents
        if #unavailable(iOS 16) {
            if isExpanded {
                if let sheet = self.sheetPresentationController, !hasBeenExpanded {
                    sheet.selectedDetentIdentifier = .large
                    hasBeenExpanded = true
                }
            }
        }
    }

    private func removeHintViewIfNecessary() {
        if isExpanded { hintView.removeFromSuperview() }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.dispatchLegacy(
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
        if isMenuRedesign {
            menuRedesignContent.reloadDataView(with: data)
        } else {
            menuContent.reloadTableView(with: data)
        }
    }
}
