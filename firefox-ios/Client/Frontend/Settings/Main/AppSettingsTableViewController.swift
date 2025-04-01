// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Glean

// MARK: - Settings Flow Delegate Protocol

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
    func showFirefoxSuggest()
    func openDebugTestTabs(count: Int)
    func showDebugFeatureFlags()
    func showPasswordManager(shouldShowOnboarding: Bool)
    func didFinishShowingSettings()
}

// MARK: - App Settings Screen Protocol

protocol AppSettingsScreen: UIViewController {
    var settingsDelegate: SettingsDelegate? { get set }
    var parentCoordinator: SettingsFlowDelegate? { get set }

    func handle(route: Route.SettingsSection)
}

// MARK: - App Settings Table View Controller

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController,
                                      AppSettingsScreen,
                                      FeatureFlaggable,
                                      DebugSettingsDelegate,
                                      SearchBarLocationProvider,
                                      SharedSettingsDelegate {
    // MARK: - Properties
    private var showDebugSettings = false
    private var debugSettingsClickCount = 0
    private var appAuthenticator: AppAuthenticationProtocol
    private var applicationHelper: ApplicationHelper
    private let logger: Logger
    private let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService
    private var hasAppearedBefore = false

    weak var parentCoordinator: SettingsFlowDelegate?

    // MARK: - Data Settings
    private var sendTechnicalDataSetting: SendDataSetting?
    private var sendCrashReportsSetting: SendDataSetting?
    private var sendDailyUsagePingSetting: SendDataSetting?
    private var studiesToggleSetting: SendDataSetting?

    // MARK: - Initializers
    init(
        with profile: Profile,
        and tabManager: TabManager,
        settingsDelegate: SettingsDelegate,
        parentCoordinator: SettingsFlowDelegate,
        gleanUsageReportingMetricsService: GleanUsageReportingMetricsService,
        appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
        applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.appAuthenticator = appAuthenticator
        self.applicationHelper = applicationHelper
        self.logger = logger
        self.gleanUsageReportingMetricsService = gleanUsageReportingMetricsService

        super.init(windowUUID: tabManager.windowUUID)
        self.profile = profile
        self.tabManager = tabManager
        self.settingsDelegate = settingsDelegate
        self.parentCoordinator = parentCoordinator
        setupNavigationBar()
        setupDataSettings()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cellType: ThemedLearnMoreTableViewCell.self)
        setupNavigationBar()
        configureAccessibilityIdentifiers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if hasAppearedBefore {
            // Only reload if we're returning from a child view
            askedToReload()
        }

        hasAppearedBefore = true
    }

    // MARK: - Actions

    @objc
    private func done() {
        settingsDelegate?.didFinish()
    }

    // MARK: - Navigation Bar Setup
    private func setupNavigationBar() {
        navigationItem.title = String.AppSettingsTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .AppSettingsDone,
            style: .done,
            target: self,
            action: #selector(done))
    }

    // MARK: - Accessibility Identifiers
    func configureAccessibilityIdentifiers() {
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Settings.navigationBarItem
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings.tableViewController
    }

    // MARK: - Route Handling

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

    // MARK: - User Authentication

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

    // MARK: Data settings setup

    private func setupDataSettings() {
        guard let profile else { return }

        let studiesSetting = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            titleText: .StudiesSettingTitleV2,
            subtitleText: .StudiesSettingMessageV2,
            learnMoreText: .StudiesSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("ios-studies"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.studiesTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.studiesLearnMoreButton,
            settingsDelegate: parentCoordinator,
            isStudiesCase: true
        )
        studiesSetting.settingDidChange = {
            Experiments.setStudiesSetting($0)
        }

        let sendTechnicalDataSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            titleText: .SendTechnicalDataSettingTitleV2,
            subtitleText: String(format: .SendTechnicalDataSettingMessageV2, AppName.shortName.rawValue),
            learnMoreText: .SendTechnicalDataSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("mobile-technical-and-interaction-data"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendTechnicalDataTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendTechnicalDataLearnMoreButton,
            settingsDelegate: parentCoordinator
        )

        sendTechnicalDataSettings.settingDidChange = { [weak self] value in
            guard let self, let profile = self.profile else { return }
            TermsOfServiceManager(prefs: profile.prefs).shouldSendTechnicalData(value: value)
            studiesSetting.updateSetting(for: value)
            tableView.reloadData()
        }
        sendTechnicalDataSetting = sendTechnicalDataSettings

        let sendDailyUsagePingSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendDailyUsagePing,
            defaultValue: true,
            titleText: .SendDailyUsagePingSettingTitle,
            subtitleText: String(format: .SendDailyUsagePingSettingMessage, MozillaName.shortName.rawValue),
            learnMoreText: .SendDailyUsagePingSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("usage-ping-settings-mobile"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendDailyUsagePingTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendDailyUsagePingLearnMoreButton,
            settingsDelegate: parentCoordinator
        )
        sendDailyUsagePingSettings.settingDidChange = { [weak self] value in
            if value {
                self?.gleanUsageReportingMetricsService.start()
            } else {
                self?.gleanUsageReportingMetricsService.stop()
            }
        }
        sendDailyUsagePingSetting = sendDailyUsagePingSettings

        let sendCrashReportsSettings = SendDataSetting(
            prefs: profile.prefs,
            prefKey: AppConstants.prefSendCrashReports,
            defaultValue: true,
            titleText: .SendCrashReportsSettingTitle,
            subtitleText: String(format: .SendCrashReportsSettingMessageV2, MozillaName.shortName.rawValue),
            learnMoreText: .SendCrashReportsSettingLinkV2,
            learnMoreURL: SupportUtils.URLForTopic("ios-crash-reports"),
            a11yId: AccessibilityIdentifiers.Settings.SendData.sendCrashReportsTitle,
            learnMoreA11yId: AccessibilityIdentifiers.Settings.SendData.sendCrashReportsLearnMoreButton,
            settingsDelegate: parentCoordinator
        )
        self.sendCrashReportsSetting = sendCrashReportsSettings

        studiesToggleSetting = studiesSetting
    }

    // MARK: - Generate Settings

    override func generateSettings() -> [SettingSection] {
        setupDataSettings()
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
                               children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])]
    }

    private func getAccountSetting() -> [SettingSection] {
        let accountSectionTitle = NSAttributedString(string: .FxAFirefoxAccount)

        let attributedString = NSAttributedString(string: .Settings.Sync.ButtonDescription)
        let accountFooterText = !(profile?.hasAccount() ?? false) ? attributedString : nil

        var settings = [
            // Without a Firefox Account:
            ConnectSetting(settings: self, settingsDelegate: parentCoordinator),
            AdvancedAccountSetting(settings: self, isHidden: showDebugSettings, settingsDelegate: parentCoordinator),
            // With a Firefox Account:
            AccountStatusSetting(settings: self, settingsDelegate: parentCoordinator),
            SyncNowSetting(settings: self, settingsDelegate: parentCoordinator)
        ]
        if AppInfo.isChinaEdition, let profile {
            settings.append(ChinaSyncServiceSetting(profile: profile, settingsDelegate: self))
        }
        return [
            SettingSection(title: accountSectionTitle, footerTitle: accountFooterText, children: settings)
        ]
    }

    private func getGeneralSettings() -> [SettingSection] {
        var generalSettings: [Setting] = [
            BrowsingSetting(settings: self, settingsDelegate: parentCoordinator),
            SearchSetting(settings: self, settingsDelegate: parentCoordinator),
            NewTabPageSetting(settings: self, settingsDelegate: parentCoordinator),
            HomeSetting(settings: self, settingsDelegate: parentCoordinator),
            ThemeSetting(settings: self, settingsDelegate: parentCoordinator)
        ]

        if isSearchBarLocationFeatureEnabled, let profile {
            generalSettings.append(
                SearchBarSetting(settings: self, profile: profile, settingsDelegate: parentCoordinator)
            )
        }

        // FXIOS-11645 For enrolled users whose devices support alternate app icons, add the App Icon setting
        if featureFlags.isFeatureEnabled(.appIconSelection, checking: .buildOnly),
           UIApplication.shared.supportsAlternateIcons {
            generalSettings.append(
                AppIconSetting(
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    settingsDelegate: parentCoordinator
                )
            )
        }

        generalSettings += [
            SiriPageSetting(settings: self, settingsDelegate: parentCoordinator)
        ]

        return [SettingSection(title: NSAttributedString(string: .SettingsGeneralSectionTitle),
                               children: generalSettings)]
    }

    private func getPrivacySettings() -> [SettingSection] {
        var privacySettings = [Setting]()

        privacySettings.append(AutofillPasswordSetting(settings: self, settingsDelegate: parentCoordinator))

        privacySettings.append(ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator))

        if let profile {
            privacySettings.append(
                BoolSetting(prefs: profile.prefs,
                            theme: themeManager.getCurrentTheme(for: windowUUID),
                            prefKey: PrefsKeys.Settings.closePrivateTabs,
                            defaultValue: true,
                            titleText: .AppSettingsClosePrivateTabsTitle,
                            statusText: .AppSettingsClosePrivateTabsDescription) { _ in
                                let action = TabTrayAction(windowUUID: self.windowUUID,
                                                           actionType: TabTrayActionType.closePrivateTabsSettingToggled)
                                store.dispatch(action)
                }
            )
        }

        privacySettings.append(ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator))

        if let profile {
            privacySettings.append(NotificationsSetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                                        profile: profile,
                                                        settingsDelegate: parentCoordinator))
        }

        privacySettings.append(PrivacyPolicySetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                                    settingsDelegate: parentCoordinator))

        return [SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle),
                               children: privacySettings)]
    }

    private func getSupportSettings() -> [SettingSection] {
        var supportSettings = [
            ShowIntroductionSetting(settings: self, settingsDelegate: self),
            SendFeedbackSetting(settingsDelegate: parentCoordinator),
        ]

        // Only add this toggle to the Settings if Sent from Firefox feature flag is enabled from Nimbus
        if featureFlags.isFeatureEnabled(.sentFromFirefox, checking: .buildOnly), let profile {
            supportSettings.append(
                SentFromFirefoxSetting(
                    prefs: profile.prefs,
                    delegate: settingsDelegate,
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    settingsDelegate: parentCoordinator
                )
            )
        }

        guard let sendTechnicalDataSetting,
              let sendDailyUsagePingSetting,
              let studiesToggleSetting,
              let sendCrashReportsSetting else {
            return []
        }

        supportSettings.append(contentsOf: [
            sendTechnicalDataSetting,
            studiesToggleSetting,
            sendDailyUsagePingSetting,
            sendCrashReportsSetting
        ])

        supportSettings.append(contentsOf: [
            OpenSupportPageSetting(delegate: settingsDelegate,
                                   theme: themeManager.getCurrentTheme(for: windowUUID),
                                   settingsDelegate: parentCoordinator),
        ])

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
        var hiddenDebugOptions = [
            ExperimentsSettings(settings: self, settingsDelegate: self),
            ExportLogDataSetting(settings: self),
            ExportBrowserDataSetting(settings: self),
            AppDataUsageReportSetting(settings: self),
            DeleteExportedDataSetting(settings: self),
            ForceCrashSetting(settings: self),
            SwitchFakespotProduction(settings: self, settingsDelegate: self),
            ChangeToChinaSetting(settings: self),
            AppReviewPromptSetting(settings: self, settingsDelegate: self),
            ToggleInactiveTabs(settings: self, settingsDelegate: self),
            ResetContextualHints(settings: self),
            ResetWallpaperOnboardingPage(settings: self, settingsDelegate: self),
            SentryIDSetting(settings: self, settingsDelegate: self),
            FasterInactiveTabs(settings: self, settingsDelegate: self),
            OpenFiftyTabsDebugOption(settings: self, settingsDelegate: self),
            FirefoxSuggestSettings(settings: self, settingsDelegate: self),
            ScreenshotSetting(settings: self)
        ]

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        hiddenDebugOptions.append(FeatureFlagsSettings(settings: self, settingsDelegate: self))
        #endif

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
        applicationHelper.open(url, inWindow: windowUUID)
    }

    func pressedFirefoxSuggest() {
        parentCoordinator?.showFirefoxSuggest()
    }

    func pressedOpenFiftyTabs() {
        parentCoordinator?.openDebugTestTabs(count: 50)
    }

    func pressedDebugFeatureFlags() {
        parentCoordinator?.showDebugFeatureFlags()
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
        guard let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView else {
            logger.log("Failed to cast or retrieve ThemedTableSectionHeaderFooterView for section: \(section)",
                       level: .fatal,
                       category: .lifecycle)
            return UIView()
        }
        return headerView
    }
}
