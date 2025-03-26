// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import SwiftUI

protocol SettingsCoordinatorDelegate: AnyObject {
    func openURLinNewTab(_ url: URL)
    func openDebugTestTabs(count: Int)
    func didFinishSettings(from coordinator: SettingsCoordinator)
}

class SettingsCoordinator: BaseCoordinator,
                           SettingsDelegate,
                           SettingsFlowDelegate,
                           GeneralSettingsDelegate,
                           PrivacySettingsDelegate,
                           PasswordManagerCoordinatorDelegate,
                           AccountSettingsDelegate,
                           AboutSettingsDelegate,
                           ParentCoordinatorDelegate,
                           QRCodeNavigationHandler,
                           BrowsingSettingsDelegate {
    var settingsViewController: AppSettingsScreen?
    private let wallpaperManager: WallpaperManagerInterface
    private let profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService
    weak var parentCoordinator: SettingsCoordinatorDelegate?
    private var windowUUID: WindowUUID { return tabManager.windowUUID }
    private let settingsTelemetry: SettingsTelemetry

    init(
        router: Router,
        wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
        profile: Profile = AppContainer.shared.resolve(),
        tabManager: TabManager,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        gleanUsageReportingMetricsService: GleanUsageReportingMetricsService = AppContainer.shared.resolve(),
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.wallpaperManager = wallpaperManager
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.gleanUsageReportingMetricsService = gleanUsageReportingMetricsService
        self.settingsTelemetry = SettingsTelemetry(gleanWrapper: gleanWrapper)
        super.init(router: router)

        // It's important we initialize AppSettingsTableViewController with a settingsDelegate and parentCoordinator
        let settingsViewController = AppSettingsTableViewController(
            with: profile,
            and: tabManager,
            settingsDelegate: self,
            parentCoordinator: self,
            gleanUsageReportingMetricsService: gleanUsageReportingMetricsService
        )
        self.settingsViewController = settingsViewController
        router.setRootViewController(settingsViewController)
    }

    func start(with settingsSection: Route.SettingsSection) {
        // We might already know the sub-settings page we want to show, but in some case we don't and
        // the flow decision needs to be figured out by the view controller
        if let viewController = getSettingsViewController(settingsSection: settingsSection) {
            router.push(viewController)
        } else {
            assert(settingsViewController != nil)
            settingsViewController?.handle(route: settingsSection)
        }
    }

    override func canHandle(route: Route) -> Bool {
        switch route {
        case .settings:
            return true
        default:
            return false
        }
    }

    override func handle(route: Route) {
        switch route {
        case let .settings(section):
            start(with: section)
        default:
            break
        }
    }

    private func getSettingsViewController(settingsSection section: Route.SettingsSection) -> UIViewController? {
        switch section {
        case .appIcon:
            let viewController = UIHostingController(
                rootView: AppIconSelectionView(
                    windowUUID: windowUUID
                )
            )
            viewController.title = .Settings.AppIconSelection.ScreenTitle
            return viewController
        case .addresses:
            let viewModel = AddressAutofillSettingsViewModel(
                profile: profile,
                windowUUID: windowUUID
            )
            let viewController = AddressAutofillSettingsViewController(
                addressAutofillViewModel: viewModel,
                windowUUID: windowUUID
            )
            return viewController
        case .newTab:
            let viewController = NewTabContentSettingsViewController(prefs: profile.prefs,
                                                                     windowUUID: windowUUID)
            viewController.profile = profile
            return viewController

        case .homePage:
            let viewController = HomePageSettingViewController(prefs: profile.prefs,
                                                               settingsDelegate: self,
                                                               tabManager: tabManager)
            viewController.profile = profile
            return viewController

        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs, windowUUID: windowUUID)
            return viewController

        case .search:
            let viewController = SearchSettingsTableViewController(profile: profile, windowUUID: windowUUID)
            return viewController

        case .clearPrivateData:
            let viewController = ClearPrivateDataTableViewController(profile: profile, tabManager: tabManager)
            return viewController

        case .fxa:
            let fxaParams = FxALaunchParams(entrypoint: .fxaDeepLinkSetting, query: [:])
            let viewController = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
                fxaParams,
                flowType: .emailLoginFlow,
                referringPage: .settings,
                profile: profile,
                windowUUID: windowUUID
            )
            (viewController as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = self
            return viewController

        case .theme:
           return themeManager.isNewAppearanceMenuOn
               ? UIHostingController(rootView: AppearanceSettingsView(windowUUID: windowUUID))
               : ThemeSettingsController(windowUUID: windowUUID)

        case .wallpaper:
            if wallpaperManager.canSettingsBeShown {
                let viewModel = WallpaperSettingsViewModel(
                    wallpaperManager: wallpaperManager,
                    tabManager: tabManager,
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    windowUUID: windowUUID
                )
                let wallpaperVC = WallpaperSettingsViewController(viewModel: viewModel, windowUUID: windowUUID)
                wallpaperVC.settingsDelegate = self
                return wallpaperVC
            } else {
                return nil
            }

        case .contentBlocker:
            let contentBlockerVC = ContentBlockerSettingViewController(windowUUID: windowUUID,
                                                                       prefs: profile.prefs,
                                                                       isShownFromSettings: false)
            contentBlockerVC.settingsDelegate = self
            contentBlockerVC.profile = profile
            contentBlockerVC.tabManager = tabManager
            return contentBlockerVC

        case .browser:
            return BrowsingSettingsViewController(profile: profile, windowUUID: windowUUID)

        case .toolbar:
            let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
            return SearchBarSettingsViewController(viewModel: viewModel, windowUUID: windowUUID)

        case .topSites:
            let viewController = TopSitesSettingsViewController(windowUUID: windowUUID)
            viewController.profile = profile
            return viewController

        case .creditCard, .password:
            return nil // Needs authentication, decision handled by VC

        case .general, .rateApp:
            return nil // Return nil since we're already at the general page
        }
    }

    // MARK: - SettingsDelegate
    func settingsOpenURLInNewTab(_ url: URL) {
        parentCoordinator?.openURLinNewTab(url)
    }

    func didFinish() {
        parentCoordinator?.didFinishSettings(from: self)
    }

    // MARK: - SettingsFlowDelegate
    func showDevicePassCode() {
        let passcodeViewController = DevicePasscodeRequiredViewController(windowUUID: windowUUID)
        passcodeViewController.profile = profile
        router.push(passcodeViewController)
    }

    func showCreditCardSettings() {
        let viewModel = CreditCardSettingsViewModel(profile: profile, windowUUID: windowUUID)
        let creditCardViewController = CreditCardSettingsViewController(creditCardViewModel: viewModel)
        router.push(creditCardViewController)
    }

    func showExperiments() {
        let experimentsViewController = ExperimentsViewController()
        router.push(experimentsViewController)
    }

    func showFirefoxSuggest() {
        let firefoxSuggestViewController = FirefoxSuggestSettingsViewController(profile: profile, windowUUID: windowUUID)
        router.push(firefoxSuggestViewController)
    }

    func openDebugTestTabs(count: Int) {
        parentCoordinator?.openDebugTestTabs(count: count)
    }

    func showDebugFeatureFlags() {
        let featureFlagsViewController = FeatureFlagsDebugViewController(profile: profile, windowUUID: windowUUID)
        router.push(featureFlagsViewController)
    }

    func showPasswordManager(shouldShowOnboarding: Bool) {
        let passwordCoordinator = PasswordManagerCoordinator(
            router: router,
            profile: profile,
            windowUUID: windowUUID
        )
        add(child: passwordCoordinator)
        passwordCoordinator.parentCoordinator = self
        passwordCoordinator.start(with: shouldShowOnboarding)
    }

    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            if rootNavigationController != nil {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: DefaultRouter(navigationController: rootNavigationController!)
                )
            } else {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: router
                )
            }
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }

    func didFinishShowingSettings() {
        didFinish()
    }

    // MARK: PrivacySettingsDelegate

    func pressedAutoFillsPasswords() {
        let viewController = AutoFillPasswordSettingsViewController(profile: profile, windowUUID: windowUUID)
        viewController.parentCoordinator = self
        router.push(viewController)
    }

    func pressedAddressAutofill() {
        let viewModel = AddressAutofillSettingsViewModel(
            profile: profile,
            windowUUID: windowUUID
        )
        let viewController = AddressAutofillSettingsViewController(
            addressAutofillViewModel: viewModel,
            windowUUID: windowUUID
        )
        router.push(viewController)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillSettings
        )
    }

    func pressedCreditCard() {
        findAndHandle(route: .settings(section: .creditCard))
    }

    func pressedClearPrivateData() {
        let viewController = ClearPrivateDataTableViewController(profile: profile, tabManager: tabManager)
        router.push(viewController)
    }

    func pressedContentBlocker() {
        let viewController = ContentBlockerSettingViewController(windowUUID: windowUUID, prefs: profile.prefs)
        viewController.settingsDelegate = self
        viewController.profile = profile
        viewController.tabManager = tabManager
        router.push(viewController)
    }

    func pressedPasswords() {
        findAndHandle(route: .settings(section: .password))
    }

    func pressedNotifications() {
        let viewController = NotificationsSettingsViewController(prefs: profile.prefs,
                                                                 hasAccount: profile.hasAccount(),
                                                                 windowUUID: windowUUID)
        router.push(viewController)
    }

    func askedToOpen(url: URL?, withTitle title: NSAttributedString?) {
        guard let url = url else { return }
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }

    // MARK: GeneralSettingsDelegate

    func pressedCustomizeAppIcon() {
        settingsTelemetry.tappedAppIconSetting()

        let viewController = UIHostingController(
            rootView: AppIconSelectionView(
                windowUUID: windowUUID
            )
        )
        viewController.title = .Settings.AppIconSelection.ScreenTitle
        router.push(viewController)
    }

    func pressedHome() {
        let viewController = HomePageSettingViewController(prefs: profile.prefs,
                                                           settingsDelegate: self,
                                                           tabManager: tabManager)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedNewTab() {
        let viewController = NewTabContentSettingsViewController(prefs: profile.prefs, windowUUID: windowUUID)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedSearchEngine() {
        let viewController = SearchSettingsTableViewController(profile: profile, windowUUID: windowUUID)
        router.push(viewController)
    }

    func pressedSiri() {
        let viewController = SiriSettingsViewController(prefs: profile.prefs, windowUUID: windowUUID)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToolbar() {
        let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
        let viewController = SearchBarSettingsViewController(viewModel: viewModel, windowUUID: windowUUID)
        router.push(viewController)
    }

    func pressedTheme() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .themeSettings)
        store.dispatch(action)

        if themeManager.isNewAppearanceMenuOn {
            let viewController = UIHostingController(rootView: AppearanceSettingsView(windowUUID: windowUUID))
            viewController.title = .SettingsAppearanceTitle
            router.push(viewController)
        } else {
            router.push(ThemeSettingsController(windowUUID: windowUUID))
        }
    }

    func pressedBrowsing() {
        let viewController = BrowsingSettingsViewController(profile: profile,
                                                            windowUUID: windowUUID)
        viewController.parentCoordinator = self
        router.push(viewController)
    }

    // MARK: AccountSettingsDelegate

    func pressedConnectSetting() {
        let fxaParams = FxALaunchParams(entrypoint: .connectSetting, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .settings,
                                                                deepLinkParams: fxaParams,
                                                                windowUUID: windowUUID)
        viewController.qrCodeNavigationHandler = self
        router.push(viewController)
    }

    func pressedAdvancedAccountSetting() {
        let viewController = AdvancedAccountSettingViewController(windowUUID: windowUUID)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToShowSyncContent() {
        let viewController = SyncContentSettingsViewController(windowUUID: windowUUID)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToShowFirefoxAccount() {
        let fxaParams = FxALaunchParams(entrypoint: .accountStatusSettingReauth, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .settings,
                                                                deepLinkParams: fxaParams,
                                                                windowUUID: windowUUID)
        viewController.qrCodeNavigationHandler = self
        router.push(viewController)
    }

    // MARK: - BrowsingSettingsDelegate

    func pressedMailApp() {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs, windowUUID: windowUUID)
        router.push(viewController)
    }

    func pressedAutoPlay() {
        let viewController = AutoplaySettingsViewController(prefs: profile.prefs, windowUUID: windowUUID)
        router.push(viewController)
    }

    // MARK: - SupportSettingsDelegate

    func pressedOpenSupportPage(url: URL) {
        didFinish()
        settingsOpenURLInNewTab(url)
    }

    // MARK: - PasswordManagerCoordinatorDelegate

    func didFinishPasswordManager(from coordinator: PasswordManagerCoordinator) {
        didFinish()
        remove(child: coordinator)
    }

    // MARK: - AboutSettingsDelegate

    func pressedRateApp() {
        assert(settingsViewController != nil)
        settingsViewController?.handle(route: .rateApp)
    }

    func pressedLicense(url: URL, title: NSAttributedString) {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }

    func pressedYourRights(url: URL, title: NSAttributedString) {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }
}
