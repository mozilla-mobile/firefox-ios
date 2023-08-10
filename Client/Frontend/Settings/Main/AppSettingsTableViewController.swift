// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// Will be clean up with FXIOS-6529
enum AppSettingsDeeplinkOption {
    case contentBlocker
    case customizeHomepage
    case customizeTabs
    case customizeToolbar
    case customizeTopSites
    case wallpaper
    case creditCard
    case fxa
    case mailto
    case newTab
    case search

    func getSettingsRoute() -> Route.SettingsSection {
        switch self {
        case .contentBlocker:
            return .contentBlocker
        case .customizeHomepage:
            return .homePage
        case .customizeTabs:
            return .tabs
        case .customizeToolbar:
            return .toolbar
        case .customizeTopSites:
            return .topSites
        case .wallpaper:
            return .wallpaper
        case .creditCard:
            return .creditCard
        case .fxa:
            return .fxa
        case .mailto:
            return .mailto
        case .newTab:
            return .newTab
        case .search:
            return .search
        }
    }
}

/// Supports decision making from VC to parent coordinator
protocol SettingsFlowDelegate: AnyObject,
                               GeneralSettingsDelegate,
                               PrivacySettingsDelegate,
                               AccountSettingsDelegate,
                               AboutSettingsDelegate,
                               SupportSettingsDelegate {
    func showDevicePassCode()
    func showCreditCardSettings()
    func showExperiments()
    func showPasswordManager(shouldShowOnboarding: Bool)

    func didFinishShowingSettings()
}

protocol AppSettingsScreen: UIViewController {
    var settingsDelegate: SettingsDelegate? { get set }
    var parentCoordinator: SettingsFlowDelegate? { get set }

