// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Ecosia

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

    weak var parentCoordinator: SettingsFlowDelegate?

    // MARK: - Data Settings
    private var sendAnonymousUsageDataSetting: BoolSetting?
    private var studiesToggleSetting: BoolSetting?

    // MARK: - Initializers
    init(with profile: Profile,
         and tabManager: TabManager,
         delegate: SettingsDelegate? = nil,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.appAuthenticator = appAuthenticator
        self.applicationHelper = applicationHelper

        // Ecosia: Update TableView to grouped style
        // super.init(windowUUID: tabManager.windowUUID)
        super.init(style: .insetGrouped, windowUUID: tabManager.windowUUID)

        self.profile = profile
        self.tabManager = tabManager
        self.settingsDelegate = delegate
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

        // Ecosia: Register Nudge Card if needed
        if User.shared.shouldShowDefaultBrowserSettingNudgeCard {
            tableView.register(DefaultBrowserSettingsNudgeCardHeaderView.self,
                               forHeaderFooterViewReuseIdentifier: DefaultBrowserSettingsNudgeCardHeaderView.cellIdentifier)
        }
    }

    /* Ecosia: Move settings reload to `viewWillAppear`
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        askedToReload()
    }
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            openHelpDialogOrRateApp()
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

    // MARK: Ecosia

    private func openHelpDialogOrRateApp() {
        let rateAction = UIAlertAction(title: .localized(.settingsRatingPromptYes), style: .default) { _ in
            UIApplication.shared.open(EcosiaEnvironment.current.urlProvider.storeWriteReviewPage)
        }

        let helpAction = UIAlertAction(title: .localized(.settingsRatingPromptNo), style: .destructive) { [weak self] _ in
            self?.settingsDelegate?.settingsOpenURLInNewTab(EcosiaEnvironment.current.urlProvider.helpPage)
            self?.dismissVC()
        }

        let alertController = UIAlertController(title: .localized(.settingsRatingPromptTitle), message: nil, preferredStyle: .alert)
        alertController.addAction(rateAction)
        alertController.addAction(helpAction)
        present(alertController, animated: true)
    }

    // MARK: - User AutheSntication

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
        let anonymousUsageDataSetting = SendAnonymousUsageDataSetting(
            prefs: profile.prefs,
            delegate: settingsDelegate,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            settingsDelegate: parentCoordinator
        )

        let studiesSetting = StudiesToggleSetting(
            prefs: profile.prefs,
            delegate: settingsDelegate,
            theme: themeManager.getCurrentTheme(for: windowUUID),
            settingsDelegate: parentCoordinator
        )

        anonymousUsageDataSetting.shouldSendUsageData = { value in
            studiesSetting.updateSetting(for: value)
        }

        sendAnonymousUsageDataSetting = anonymousUsageDataSetting
        studiesToggleSetting = studiesSetting
    }

    // MARK: - Generate Settings

    override func generateSettings() -> [SettingSection] {
        /* Ecosia: Review Settings
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
         */
        getEcosiaSettingsSectionsShowingDebug(showDebugSettings)
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
        let supportSettings = [
            ShowIntroductionSetting(settings: self, settingsDelegate: self),
            SendFeedbackSetting(settingsDelegate: parentCoordinator),
            sendAnonymousUsageDataSetting,
            studiesToggleSetting,
            OpenSupportPageSetting(delegate: settingsDelegate,
                                   theme: themeManager.getCurrentTheme(for: windowUUID),
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

    /* Ecosia: Set the header view for the table view with custom handling for the default browser nudge card
       Adds other overrides after this one to modify the UI logic
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as! ThemedTableSectionHeaderFooterView
        return headerView
    }
     */
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowDefaultBrowserNudgeCardInSection(section),
           let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: DefaultBrowserSettingsNudgeCardHeaderView.cellIdentifier)
            as? DefaultBrowserSettingsNudgeCardHeaderView {
            header.onDismiss = { [weak self] in
                User.shared.hideDefaultBrowserSettingNudgeCard()
                Analytics.shared.defaultBrowserSettingsViaNudgeCardDismiss()
                self?.hideDefaultBrowserNudgeCardInSection(section)
            }
            header.onTap = { [weak self] in
                self?.showDefaultBrowserDetailView()
            }
            header.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            return header
        } else if let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView {
            return headerView
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard shouldShowDefaultBrowserNudgeCardInSection(section) else {
            return super.tableView(tableView, viewForFooterInSection: section)
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard shouldShowDefaultBrowserNudgeCardInSection(section) else {
            return super.tableView(tableView, heightForFooterInSection: section)
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowDefaultBrowserNudgeCardInSection(section) {
            return UITableView.automaticDimension
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowDefaultBrowserNudgeCardInSection(section) {
            return 1
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldShowDefaultBrowserNudgeCardInSection(indexPath.section) {
            let cell = UITableViewCell()
            cell.isUserInteractionEnabled = false
            cell.backgroundColor = .clear
            cell.contentView.isHidden = true
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldShowDefaultBrowserNudgeCardInSection(indexPath.section) {
            return .leastNonzeroMagnitude
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
}
