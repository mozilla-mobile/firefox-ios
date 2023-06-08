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
        }
    }
}

protocol AppSettingsDelegate: AnyObject {
    func clickedVersion()
}

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController, FeatureFlaggable, AppSettingsDelegate {
    // MARK: - Properties
    var deeplinkTo: AppSettingsDeeplinkOption? // Will be clean up with FXIOS-6529
    private var showDebugSettings = false
    private var debugSettingsClickCount: Int = 0
    private var appAuthenticator: AppAuthenticationProtocol

    // MARK: - Initializers
    init(with profile: Profile,
         and tabManager: TabManager,
         delegate: SettingsDelegate? = nil,
         deeplinkingTo destination: AppSettingsDeeplinkOption? = nil,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.deeplinkTo = destination
        self.appAuthenticator = appAuthenticator

        super.init()
        self.profile = profile
        self.tabManager = tabManager
        self.settingsDelegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()

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

        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Settings.navigationBarItem
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.tableViewController

        checkForDeeplinkSetting()
    }

    @objc
    private func done() {
        settingsDelegate?.didFinish()
    }

    // Will be clean up with FXIOS-6529
    private func checkForDeeplinkSetting() {
        guard let deeplink = deeplinkTo else { return }
        var viewController: SettingsTableViewController

        switch deeplink {
        case .contentBlocker:
            viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
            viewController.tabManager = tabManager

        case .customizeHomepage:
            viewController = HomePageSettingViewController(prefs: profile.prefs)

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
            if appAuthenticator.canAuthenticateDeviceOwner() {
                AppAuthenticator().authenticateWithDeviceOwnerAuthentication { result in
                    switch result {
                    case .success:
                        navController.pushViewController(viewController,
                                                         animated: true)
                    case .failure:
                        viewController.dismissVC()
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
        }

        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: false)
        // Add a done button from this view
        viewController.navigationItem.rightBarButtonItem = navigationItem.rightBarButtonItem
    }

    override func generateSettings() -> [SettingSection] {
        let footerTitle = NSAttributedString(
            string: String.FirefoxHomepage.HomeTabBanner.EvergreenMessage.HomeTabBannerDescription)
        var settings = [
            SettingSection(footerTitle: footerTitle,
                           children: [DefaultBrowserSetting(theme: themeManager.currentTheme)])
        ]

        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            SearchSetting(settings: self),
            NewTabPageSetting(settings: self),
            HomeSetting(settings: self),
            OpenWithSetting(settings: self),
            ThemeSetting(settings: self),
            SiriPageSetting(settings: self),
            BoolSetting(
                prefs: prefs,
                theme: themeManager.currentTheme,
                prefKey: PrefsKeys.KeyBlockPopups,
                defaultValue: true,
                titleText: .AppSettingsBlockPopups),
            NoImageModeSetting(settings: self)
           ]

        if isSearchBarLocationFeatureEnabled {
            generalSettings.insert(SearchBarSetting(settings: self), at: 5)
        }

        let autofillCreditCardStatus = featureFlags.isFeatureEnabled(.creditCardAutofillStatus, checking: .buildOnly)
        let tabTrayGroupsAreBuildActive = featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly)
        let inactiveTabsAreBuildActive = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)
        if tabTrayGroupsAreBuildActive || inactiveTabsAreBuildActive {
            generalSettings.insert(TabsSetting(theme: themeManager.currentTheme), at: 3)
        }

        let accountChinaSyncSetting: [Setting]
        if !AppInfo.isChinaEdition {
            accountChinaSyncSetting = []
        } else {
            accountChinaSyncSetting = [
                // Show China sync service setting:
                ChinaSyncServiceSetting(settings: self)
            ]
        }

        generalSettings += [
            BoolSetting(
                prefs: prefs,
                theme: themeManager.currentTheme,
                prefKey: "showClipboardBar",
                defaultValue: false,
                titleText: .SettingsOfferClipboardBarTitle,
                statusText: .SettingsOfferClipboardBarStatus),
            BoolSetting(
                prefs: prefs,
                theme: themeManager.currentTheme,
                prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
                defaultValue: true,
                titleText: .SettingsShowLinkPreviewsTitle,
                statusText: .SettingsShowLinkPreviewsStatus)
        ]

        let accountSectionTitle = NSAttributedString(string: .FxAFirefoxAccount)

        let footerText = !profile.hasAccount() ? NSAttributedString(string: .Settings.Sync.ButtonDescription) : nil
        settings += [
            SettingSection(title: accountSectionTitle, footerTitle: footerText, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                AdvancedAccountSetting(settings: self, isHidden: showDebugSettings),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                SyncNowSetting(settings: self)
            ] + accountChinaSyncSetting )]

        settings += [ SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle), children: generalSettings)]

        var privacySettings = [Setting]()
        privacySettings.append(LoginsSetting(settings: self, delegate: settingsDelegate))

        if autofillCreditCardStatus {
            privacySettings.append(AutofillCreditCardSettings(settings: self))
        }

        privacySettings.append(ClearPrivateDataSetting(settings: self))

        privacySettings += [
            BoolSetting(prefs: prefs,
                        theme: themeManager.currentTheme,
                        prefKey: "settings.closePrivateTabs",
                        defaultValue: false,
                        titleText: .AppSettingsClosePrivateTabsTitle,
                        statusText: .AppSettingsClosePrivateTabsDescription)
        ]

        privacySettings.append(ContentBlockerSetting(settings: self))

        if featureFlags.isFeatureEnabled(.notificationSettings, checking: .buildOnly) {
            privacySettings.append(NotificationsSetting(theme: themeManager.currentTheme, profile: self.profile))
        }

        privacySettings += [
            PrivacyPolicySetting()
        ]

        let supportSettings = [
            ShowIntroductionSetting(settings: self),
            SendFeedbackSetting(),
            SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate, theme: themeManager.currentTheme),
            StudiesToggleSetting(prefs: prefs, delegate: settingsDelegate, theme: themeManager.currentTheme),
            OpenSupportPageSetting(delegate: settingsDelegate, theme: themeManager.currentTheme),
        ]

        let aboutSettings = [
            AppStoreReviewSetting(),
            VersionSetting(settings: self, appSettingsDelegate: self),
            LicenseAndAcknowledgementsSetting(),
            YourRightsSetting()
        ]

        settings += [
            SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: .AppSettingsSupport), children: supportSettings),
            SettingSection(title: NSAttributedString(string: .AppSettingsAbout), children: aboutSettings)
        ]

        if showDebugSettings {
            let hiddenDebugOptions = [
                ExperimentsSettings(settings: self),
                ExportLogDataSetting(settings: self),
                ExportBrowserDataSetting(settings: self),
                DeleteExportedDataSetting(settings: self),
                ForceCrashSetting(settings: self),
                ForgetSyncAuthStateDebugSetting(settings: self),
                ChangeToChinaSetting(settings: self),
                AppReviewPromptSetting(settings: self),
                TogglePullToRefresh(settings: self),
                ToggleHistoryGroups(settings: self),
                ToggleInactiveTabs(settings: self),
                ResetContextualHints(settings: self),
                ResetWallpaperOnboardingPage(settings: self),
                SentryIDSetting(settings: self),
                FasterInactiveTabs(settings: self),
                OpenFiftyTabsDebugOption(settings: self),
            ]

            settings += [
                SettingSection(title: NSAttributedString(string: "Debug"), children: hiddenDebugOptions)
            ]
        }

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! ThemedTableSectionHeaderFooterView
        return headerView
    }

    // MARK: AppSettingsDelegate

    func clickedVersion() {
        debugSettingsClickCount += 1
        if debugSettingsClickCount >= 5 {
            debugSettingsClickCount = 0
            showDebugSettings = !showDebugSettings
            settings = generateSettings()
            tableView.reloadData()
        }
    }
}

extension AppSettingsTableViewController: SearchBarLocationProvider {}