    func handle(route: Route.SettingsSection)
}

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController,
                                      AppSettingsScreen,
                                      FeatureFlaggable,
                                      DebugSettingsDelegate,
                                      SearchBarLocationProvider,
                                      SharedSettingsDelegate {
    // MARK: - Properties
    var deeplinkTo: AppSettingsDeeplinkOption? // Will be clean up with FXIOS-6529
    private var showDebugSettings = false
    private var debugSettingsClickCount: Int = 0
    private var appAuthenticator: AppAuthenticationProtocol
    private var applicationHelper: ApplicationHelper
    weak var parentCoordinator: SettingsFlowDelegate?

    // MARK: - Initializers
    init(with profile: Profile,
         and tabManager: TabManager,
         delegate: SettingsDelegate? = nil,
         deeplinkingTo destination: AppSettingsDeeplinkOption? = nil,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.deeplinkTo = destination
        self.appAuthenticator = appAuthenticator
        self.applicationHelper = applicationHelper

        super.init()
        self.profile = profile
        self.tabManager = tabManager
        self.settingsDelegate = delegate
        setupNavigationBar()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Settings.navigationBarItem
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.tableViewController

        checkForDeeplinkSetting()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        askedToReload()
    }

    @objc
    private func done() {
        settingsDelegate?.didFinish()
    }

    private func setupNavigationBar() {
        navigationItem.title = String.AppSettingsTitle
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: .AppSettingsDone,
                style: .done,
                target: self,
                action: #selector(done))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: .AppSettingsDone,
                style: .done,
                target: navigationController,
                action: #selector((navigationController as! ThemedNavigationController).done))
        }
    }

    // MARK: Handle Route decisions

    func handle(route: Route.SettingsSection) {
        switch route {
        case .password:
            handlePasswordFlow(route: route)
        case .creditCard:
            authenticateUserFor(route: route)
        case .rateApp:
            RatingPromptManager.goToAppStoreReview()
        default:
            break
        }
    }

    private func handlePasswordFlow(route: Route.SettingsSection) {
        // Show password onboarding before we authenticate
        if LoginOnboarding.shouldShow() {
            parentCoordinator?.showPasswordManager(shouldShowOnboarding: true)
            LoginOnboarding.setShown()
        } else {
            authenticateUserFor(route: route)
        }
    }

    // Authenticates the user prior to allowing access to sensitive sections
    private func authenticateUserFor(route: Route.SettingsSection) {
        appAuthenticator.getAuthenticationState { state in
            switch state {
            case .deviceOwnerAuthenticated:
                self.openDeferredRouteAfterAuthentication(route: route)
            case .deviceOwnerFailed:
                break // Keep showing the main settings page
            case .passCodeRequired:
                self.parentCoordinator?.showDevicePassCode()
            }
        }
    }

    // Called after the user has been prompted to authenticate to access a sensitive section
    private func openDeferredRouteAfterAuthentication(route: Route.SettingsSection) {
        switch route {
        case .creditCard:
            self.parentCoordinator?.showCreditCardSettings()
        case .password:
            self.parentCoordinator?.showPasswordManager(shouldShowOnboarding: false)
        default:
            break
        }
    }

    // Will be removed with FXIOS-6529
    func checkForDeeplinkSetting() {
        guard let deeplink = deeplinkTo else { return }
        var viewController: SettingsTableViewController

        switch deeplink {
        case .contentBlocker:
            viewController = ContentBlockerSettingViewController(prefs: profile.prefs, isShownFromSettings: false)
            viewController.tabManager = tabManager

        case .customizeHomepage:
            viewController = HomePageSettingViewController(prefs: profile.prefs, settingsDelegate: settingsDelegate)

        case .customizeTabs:
            viewController = TabsSettingsViewController()

        case .customizeToolbar:
            let viewModel = SearchBarSettingsViewModel(prefs: profile.prefs)
            viewController = SearchBarSettingsViewController(viewModel: viewModel)

        case .wallpaper:
            let wallpaperManager = WallpaperManager()
            if wallpaperManager.canSettingsBeShown {
                let viewModel = WallpaperSettingsViewModel(wallpaperManager: wallpaperManager,
                                                           tabManager: tabManager,
                                                           theme: themeManager.currentTheme)
                let wallpaperVC = WallpaperSettingsViewController(viewModel: viewModel)
                navigationController?.pushViewController(wallpaperVC, animated: true)
            }
            return

        case .creditCard:
            let viewModel = CreditCardSettingsViewModel(profile: profile)
            let viewController = CreditCardSettingsViewController(
                creditCardViewModel: viewModel)
            guard let navController = navigationController else { return }
            if appAuthenticator.canAuthenticateDeviceOwner {
                appAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
                    switch result {
                    case .success:
                        navController.pushViewController(viewController,
                                                         animated: true)
                    case .failure:
                        break
                    }
                }
            } else {
                let passcodeViewController = DevicePasscodeRequiredViewController()
                passcodeViewController.profile = profile
                navController.pushViewController(passcodeViewController,
                                                 animated: true)
            }
            return
        case .customizeTopSites:
            viewController = TopSitesSettingsViewController()
            viewController.profile = profile
        case .fxa:
            let fxaParams = FxALaunchParams(entrypoint: .fxaDeepLinkSetting, query: [:])
            let viewController = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
                fxaParams,
                flowType: .emailLoginFlow,
                referringPage: .settings,
                profile: profile
            )
            navigationController?.pushViewController(viewController, animated: true)
            return
        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            navigationController?.pushViewController(viewController, animated: true)
            return
        case .newTab:
            viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
        case .search:
            let viewController = SearchSettingsTableViewController(profile: profile)
            navigationController?.pushViewController(viewController, animated: true)
            return
        }

        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: false)
        // Add a done button from this view
        viewController.navigationItem.rightBarButtonItem = navigationItem.rightBarButtonItem
    }

    // MARK: - Generate Settings

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()
        settings += getDefaultBrowserSetting()
        settings += getAccountSetting()
        settings += getGeneralSettings()
        settings += getPrivacySettings()
        settings += getSupportSettings()
        settings += getAboutSettings()

        if showDebugSettings {
            settings += getDebugSettings()
        }

        return settings
    }

    private func getDefaultBrowserSetting() -> [SettingSection] {
        let footerTitle = NSAttributedString(
            string: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerDescription)

        return [SettingSection(footerTitle: footerTitle,
                               children: [DefaultBrowserSetting(theme: themeManager.currentTheme)])]
    }

    private func getAccountSetting() -> [SettingSection] {
        let accountChinaSyncSetting: [Setting]
        if !AppInfo.isChinaEdition {
            accountChinaSyncSetting = []
        } else {
            accountChinaSyncSetting = [
                // Show China sync service setting:
                ChinaSyncServiceSetting(settings: self, settingsDelegate: self)
            ]
        }

        let accountSectionTitle = NSAttributedString(string: .FxAFirefoxAccount)

        let accountFooterText = !profile.hasAccount() ? NSAttributedString(string: .Settings.Sync.ButtonDescription) : nil
        return [SettingSection(title: accountSectionTitle, footerTitle: accountFooterText, children: [
            // Without a Firefox Account:
            ConnectSetting(settings: self, settingsDelegate: parentCoordinator),
            AdvancedAccountSetting(settings: self, isHidden: showDebugSettings, settingsDelegate: parentCoordinator),
            // With a Firefox Account:
            AccountStatusSetting(settings: self, settingsDelegate: parentCoordinator),
            SyncNowSetting(settings: self, settingsDelegate: parentCoordinator)
        ] + accountChinaSyncSetting)]
    }

    private func getGeneralSettings() -> [SettingSection] {
        var generalSettings: [Setting] = [
            SearchSetting(settings: self, settingsDelegate: parentCoordinator),
            NewTabPageSetting(settings: self, settingsDelegate: parentCoordinator),
            HomeSetting(settings: self, settingsDelegate: parentCoordinator),
            OpenWithSetting(settings: self, settingsDelegate: parentCoordinator),
            ThemeSetting(settings: self, settingsDelegate: parentCoordinator),
            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator),
            BlockPopupSetting(settings: self),
            NoImageModeSetting(settings: self),
        ]

        if isSearchBarLocationFeatureEnabled {
            generalSettings.insert(SearchBarSetting(settings: self, settingsDelegate: parentCoordinator), at: 5)
        }

        let tabTrayGroupsAreBuildActive = featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly)
        let inactiveTabsAreBuildActive = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)
        if tabTrayGroupsAreBuildActive || inactiveTabsAreBuildActive {
            generalSettings.insert(TabsSetting(theme: themeManager.currentTheme, settingsDelegate: parentCoordinator), at: 3)
        }

        let offerToOpenCopiedLinksSettings = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.currentTheme,
            prefKey: "showClipboardBar",
            defaultValue: false,
            titleText: .SettingsOfferClipboardBarTitle,
            statusText: .SettingsOfferClipboardBarStatus
        )

        let showLinksPreviewSettings = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.currentTheme,
            prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
            defaultValue: true,
            titleText: .SettingsShowLinkPreviewsTitle,
            statusText: .SettingsShowLinkPreviewsStatus
        )

        generalSettings += [
            offerToOpenCopiedLinksSettings,
            showLinksPreviewSettings
        ]

        return [SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle),
                               children: generalSettings)]
    }

    private func getPrivacySettings() -> [SettingSection] {
        var privacySettings = [Setting]()
        privacySettings.append(PasswordManagerSetting(settings: self, settingsDelegate: parentCoordinator))

        let autofillCreditCardStatus = featureFlags.isFeatureEnabled(.creditCardAutofillStatus, checking: .buildOnly)
        if autofillCreditCardStatus {
            privacySettings.append(AutofillCreditCardSettings(settings: self, settingsDelegate: parentCoordinator))
        }

        privacySettings.append(ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator))

        privacySettings += [
            BoolSetting(prefs: profile.prefs,
                        theme: themeManager.currentTheme,
                        prefKey: "settings.closePrivateTabs",
                        defaultValue: false,
                        titleText: .AppSettingsClosePrivateTabsTitle,
                        statusText: .AppSettingsClosePrivateTabsDescription)
        ]

        privacySettings.append(ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator))

        privacySettings.append(NotificationsSetting(theme: themeManager.currentTheme,
                                                    profile: profile,
                                                    settingsDelegate: parentCoordinator))

        privacySettings += [
            PrivacyPolicySetting(theme: themeManager.currentTheme, settingsDelegate: parentCoordinator)
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle),
                               children: privacySettings)]
    }

    private func getSupportSettings() -> [SettingSection] {
        let supportSettings = [
            ShowIntroductionSetting(settings: self, settingsDelegate: self),
            SendFeedbackSetting(settingsDelegate: parentCoordinator),
            SendAnonymousUsageDataSetting(prefs: profile.prefs,
                                          delegate: settingsDelegate,
                                          theme: themeManager.currentTheme,
                                          settingsDelegate: parentCoordinator),
            StudiesToggleSetting(prefs: profile.prefs,
                                 delegate: settingsDelegate,
                                 theme: themeManager.currentTheme,
                                 settingsDelegate: parentCoordinator),
            OpenSupportPageSetting(delegate: settingsDelegate,
                                   theme: themeManager.currentTheme,
                                   settingsDelegate: parentCoordinator),
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsSupport),
                               children: supportSettings)]
    }

    private func getAboutSettings() -> [SettingSection] {
        let aboutSettings = [
            AppStoreReviewSetting(settingsDelegate: parentCoordinator),
            VersionSetting(settingsDelegate: self),
            LicenseAndAcknowledgementsSetting(settingsDelegate: parentCoordinator),
            YourRightsSetting(settingsDelegate: parentCoordinator)
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsAbout),
                               children: aboutSettings)]
    }

    private func getDebugSettings() -> [SettingSection] {
        let hiddenDebugOptions = [
            ExperimentsSettings(settings: self, settingsDelegate: self),
            ExportLogDataSetting(settings: self),
            ExportBrowserDataSetting(settings: self),
            DeleteExportedDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            ForgetSyncAuthStateDebugSetting(settings: self),
            ChangeToChinaSetting(settings: self),
            AppReviewPromptSetting(settings: self, settingsDelegate: self),
            TogglePullToRefresh(settings: self, settingsDelegate: self),
            ToggleHistoryGroups(settings: self, settingsDelegate: self),
            ToggleInactiveTabs(settings: self, settingsDelegate: self),
            ResetContextualHints(settings: self),
            ResetWallpaperOnboardingPage(settings: self, settingsDelegate: self),
            SentryIDSetting(settings: self, settingsDelegate: self),
            FasterInactiveTabs(settings: self, settingsDelegate: self),
            OpenFiftyTabsDebugOption(settings: self),
        ]

        return [SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugOptions)]
    }

    // MARK: - DebugSettingsDelegate

    func pressedVersion() {
        debugSettingsClickCount += 1
        if debugSettingsClickCount >= 5 {
            debugSettingsClickCount = 0
            showDebugSettings = !showDebugSettings
            settings = generateSettings()
            askedToReload()
        }
    }

    func pressedExperiments() {
        parentCoordinator?.showExperiments()
    }

    func pressedShowTour() {
        parentCoordinator?.didFinishShowingSettings()

        let urlString = URL.mozInternalScheme + "://deep-link?url=/action/show-intro-onboarding"
        guard let url = URL(string: urlString) else { return }
        applicationHelper.open(url)
    }

    // MARK: SharedSettingsDelegate

    func askedToShow(alert: AlertController) {
        present(alert, animated: true) {
            // Dismiss the debug alert briefly after it's shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func askedToReload() {
        tableView.reloadData()
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }
}
