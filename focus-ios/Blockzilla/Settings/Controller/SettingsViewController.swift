/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Intents
import IntentsUI
import Glean
import SwiftUI
import Onboarding
import Combine
import Licenses
import DesignSystem

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum Section: String {
        case defaultBrowser, general, privacy, usageData, crashReports, studies, dailyUsagePing, search, siri, integration, mozilla, secret

        var headerText: String? {
            switch self {
            case .defaultBrowser: return nil
            case .general: return UIConstants.strings.general
            case .privacy: return UIConstants.strings.toggleSectionPrivacy
            case .usageData: return nil
            case .studies: return nil
            case .search: return UIConstants.strings.settingsSearchTitle
            case .siri: return UIConstants.strings.siriShortcutsTitle
            case .integration: return UIConstants.strings.toggleSectionSafari
            case .mozilla: return UIConstants.strings.toggleSectionMozilla
            case .secret: return nil
            case .crashReports: return nil
            case .dailyUsagePing: return nil
            }
        }

        static func getSections() -> [Section] {
            var sections: [Section] = [
                .defaultBrowser,
                .general,
                .privacy
                ]

            if TelemetryManager.shared.isTelemetryFeatureEnabled {
                sections.append(contentsOf: [.studies, .usageData])
            }

            sections.append(contentsOf: [
                .dailyUsagePing,
                .crashReports,
                .search,
                .siri,
                integration,
                .mozilla
            ])

            if Settings.getToggle(.displaySecretMenu) {
                sections.append(.secret)
            }

            return sections
        }
    }

    private let dismissScreenCompletion: (() -> Void)

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.allowsSelection = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let doneButton = UIBarButtonItem(title: UIConstants.strings.done, style: .plain, target: self, action: #selector(dismissSettings))
        doneButton.tintColor = .accent
        doneButton.accessibilityIdentifier = "SettingsViewController.doneButton"
        return doneButton
    }()

    private var onboardingEventsHandler: OnboardingEventsHandling
    private var themeManager: ThemeManager
    // Hold a strong reference to the block detector so it isn't deallocated
    // in the middle of its detection.
    private let detector = BlockerEnabledDetector()
    private let authenticationManager: AuthenticationManager
    private var isSafariEnabled = false
    private let searchEngineManager: SearchEngineManager
    private let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService
    private lazy var sections = {
        Section.getSections()
    }()

    private var toggles = [Int: [Int: BlockerToggle]]()

    private var labelTextForCurrentTheme: String {
        var themeName = ""
        switch themeManager.selectedTheme {
        case .unspecified:
            themeName = UIConstants.strings.systemTheme
        case .light:
            themeName = UIConstants.strings.light
        case .dark:
            themeName = UIConstants.strings.dark
        @unknown default:
            break
        }
        return themeName
    }

    private lazy var tableViewConstraints = [
        tableView.topAnchor.constraint(equalTo: view.topAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ]

    private func getSectionIndex(_ section: Section) -> Int? {
        return Section.getSections().firstIndex(where: { $0 == section })
    }

    private func initializeToggles() {
        let blockFontsToggle = BlockerToggle(label: UIConstants.strings.labelBlockFonts, setting: SettingsToggle.blockFonts)
        let studiesSubtitle = String(format: UIConstants.strings.detailTextStudies, AppInfo.productName)
        let studiesToggle = BlockerToggle(label: UIConstants.strings.labelStudies, setting: SettingsToggle.studies, subtitle: studiesSubtitle)
        let usageDataSubtitle = String(format: UIConstants.strings.detailTextSendUsageData, AppInfo.productName)
        let usageDataToggle = BlockerToggle(label: UIConstants.strings.labelSendAnonymousUsageData, setting: SettingsToggle.sendAnonymousUsageData, subtitle: usageDataSubtitle)
        let crashToggle = BlockerToggle(
            label: UIConstants.strings.labelCrashReports,
            setting: SettingsToggle.crashToggle,
            subtitle: UIConstants.strings.detailTextCrashReportsV2
        )
        let dailyUsageToggle = BlockerToggle(
            label: UIConstants.strings.labelDailyUsagePing,
            setting: SettingsToggle.dailyUsagePing,
            subtitle: UIConstants.strings.detailTextDailyUsagePing
        )
        let searchSuggestionSubtitle = String(format: UIConstants.strings.detailTextSearchSuggestion, AppInfo.productName)
        let searchSuggestionToggle = BlockerToggle(label: UIConstants.strings.settingsSearchSuggestions, setting: SettingsToggle.enableSearchSuggestions, subtitle: searchSuggestionSubtitle)
        let safariToggle = BlockerToggle(label: UIConstants.strings.toggleSafari, setting: SettingsToggle.safari)
        let homeScreenTipsToggle = BlockerToggle(label: UIConstants.strings.toggleHomeScreenTips, setting: SettingsToggle.showHomeScreenTips)

        if let privacyIndex = getSectionIndex(Section.privacy) {
            if let biometricToggle = createBiometricLoginToggleIfAvailable() {
                toggles[privacyIndex] =  [1: blockFontsToggle, 2: biometricToggle]
            } else {
                toggles[privacyIndex] = [1: blockFontsToggle]
            }
        }
        if let usageDataIndex = getSectionIndex(Section.usageData) {
            toggles[usageDataIndex] = [0: usageDataToggle]
        }
        if let studiesIndex = getSectionIndex(Section.studies) {
            toggles[studiesIndex] = [0: studiesToggle]
        }
        if let dailyUsageIndex = getSectionIndex(.dailyUsagePing) {
            toggles[dailyUsageIndex] = [0: dailyUsageToggle]
        }
        if let crashIndex = getSectionIndex(.crashReports) {
            toggles[crashIndex] = [0: crashToggle]
        }
        if let searchIndex = getSectionIndex(Section.search) {
            toggles[searchIndex] = [2: searchSuggestionToggle]
        }
        if let integrationIndex = getSectionIndex(Section.integration) {
            toggles[integrationIndex] = [0: safariToggle]
        }
        if let mozillaIndex = getSectionIndex(Section.mozilla) {
            toggles[mozillaIndex] = [0: homeScreenTipsToggle]
        }
    }

    private var shouldScrollToSiri: Bool

    init(
        searchEngineManager: SearchEngineManager,
        authenticationManager: AuthenticationManager,
        onboardingEventsHandler: OnboardingEventsHandling,
        gleanUsageReportingMetricsService: GleanUsageReportingMetricsService,
        themeManager: ThemeManager,
        dismissScreenCompletion: @escaping (() -> Void),
        shouldScrollToSiri: Bool = false
    ) {
        self.searchEngineManager = searchEngineManager
        self.shouldScrollToSiri = shouldScrollToSiri
        self.authenticationManager = authenticationManager
        self.onboardingEventsHandler = onboardingEventsHandler
        self.gleanUsageReportingMetricsService = gleanUsageReportingMetricsService
        self.themeManager = themeManager
        self.dismissScreenCompletion =  dismissScreenCompletion
        super.init(nibName: nil, bundle: nil)

        tableView.register(SettingsTableViewAccessoryCell.self, forCellReuseIdentifier: "accessoryCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.settingsTitle

        let navigationBar = navigationController!.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.layoutIfNeeded()
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.primaryText]
        navigationItem.rightBarButtonItem = doneButton

        view.addSubview(tableView)

        NSLayoutConstraint.activate(tableViewConstraints)

        initializeToggles()
        for (sectionIndex, toggleArray) in toggles {
            for (cellIndex, blockerToggle) in toggleArray {
                let toggle = blockerToggle.toggle
                toggle.onTintColor = .accent
                toggle.tintColor = .darkGray
                toggle.addTarget(self, action: #selector(toggleSwitched(_:)), for: .valueChanged)
                if blockerToggle.setting == .dailyUsagePing {
                    toggle.isOn = TelemetryManager.shared.isNewTosEnabled
                } else {
                    toggle.isOn = Settings.getToggle(blockerToggle.setting)
                }
                if blockerToggle.setting == .studies {
                    toggle.isEnabled = Settings.getToggle(.sendAnonymousUsageData)
                }
                toggles[sectionIndex]?[cellIndex] = blockerToggle
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSafariEnabledState()
        tableView.reloadData()
        if shouldScrollToSiri {
            guard let siriSection = getSectionIndex(Section.siri) else {
                shouldScrollToSiri = false
                return
            }
            let siriIndexPath = IndexPath(row: 0, section: siriSection)
            tableView.scrollToRow(at: siriIndexPath, at: .none, animated: false)
            shouldScrollToSiri = false
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.removeConstraints(tableViewConstraints)
        NSLayoutConstraint.activate(tableViewConstraints)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    @objc
    private func applicationDidBecomeActive() {
        // On iOS 9, we detect the blocker status by loading an invisible SafariViewController
        // in the current view. We can only run the detector if the view is visible; otherwise,
        // the detection callback won't fire and the detector won't be cleaned up.
        if isViewLoaded && view.window != nil {
            updateSafariEnabledState()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard themeManager.selectedTheme == .unspecified  else { return }
        themeManager.set(.device)
    }

    private func createBiometricLoginToggleIfAvailable() -> BlockerToggle? {
        guard authenticationManager.canEvaluatePolicy else { return nil }

        let label: String
        let subtitle: String

        switch authenticationManager.biometricType {
        case .faceID:
            label = UIConstants.strings.labelFaceIDLogin
            subtitle = String(format: UIConstants.strings.labelFaceIDLoginDescription, AppInfo.productName)
        case .touchID:
            label = UIConstants.strings.labelTouchIDLogin
            subtitle = String(format: UIConstants.strings.labelTouchIDLoginDescription, AppInfo.productName)
        default:
            // Unknown biometric type
            return nil
        }

        let toggle = BlockerToggle(label: label, setting: SettingsToggle.biometricLogin, subtitle: subtitle)
        toggle.toggle.isEnabled = authenticationManager.canEvaluatePolicy
        return toggle
    }

    private func toggleForIndexPath(_ indexPath: IndexPath) -> BlockerToggle {
        guard let toggle = toggles[indexPath.section]?[indexPath.row]
            else { return BlockerToggle(label: "Error", setting: SettingsToggle.blockAds)}
        return toggle
    }

    private func setupToggleCell(indexPath: IndexPath, navigationController: UINavigationController?) -> SettingsTableViewToggleCell {
        let toggle = toggleForIndexPath(indexPath)
        let cell = SettingsTableViewToggleCell(style: .subtitle, reuseIdentifier: "toggleCell", toggle: toggle)
        cell.navigationController = navigationController
        return cell
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        switch sections[indexPath.section] {
        case .defaultBrowser:
            let defaultBrowserCell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "defaultBrowserCell")
            defaultBrowserCell.textLabel?.text = String(format: UIConstants.strings.setAsDefaultBrowserLabel)
            defaultBrowserCell.accessibilityIdentifier = "settingsViewController.defaultBrowserCell"
            cell = defaultBrowserCell
        case .general:
            let themeCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "themeCell")
            themeCell.accessibilityIdentifier = "settingsViewController.themeCell"
            themeCell.setConfiguration(text: String(format: UIConstants.strings.theme), secondaryText: labelTextForCurrentTheme)
            cell = themeCell
        case .privacy:
            if indexPath.row == 0 {
                let trackingCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "trackingCell")
                trackingCell.accessibilityIdentifier = "settingsViewController.trackingCell"
                let secondaryText = Settings.getToggle(.trackingProtection) ?
                    UIConstants.strings.settingsTrackingProtectionOn :
                    UIConstants.strings.settingsTrackingProtectionOff
                trackingCell.setConfiguration(text: String(format: UIConstants.strings.trackingProtectionLabel), secondaryText: secondaryText)
                cell = trackingCell
            } else {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            }
        case .usageData:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        case .studies:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        case .search:
            if indexPath.row < 2 {
                let searchCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "accessoryCell")
                let autocompleteLabel = Settings.getToggle(.enableDomainAutocomplete) || Settings.getToggle(.enableCustomDomainAutocomplete) ? UIConstants.strings.autocompleteCustomEnabled : UIConstants.strings.autocompleteCustomDisabled
                let (label, accessoryLabel, identifier) = indexPath.row == 0 ?
                    (UIConstants.strings.settingsSearchLabel, searchEngineManager.activeEngine.name, "SettingsViewController.searchCell")
                    : (UIConstants.strings.settingsAutocompleteSection, autocompleteLabel, "SettingsViewController.autocompleteCell")
                searchCell.setConfiguration(text: label, secondaryText: accessoryLabel)
                searchCell.accessibilityIdentifier = identifier
                cell = searchCell
            } else {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            }
        case .siri:
            let siriCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "accessoryCell")
            if indexPath.row == 0 {
                siriCell.accessibilityIdentifier = "settingsViewController.siriEraseCell"
                SiriShortcuts().hasAddedActivity(type: .erase) { (result: Bool) in
                    let secondaryText = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                    siriCell.setConfiguration(text: UIConstants.strings.eraseSiri, secondaryText: secondaryText)
                }
            } else if indexPath.row == 1 {
                siriCell.accessibilityIdentifier = "settingsViewController.siriEraseAndOpenCell"
                SiriShortcuts().hasAddedActivity(type: .eraseAndOpen) { (result: Bool) in
                    let secondaryText = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                    siriCell.setConfiguration(text: UIConstants.strings.eraseAndOpenSiri, secondaryText: secondaryText)
                }
            } else {
                siriCell.accessibilityIdentifier = "settingsViewController.siriOpenURLCell"
                SiriShortcuts().hasAddedActivity(type: .openURL) { (result: Bool) in
                    let secondaryText = result ? UIConstants.strings.Edit : UIConstants.strings.add
                    siriCell.setConfiguration(text: UIConstants.strings.openUrlSiri, secondaryText: secondaryText)
                }
            }
            cell = siriCell
        case .integration:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        case .mozilla:
            if indexPath.row == 0 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "aboutCell")
                cell.textLabel?.text = String(format: UIConstants.strings.aboutTitle, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.about"
            } else if indexPath.row == 1 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "ratingCell")
                cell.textLabel?.text = String(format: UIConstants.strings.ratingSetting, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.rateFocus"
            } else {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "licensesCell")
                cell.textLabel?.text = UIConstants.strings.licenses
                cell.accessibilityIdentifier = "settingsViewController.licenses"
            }
        case .secret:
            cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "secretSettingsCell")
            cell.textLabel?.text = "Internal Settings"
        case .crashReports:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        case .dailyUsagePing:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        }

        cell.textLabel?.textColor = .primaryText
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = .secondaryText

        return cell
    }

    func numberOfRows(for section: Section) -> Int {
        switch section {
        case .defaultBrowser: return 1
        case .general: return 1
        case .privacy:
            if authenticationManager.canEvaluatePolicy { return 3 }
            return 2
        case .usageData: return 1
        case .studies: return 1
        case .search: return 3
        case .siri: return 3
        case .integration: return 1
        case .mozilla: return 3
        case .secret: return 1
        case .crashReports: return 1
        case .dailyUsagePing: return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRows(for: sections[section])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // If a toggle subtitle exists, create a standard footer with optional learn more actions
        if let text = toggles[section]?.first?.value.subtitle {
            let footer = ActionFooterView(frame: .zero)
            footer.textLabel.text = text
            var learnMoreActions = [Int: Selector]()

            let actions: [(Int?, Selector)] = [
                (getSectionIndex(.usageData), #selector(tappedLearnMoreFooter)),
                (getSectionIndex(.search), #selector(tappedLearnMoreSearchSuggestionsFooter)),
                (getSectionIndex(.studies), #selector(tappedLearnMoreStudies)),
                (getSectionIndex(.crashReports), #selector(tappedLearnMoreCrashReports)),
                (getSectionIndex(.dailyUsagePing), #selector(tappedLearnMoreDailyUsagePing))
            ]

            for (index, action) in actions {
                if let index {
                    learnMoreActions[index] = action
                }
            }

            if let selector = learnMoreActions[section] {
                let tapGesture = UITapGestureRecognizer(target: self, action: selector)
                footer.detailTextButton.setTitle(UIConstants.strings.learnMore, for: .normal)
                footer.detailTextButton.addGestureRecognizer(tapGesture)
            }
            return footer
        }
        if section == getSectionIndex(.defaultBrowser) {
            let footer = ActionFooterView(frame: .zero)
            footer.textLabel.text = String(format: UIConstants.strings.setAsDefaultBrowserDescriptionLabel, AppInfo.productName)
            return footer
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .defaultBrowser:
            GleanMetrics.SettingsScreen.setAsDefaultBrowserPressed.add()
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString, invalidCharacters: false)!,
                                      options: [:])
        case .general:
            let themeVC = ThemeViewController(themeManager: themeManager)
            navigationController?.pushViewController(themeVC, animated: true)
        case .privacy:
            if indexPath.row == 0 {
                let trackingProtectionVC = TrackingProtectionViewController(state: .settings, onboardingEventsHandler: onboardingEventsHandler)
                trackingProtectionVC.delegate = presentingViewController as? BrowserViewController
                navigationController?.pushViewController(trackingProtectionVC, animated: true)
            }
        case .search:
            if indexPath.row == 0 {
                let searchSettingsViewController = SearchSettingsViewController(searchEngineManager: searchEngineManager)
                searchSettingsViewController.delegate = self
                navigationController?.pushViewController(searchSettingsViewController, animated: true)
            } else if indexPath.row == 1 {
                let autcompleteSettingViewController = AutocompleteSettingViewController()
                navigationController?.pushViewController(autcompleteSettingViewController, animated: true)
            }
        case .siri:
            if indexPath.row == 0 {
                SiriShortcuts().manageSiri(for: SiriShortcuts.activityType.erase, in: self)
                TipManager.siriEraseTip = false
            } else if indexPath.row == 1 {
                SiriShortcuts().manageSiri(for: SiriShortcuts.activityType.eraseAndOpen, in: self)
                TipManager.siriEraseTip = false
            } else {
                let siriFavoriteVC = SiriFavoriteViewController()
                navigationController?.pushViewController(siriFavoriteVC, animated: true)
            }
        case .mozilla:
            if indexPath.row == 0 {
                aboutClicked()
            } else if indexPath.row == 1 {
                let appId = AppInfo.config.appId
                if let reviewURL = URL(string: "https://itunes.apple.com/app/id\(appId)?action=write-review",
                                       invalidCharacters: false),
                    UIApplication.shared.canOpenURL(reviewURL) {
                    UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
                }
            } else {
                navigationController?.pushViewController(UIHostingController(rootView: LicenseListView().navigationBarTitle(UIConstants.strings.licenses)), animated: true)
            }
        case .secret:
            if indexPath.row == 0 {
                let hostingController = UIHostingController(rootView: InternalSettingsView())
                hostingController.title = "Internal Settings"
                navigationController?.pushViewController(hostingController, animated: true)
            }
        default: break
        }
    }

    private func updateSafariEnabledState() {
        guard let index = getSectionIndex(Section.integration),
            let safariToggle = toggles[index]?[0]?.toggle else { return }
        safariToggle.isEnabled = false

        detector.detectEnabled(view) { [weak self] enabled in
            safariToggle.isOn = enabled && Settings.getToggle(.safari)
            safariToggle.isEnabled = true
            self?.isSafariEnabled = enabled
        }
    }

    private func tappedFooter(forSupportTopic topic: SupportTopic) {
        let contentViewController = SettingsContentViewController(url: URL(forSupportTopic: topic))
        navigationController?.navigationBar.tintColor = .accent
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    @objc
    func tappedLearnMoreFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(forSupportTopic: .usageData)
    }

    @objc
    func tappedLearnMoreSearchSuggestionsFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(forSupportTopic: .searchSuggestions)
    }

    @objc
    func tappedLearnMoreStudies(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(forSupportTopic: .studies)
    }

    @objc
    func tappedLearnMoreCrashReports() {
        tappedFooter(forSupportTopic: .mobileCrashReports)
    }

    @objc
    func tappedLearnMoreDailyUsagePing() {
        tappedFooter(forSupportTopic: .usagePingSettingsMobile)
    }

    @objc
    private func dismissSettings() {
        #if DEBUG
        if let browserViewController = presentingViewController as? BrowserViewController {
            browserViewController.refreshTipsDisplay()
        }
        #endif
        self.dismiss(animated: true, completion: dismissScreenCompletion)
    }

    @objc
    private func aboutClicked() {
        navigationController!.pushViewController(AboutViewController(), animated: true)
    }

    @objc
    private func toggleSwitched(_ sender: UISwitch) {
        let toggle = toggles.values.filter { $0.values.contains(where: { $0.toggle == sender }) }[0].values.filter { $0.toggle == sender }[0]

        func updateSetting(_ value: Bool, forToggle toggle: SettingsToggle) {
            Settings.set(value, forToggle: toggle)
            ContentBlockerHelper.shared.reload()
            Utils.reloadSafariContentBlocker()
        }

        func disableAndTurnOffStudiesToggle(_ sender: UISwitch) {
            // Gray out the toggle
            sender.isOn = false
            sender.isEnabled = false
            sender.alpha = 0.5
            NimbusWrapper.shared.nimbus.globalUserParticipation = false
            updateSetting(false, forToggle: .studies)
        }

        // Find the 'studies' toggle
        let studiesToggle = toggles.values
            .flatMap { $0.values }
            .first(where: { $0.setting == .studies })?.toggle

        // Find the 'Send usage data' toggle
        let sendAnonymousUsageDataToggle = toggles.values
            .flatMap { $0.values }
            .first(where: { $0.setting == .sendAnonymousUsageData })?.toggle

        // The following settings are special and need to be in effect immediately.
        if toggle.setting == .sendAnonymousUsageData {
            Glean.shared.setCollectionEnabled(sender.isOn)
            if !sender.isOn {
                UsageProfileManager.unsetUsageProfileId()
                NimbusWrapper.shared.nimbus.resetTelemetryIdentifiers()
            } else {
                UsageProfileManager.checkAndSetUsageProfileId()
            }

            // Disable and turn off 'studies' if 'sendAnonymousUsageData' is turned off
            if let studiesToggle = studiesToggle {
                if !sender.isOn {
                    disableAndTurnOffStudiesToggle(studiesToggle)
                } else {
                    // Restore toggle's appearance
                    studiesToggle.isEnabled = true
                    studiesToggle.alpha = 1.0
                }
            }
        } else if toggle.setting == .studies {
            // Ensure 'studies' is disabled if 'sendAnonymousUsageData' is turned off, even when 'studies' is being enabled.
            if sendAnonymousUsageDataToggle?.isOn == true {
                NimbusWrapper.shared.nimbus.globalUserParticipation = sender.isOn
            } else {
                disableAndTurnOffStudiesToggle(sender)
            }
        } else if toggle.setting == .biometricLogin {
            TipManager.biometricTip = false
        } else if toggle.setting == .dailyUsagePing {
            if sender.isOn {
                gleanUsageReportingMetricsService.start()
            } else {
                gleanUsageReportingMetricsService.stop()
            }
        }

        switch toggle.setting {
        case .safari where sender.isOn && !isSafariEnabled:
            let instructionsViewController = SafariInstructionsViewController()
            navigationController!.pushViewController(instructionsViewController, animated: true)
            updateSetting(sender.isOn, forToggle: toggle.setting)
        case .enableSearchSuggestions:
            UserDefaults.standard.set(true, forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt)
            updateSetting(sender.isOn, forToggle: toggle.setting)
            GleanMetrics
                .ShowSearchSuggestions
                .changedFromSettings
                .record(
                    GleanMetrics
                        .ShowSearchSuggestions
                        .ChangedFromSettingsExtra(isEnabled: sender.isOn)
                )
        case .showHomeScreenTips:
            updateSetting(sender.isOn, forToggle: toggle.setting)
            // This update must occur after the setting has been updated to properly take effect.
            if let browserViewController = presentingViewController as? BrowserViewController {
                browserViewController.refreshTipsDisplay()
            }
        default:
            updateSetting(sender.isOn, forToggle: toggle.setting)
        }
    }
}

extension SettingsViewController: SearchSettingsViewControllerDelegate {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didSelectEngine engine: SearchEngine) {
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SettingsTableViewAccessoryCell {
            var configuration = cell.defaultContentConfiguration()
            let margins = configuration.directionalLayoutMargins
            configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: margins.top, leading: UIConstants.layout.settingsCellLeftInset, bottom: margins.bottom, trailing: margins.trailing)
            configuration.secondaryText = engine.name
            cell.contentConfiguration = configuration
        }
    }
}

extension SettingsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }

    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
