// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

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
    private var debugSettingsClickCount: Int = 0
    private var appAuthenticator: AppAuthenticationProtocol
    private var applicationHelper: ApplicationHelper
    private let logger: Logger

    weak var parentCoordinator: SettingsFlowDelegate?

    // MARK: - Data Settings
    private var sendAnonymousUsageDataSetting: BoolSetting?
    private var sendCrashReportsSetting: BoolSetting?
    private var studiesToggleSetting: BoolSetting?

    // MARK: - Initializers
    init(with profile: Profile,
         and tabManager: TabManager,
         settingsDelegate: SettingsDelegate,
         parentCoordinator: SettingsFlowDelegate,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
         applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
         logger: Logger = DefaultLogger.shared) {
        self.appAuthenticator = appAuthenticator
        self.applicationHelper = applicationHelper
        self.logger = logger

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

        setupNavigationBar()
        configureAccessibilityIdentifiers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        askedToReload()
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
        let isSentCrashReportsEnabled = featureFlags.isFeatureEnabled(.tosFeature, checking: .buildOnly)

        let anonymousUsageDataSetting = SendDataSetting(
            prefs: profile.prefs,
            delegate: settingsDelegate,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            settingsDelegate: parentCoordinator,
            sendDataType: .usageData
        )

        let studiesSetting = StudiesToggleSetting(
            prefs: profile.prefs,
            delegate: settingsDelegate,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            settingsDelegate: parentCoordinator
        )

        anonymousUsageDataSetting.shouldSendData = { value in
            studiesSetting.updateSetting(for: value)
        }

        // Only add this toggle to the Settings if Terms Of Service feature flag is enabled
        if isSentCrashReportsEnabled {
            let sendCrashReportsSettings = SendDataSetting(
                prefs: profile.prefs,
                delegate: settingsDelegate,
                theme: themeManager.getCurrentTheme(for: windowUUID),
                settingsDelegate: parentCoordinator,
                sendDataType: .crashReports
            )
            sendCrashReportsSettings.shouldSendData = { value in
                // TODO: FXIOS-10348 Firefox iOS: Manage Privacy Preferences in Settings
            }
            self.sendCrashReportsSetting = sendCrashReportsSettings
        }

        sendAnonymousUsageDataSetting = anonymousUsageDataSetting
        studiesToggleSetting = studiesSetting
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
                               children: [DefaultBrowserSetting(theme: themeManager.getCurrentTheme(for: windowUUID))])]
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

        let attributedString = NSAttributedString(string: .Settings.Sync.ButtonDescription)
        let accountFooterText = !profile.hasAccount() ? attributedString : nil

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

        let inactiveTabsAreBuildActive = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly)
        if inactiveTabsAreBuildActive {
            generalSettings.insert(
                TabsSetting(
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    settingsDelegate: parentCoordinator
                ),
                at: 3
            )
        }

        let offerToOpenCopiedLinksSettings = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: "showClipboardBar",
            defaultValue: false,
            titleText: .SettingsOfferClipboardBarTitle,
            statusText: String(format: .SettingsOfferClipboardBarStatus, AppName.shortName.rawValue)
        )

        let showLinksPreviewSettings = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: PrefsKeys.ContextMenuShowLinkPreviews,
            defaultValue: true,
            titleText: .SettingsShowLinkPreviewsTitle,
            statusText: .SettingsShowLinkPreviewsStatus
        )

        let blockOpeningExternalAppsSettings = BoolSetting(
            prefs: profile.prefs,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            prefKey: PrefsKeys.BlockOpeningExternalApps,
            defaultValue: false,
            titleText: .SettingsBlockOpeningExternalAppsTitle
        )

        generalSettings += [
            offerToOpenCopiedLinksSettings,
            showLinksPreviewSettings,
            blockOpeningExternalAppsSettings
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

        let autofillAddressStatus = AddressLocaleFeatureValidator.isValidRegion()
        if autofillAddressStatus {
            privacySettings.append(AddressAutofillSetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                                          profile: profile,
                                                          settingsDelegate: parentCoordinator))
        }

        privacySettings.append(ClearPrivateDataSetting(settings: self, settingsDelegate: parentCoordinator))

        privacySettings += [
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
        ]

        privacySettings.append(ContentBlockerSetting(settings: self, settingsDelegate: parentCoordinator))

        privacySettings.append(NotificationsSetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                                    profile: profile,
                                                    settingsDelegate: parentCoordinator))

        privacySettings += [
            PrivacyPolicySetting(theme: themeManager.getCurrentTheme(for: windowUUID),
                                 settingsDelegate: parentCoordinator)
        ]

        return [SettingSection(title: NSAttributedString(string: .AppSettingsPrivacyTitle),
                               children: privacySettings)]
    }

    private func getSupportSettings() -> [SettingSection] {
        guard let sendAnonymousUsageDataSetting, let studiesToggleSetting else { return [] }
        let isSentFromFirefoxEnabled = featureFlags.isFeatureEnabled(.sentFromFirefox, checking: .buildOnly)

        var supportSettings = [
            ShowIntroductionSetting(settings: self, settingsDelegate: self),
            SendFeedbackSetting(settingsDelegate: parentCoordinator),
        ]

        // Only add this toggle to the Settings if Sent from Firefox feature flag is enabled
        if isSentFromFirefoxEnabled {
            supportSettings.append(
                SentFromFirefoxSetting(
                    prefs: profile.prefs,
                    delegate: settingsDelegate,
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    settingsDelegate: parentCoordinator
                )
            )
        }

        supportSettings.append(sendAnonymousUsageDataSetting)
        if let sendCrashReportsSetting {
            supportSettings.append(sendCrashReportsSetting)
        }

        supportSettings.append(contentsOf: [
            studiesToggleSetting,
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
            FirefoxSuggestSettings(settings: self, settingsDelegate: self)
        ]

        #if MOZ_CHANNEL_BETA || MOZ_CHANNEL_FENNEC
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
