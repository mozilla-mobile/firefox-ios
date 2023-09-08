// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Redux

protocol SettingsCoordinatorDelegate: AnyObject {
    func openURLinNewTab(_ url: URL)
    func didFinishSettings(from coordinator: SettingsCoordinator)
}

class SettingsCoordinator: BaseCoordinator,
                           SettingsDelegate,
                           SettingsFlowDelegate,
                           GeneralSettingsDelegate,
                           PrivacySettingsDelegate,
                           PasswordManagerCoordinatorDelegate,
                           AccountSettingsDelegate,
                           AboutSettingsDelegate {
    var settingsViewController: AppSettingsScreen
    private let wallpaperManager: WallpaperManagerInterface
    private let profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    weak var parentCoordinator: SettingsCoordinatorDelegate?

    init(router: Router,
         wallpaperManager: WallpaperManagerInterface = WallpaperManager(),
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.wallpaperManager = wallpaperManager
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.settingsViewController = AppSettingsTableViewController(with: profile,
                                                                     and: tabManager)
        super.init(router: router)

        router.setRootViewController(settingsViewController)
        settingsViewController.settingsDelegate = self
        settingsViewController.parentCoordinator = self
    }

    func start(with settingsSection: Route.SettingsSection) {
        // We might already know the sub-settings page we want to show, but in some case we don't and
        // the flow decision needs to be figured out by the view controller
        if let viewController = getSettingsViewController(settingsSection: settingsSection) {
            router.push(viewController)
        } else {
            settingsViewController.handle(route: settingsSection)
        }
    }

    override func handle(route: Route) -> Bool {
        switch route {
        case let .settings(section):
            start(with: section)
            return true
        default:
            return false
        }
    }

    private func getSettingsViewController(settingsSection section: Route.SettingsSection) -> UIViewController? {
        switch section {
        case .newTab:
            let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
            return viewController

        case .homePage:
            let viewController = HomePageSettingViewController(prefs: profile.prefs, settingsDelegate: self)
            viewController.profile = profile
            return viewController

        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            return viewController

        case .search:
            let viewController = SearchSettingsTableViewController(profile: profile)
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
                profile: profile
            )
            return viewController

        case .theme:
            return ThemeSettingsController()

        case .wallpaper:
            if wallpaperManager.canSettingsBeShown {
                let viewModel = WallpaperSettingsViewModel(
                    wallpaperManager: wallpaperManager,
                    tabManager: tabManager,
                    theme: themeManager.currentTheme
                )
                let wallpaperVC = WallpaperSettingsViewController(viewModel: viewModel)
                wallpaperVC.settingsDelegate = self
                return wallpaperVC
            } else {
                return nil
            }

        case .contentBlocker:
            let contentBlockerVC = ContentBlockerSettingViewController(prefs: profile.prefs,
                                                                       isShownFromSettings: false)
            contentBlockerVC.settingsDelegate = self
            contentBlockerVC.profile = profile
            contentBlockerVC.tabManager = tabManager
            return contentBlockerVC

        case .tabs:
            return TabsSettingsViewController()

        case .toolbar:
            let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
            return SearchBarSettingsViewController(viewModel: viewModel)

        case .topSites:
            let viewController = TopSitesSettingsViewController()
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
        let passcodeViewController = DevicePasscodeRequiredViewController()
        passcodeViewController.profile = profile
        router.push(passcodeViewController)
    }

    func showCreditCardSettings() {
        let viewModel = CreditCardSettingsViewModel(profile: profile)
        let creditCardViewController = CreditCardSettingsViewController(creditCardViewModel: viewModel)
        router.push(creditCardViewController)
    }

    func showExperiments() {
        let experimentsViewController = ExperimentsViewController()
        router.push(experimentsViewController)
    }

    func showPasswordManager(shouldShowOnboarding: Bool) {
        let passwordCoordinator = PasswordManagerCoordinator(
            router: router,
            profile: profile
        )
        add(child: passwordCoordinator)
        passwordCoordinator.parentCoordinator = self
        passwordCoordinator.start(with: shouldShowOnboarding)
    }

    func didFinishShowingSettings() {
        didFinish()
    }

    // MARK: PrivacySettingsDelegate

    func pressedCreditCard() {
        findAndHandle(route: .settings(section: .creditCard))
    }

    func pressedClearPrivateData() {
        let viewController = ClearPrivateDataTableViewController(profile: profile, tabManager: tabManager)
        router.push(viewController)
    }

    func pressedContentBlocker() {
        let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
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
                                                                 hasAccount: profile.hasAccount())
        router.push(viewController)
    }

    func askedToOpen(url: URL?, withTitle title: NSAttributedString?) {
        guard let url = url else { return }
        let viewController = SettingsContentViewController()
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }

    // MARK: GeneralSettingsDelegate

    func pressedHome() {
        let viewController = HomePageSettingViewController(prefs: profile.prefs,
                                                           settingsDelegate: self)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedMailApp() {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
        router.push(viewController)
    }

    func pressedNewTab() {
        let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedSearchEngine() {
        let viewController = SearchSettingsTableViewController(profile: profile)
        router.push(viewController)
    }

    func pressedSiri() {
        let viewController = SiriSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToolbar() {
        let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
        let viewController = SearchBarSettingsViewController(viewModel: viewModel)
        router.push(viewController)
    }

    func pressedTabs() {
        let viewController = TabsSettingsViewController()
        router.push(viewController)
    }

    func pressedTheme() {
        if ReduxFlagManager.isReduxEnabled {
            store.dispatch(ActiveScreensStateAction.showScreen(.themeSettings))
        }
        router.push(ThemeSettingsController())
    }

    // MARK: AccountSettingsDelegate

    func pressedConnectSetting() {
        let fxaParams = FxALaunchParams(entrypoint: .connectSetting, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .settings,
                                                                deepLinkParams: fxaParams)
        router.push(viewController)
    }

    func pressedAdvancedAccountSetting() {
        let viewController = AdvancedAccountSettingViewController()
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToShowSyncContent() {
        let viewController = SyncContentSettingsViewController()
        viewController.profile = profile
        router.push(viewController)
    }

    func pressedToShowFirefoxAccount() {
        let fxaParams = FxALaunchParams(entrypoint: .accountStatusSettingReauth, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile,
                                                                parentType: .settings,
                                                                deepLinkParams: fxaParams)
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
        settingsViewController.handle(route: .rateApp)
    }

    func pressedLicense(url: URL, title: NSAttributedString) {
        let viewController = SettingsContentViewController()
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }

    func pressedYourRights(url: URL, title: NSAttributedString) {
        let viewController = SettingsContentViewController()
        viewController.settingsTitle = title
        viewController.url = url
        router.push(viewController)
    }
}
