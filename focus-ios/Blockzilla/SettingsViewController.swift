/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import UIKit
import Telemetry
import LocalAuthentication
import Intents
import IntentsUI
import Glean

class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .gray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func setupDynamicFont(forLabels labels: [UILabel], addObserver: Bool = false) {
        for label in labels {
            label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
            label.adjustsFontForContentSizeCategory = true
        }

        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { _ in
            self.setupDynamicFont(forLabels: labels)
        }
    }
}

class SettingsTableViewAccessoryCell: SettingsTableViewCell {
    var labelText: String? {
        get { return textLabel?.text }
        set {
            textLabel?.text = newValue
        }
    }
    
    var accessoryLabelText: String? {
        get { return detailTextLabel?.text }
        set {
            detailTextLabel?.text = newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
        tintColor = .secondaryText.withAlphaComponent(0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingsTableViewToggleCell: SettingsTableViewCell {
    private let newLabel = SmartLabel()
    private let spacerView = UIView()
    var navigationController: UINavigationController?

    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, toggle: BlockerToggle) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDynamicFont(forLabels: [newLabel], addObserver: true)

        newLabel.numberOfLines = 0
        newLabel.text = toggle.label

        textLabel?.numberOfLines = 0
        textLabel?.text = toggle.label

        newLabel.textColor = .primaryText
        textLabel?.textColor = .primaryText
        layoutMargins = UIEdgeInsets.zero

        accessoryView = PaddedSwitch(switchView: toggle.toggle)
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum Section: String {
        case general, privacy, usageData, search, siri, integration, mozilla

        var numberOfRows: Int {
            switch self {
            case .general: return 1
            case .privacy:
                if BiometryType(context: LAContext()).hasBiometry { return 3 }
                return 2
            case .usageData: return 1
            case .search: return 3
            case .siri: return 3
            case .integration: return 1
            case .mozilla:
                // Show tips option should not be displayed for users that do not see tips
                return TipManager.shared.canShowTips ? 3 : 2
            }
        }

        var headerText: String? {
            switch self {
            case .general: return UIConstants.strings.general
            case .privacy: return UIConstants.strings.toggleSectionPrivacy
            case .usageData: return nil
            case .search: return UIConstants.strings.settingsSearchTitle
            case .siri: return UIConstants.strings.siriShortcutsTitle
            case .integration: return UIConstants.strings.toggleSectionSafari
            case .mozilla: return UIConstants.strings.toggleSectionMozilla
            }
        }

        static func getSections() -> [Section] {
            return [.general, .privacy, .usageData, .search, .siri, integration, .mozilla]
        }
    }

    enum BiometryType {
        enum Status {
            case hasIdentities
            case hasNoIdentities

            init(_ hasIdentities: Bool) {
                self = hasIdentities ? .hasIdentities : .hasNoIdentities
            }
        }

        case faceID(Status), touchID(Status), none

        private static let NO_IDENTITY_ERROR = -7

        var hasBiometry: Bool {
            switch self {
            case .touchID, .faceID: return true
            case .none: return false
            }
        }

        var hasIdentities: Bool {
            switch self {
            case .touchID(Status.hasIdentities), .faceID(Status.hasIdentities): return true
            default: return false
            }
        }

        init(context: LAContext) {
            var biometricError: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricError) else { self = .none; return }
            let status = Status(biometricError.map({ $0.code != BiometryType.NO_IDENTITY_ERROR }) ?? true)

            switch context.biometryType {
            case .faceID: self = .faceID(status)
            case .touchID: self = .touchID(status)
            case .none: self = .none
            @unknown default: self = .none
            }
        }
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.allowsSelection = true
        tableView.estimatedRowHeight = UITableView.automaticDimension
        return tableView
    }()

    // Hold a strong reference to the block detector so it isn't deallocated
    // in the middle of its detection.
    private let detector = BlockerEnabledDetector()
    private let biometryType = BiometryType(context: LAContext())
    private var isSafariEnabled = false
    private let searchEngineManager: SearchEngineManager
    private var highlightsButton = UIBarButtonItem()
    private let whatsNew: WhatsNewDelegate
    private lazy var sections = {
        Section.getSections()
    }()

    private var toggles = [Int: [Int: BlockerToggle]]()
    
    private var labelTextForCurrentTheme: String {
        var themeName = ""
        switch UserDefaults.standard.theme.userInterfaceStyle {
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

    private func getSectionIndex(_ section: Section) -> Int? {
        return Section.getSections().firstIndex(where: { $0 == section })
    }

    private func initializeToggles() {
        let blockFontsToggle = BlockerToggle(label: UIConstants.strings.labelBlockFonts, setting: SettingsToggle.blockFonts)
        let usageDataSubtitle = String(format: UIConstants.strings.detailTextSendUsageData, AppInfo.productName)
        let usageDataToggle = BlockerToggle(label: UIConstants.strings.labelSendAnonymousUsageData, setting: SettingsToggle.sendAnonymousUsageData, subtitle: usageDataSubtitle)
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

    /// Used to calculate cell heights.
    private lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = PaddedSwitch(switchView: UISwitch())
        return cell
    }()

    private var shouldScrollToSiri: Bool
    init(searchEngineManager: SearchEngineManager, whatsNew: WhatsNewDelegate, shouldScrollToSiri: Bool = false) {
        self.searchEngineManager = searchEngineManager
        self.whatsNew = whatsNew
        self.shouldScrollToSiri = shouldScrollToSiri
        super.init(nibName: nil, bundle: nil)

        tableView.register(SettingsTableViewAccessoryCell.self, forCellReuseIdentifier: "accessoryCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {

        title = UIConstants.strings.settingsTitle

        let navigationBar = navigationController!.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationBar.shadowImage = UIImage()
        navigationBar.layoutIfNeeded()
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.primaryText]

        highlightsButton = UIBarButtonItem(title: UIConstants.strings.whatsNewTitle, style: .plain, target: self, action: #selector(whatsNewClicked))
        highlightsButton.image = UIImage(named: "highlight")
        highlightsButton.tintColor = .accent
        highlightsButton.accessibilityIdentifier = "SettingsViewController.whatsNewButton"
        
        let doneButton = UIBarButtonItem(title: UIConstants.strings.done, style: .plain, target: self, action: #selector(dismissSettings))
        doneButton.tintColor = .accent
        doneButton.accessibilityIdentifier = "SettingsViewController.doneButton"

        navigationItem.rightBarButtonItems = [doneButton, highlightsButton]

        if whatsNew.shouldShowWhatsNew() {
            highlightsButton.tintColor = .accent
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        initializeToggles()
        for (sectionIndex, toggleArray) in toggles {
            for (cellIndex, blockerToggle) in toggleArray {
                let toggle = blockerToggle.toggle
                toggle.onTintColor = .accent
                toggle.tintColor = .darkGray
                toggle.addTarget(self, action: #selector(toggleSwitched(_:)), for: .valueChanged)
                toggle.isOn = Settings.getToggle(blockerToggle.setting)
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
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    @objc private func applicationDidBecomeActive() {
        // On iOS 9, we detect the blocker status by loading an invisible SafariViewController
        // in the current view. We can only run the detector if the view is visible; otherwise,
        // the detection callback won't fire and the detector won't be cleaned up.
        if isViewLoaded && view.window != nil {
            updateSafariEnabledState()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func createBiometricLoginToggleIfAvailable() -> BlockerToggle? {
        guard biometryType.hasBiometry else { return nil }

        let label: String
        let subtitle: String

        switch biometryType {
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
        toggle.toggle.isEnabled = biometryType.hasIdentities
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
        case .general:
            let themeCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "themeCell")
            themeCell.labelText = String(format: UIConstants.strings.theme)
            themeCell.accessibilityIdentifier = "settingsViewController.themeCell"
            themeCell.accessoryLabelText = labelTextForCurrentTheme
            cell = themeCell
        case .privacy:
            if indexPath.row == 0 {
                let trackingCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "trackingCell")
                trackingCell.labelText = String(format: UIConstants.strings.trackingProtectionLabel)
                trackingCell.accessibilityIdentifier = "settingsViewController.trackingCell"
                trackingCell.accessoryLabelText = Settings.getToggle(.trackingProtection) ?
                    UIConstants.strings.settingsTrackingProtectionOn :
                    UIConstants.strings.settingsTrackingProtectionOff
                cell = trackingCell
                
            } else {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            }
        case .usageData:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        case .search:
            if indexPath.row < 2 {
                let searchCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "accessoryCell")
                let autocompleteLabel = Settings.getToggle(.enableDomainAutocomplete) || Settings.getToggle(.enableCustomDomainAutocomplete) ? UIConstants.strings.autocompleteCustomEnabled : UIConstants.strings.autocompleteCustomDisabled
                let labels : (label: String, accessoryLabel: String, identifier: String) = indexPath.row == 0 ?
                    (UIConstants.strings.settingsSearchLabel, searchEngineManager.activeEngine.name, "SettingsViewController.searchCell")
                    :(UIConstants.strings.settingsAutocompleteSection, autocompleteLabel, "SettingsViewController.autocompleteCell")
                searchCell.accessoryLabelText = labels.accessoryLabel
                searchCell.labelText = labels.label
                searchCell.accessibilityIdentifier = labels.identifier
                cell = searchCell
            } else {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            }
        case .siri:
            let siriCell = SettingsTableViewAccessoryCell(style: .value1, reuseIdentifier: "accessoryCell")
            if indexPath.row == 0 {
                siriCell.labelText = UIConstants.strings.eraseSiri
                siriCell.accessibilityIdentifier = "settingsViewController.siriEraseCell"
                SiriShortcuts().hasAddedActivity(type: .erase) { (result: Bool) in
                    siriCell.accessoryLabelText = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                }
            } else if indexPath.row == 1 {
                siriCell.labelText = UIConstants.strings.eraseAndOpenSiri
                siriCell.accessibilityIdentifier = "settingsViewController.siriEraseAndOpenCell"
                SiriShortcuts().hasAddedActivity(type: .eraseAndOpen) { (result: Bool) in
                    siriCell.accessoryLabelText = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                }
            } else {
                siriCell.labelText = UIConstants.strings.openUrlSiri
                siriCell.accessibilityIdentifier = "settingsViewController.siriOpenURLCell"
                SiriShortcuts().hasAddedActivity(type: .openURL) { (result: Bool) in
                    siriCell.accessoryLabelText = result ? UIConstants.strings.Edit : UIConstants.strings.add
                }
            }
            cell = siriCell
        case .mozilla where TipManager.shared.canShowTips:
            if indexPath.row == 0 {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            } else if indexPath.row == 1 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "aboutCell")
                cell.textLabel?.text = String(format: UIConstants.strings.aboutTitle, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.about"
            } else {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "ratingCell")
                cell.textLabel?.text = String(format: UIConstants.strings.ratingSetting, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.rateFocus"
            }
        case .mozilla where !TipManager.shared.canShowTips:
            if indexPath.row == 0 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "aboutCell")
                cell.textLabel?.text = String(format: UIConstants.strings.aboutTitle, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.about"
            } else {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "ratingCell")
                cell.textLabel?.text = String(format: UIConstants.strings.ratingSetting, AppInfo.productName)
                cell.accessibilityIdentifier = "settingsViewController.rateFocus"
            }
        default:
            cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
        }

        cell.textLabel?.textColor = .primaryText
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = .secondaryText
        
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfRows
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    private func heightForLabel(_ label: UILabel, width: CGFloat, text: String) -> CGFloat {
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs: [NSAttributedString.Key: Any] = [.font: label.font as Any]
        let boundingRect = NSString(string: text).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].headerText
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let text = toggles[section]?.first?.value.subtitle {
            let footer = ActionFooterView(frame: .zero)
            footer.textLabel.text = text

            if section == 1 || section == 2 {
                let selector = toggles[section]?.first?.value.label == UIConstants.strings.labelSendAnonymousUsageData ? #selector(tappedLearnMoreFooter) : #selector(tappedLearnMoreSearchSuggestionsFooter)
                let tapGesture = UITapGestureRecognizer(target: self, action: selector)
                footer.detailTextButton.setTitle(UIConstants.strings.learnMore, for: .normal)
                footer.detailTextButton.addGestureRecognizer(tapGesture)
            }
            return footer
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section] == .privacy ? 50 : 30
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .general:
            let themeVC = ThemeViewController()
            navigationController?.pushViewController(themeVC, animated: true)
        case .privacy:
            if indexPath.row == 0 {
                let trackingProtectionVC = TrackingProtectionViewController(state: .settings)
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
            guard #available(iOS 12.0, *) else { return }
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
        case .mozilla where TipManager.shared.canShowTips:
            if indexPath.row == 1 {
                aboutClicked()
            } else if indexPath.row == 2 {
                let appId = AppInfo.config.appId
                if let reviewURL = URL(string: "https://itunes.apple.com/app/id\(appId)?action=write-review"), UIApplication.shared.canOpenURL(reviewURL) {
                    UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
                }
            }
        case .mozilla where !TipManager.shared.canShowTips:
            if indexPath.row == 0 {
                aboutClicked()
            } else if indexPath.row == 1 {
                let appId = AppInfo.config.appId
                if let reviewURL = URL(string: "https://itunes.apple.com/app/id\(appId)?action=write-review"), UIApplication.shared.canOpenURL(reviewURL) {
                    UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
                }
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
    
    @objc func tappedLearnMoreFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(forSupportTopic: .usageData)
    }

    @objc func tappedLearnMoreSearchSuggestionsFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(forSupportTopic: .searchSuggestions)
    }

    @objc private func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func aboutClicked() {
        navigationController!.pushViewController(AboutViewController(), animated: true)
    }

    @objc private func whatsNewClicked() {
        highlightsButton.tintColor = UIColor.white
        navigationController?.pushViewController(SettingsContentViewController(url: URL(forSupportTopic: .whatsNew)), animated: true)
        whatsNew.didShowWhatsNew()
    }

    @objc private func toggleSwitched(_ sender: UISwitch) {
        let toggle = toggles.values.filter { $0.values.filter { $0.toggle == sender } != []}[0].values.filter { $0.toggle == sender }[0]

        func updateSetting() {
            let telemetryEvent = TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: "setting", value: toggle.setting.rawValue)
            telemetryEvent.addExtra(key: "to", value: sender.isOn)
            Telemetry.default.recordEvent(telemetryEvent)

            Settings.set(sender.isOn, forToggle: toggle.setting)
            ContentBlockerHelper.shared.reload()
            Utils.reloadSafariContentBlocker()
        }

        // First check if the user changed the anonymous usage data setting and follow that choice right
        // here. Otherwise it will be delayed until the application restarts.
        if toggle.setting == .sendAnonymousUsageData {
            Telemetry.default.configuration.isCollectionEnabled = sender.isOn
            Telemetry.default.configuration.isUploadEnabled = sender.isOn
            Glean.shared.setUploadEnabled(sender.isOn)
        } else if toggle.setting == .biometricLogin {
            TipManager.biometricTip = false
        }

        switch toggle.setting {
        case .safari where sender.isOn && !isSafariEnabled:
            let instructionsViewController = SafariInstructionsViewController()
            navigationController!.pushViewController(instructionsViewController, animated: true)
            updateSetting()
        case .enableSearchSuggestions:
            UserDefaults.standard.set(true, forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt)
            updateSetting()
        case .showHomeScreenTips:
            updateSetting()
            // This update must occur after the setting has been updated to properly take effect.
            if let browserViewController = presentingViewController as? BrowserViewController {
                browserViewController.refreshTipsDisplay()
            }
        default:
            updateSetting()
        }
    }
}

extension SettingsViewController: SearchSettingsViewControllerDelegate {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didSelectEngine engine: SearchEngine) {
        (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SettingsTableViewAccessoryCell)?.accessoryLabelText = engine.name
    }
}

extension SettingsViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 12.0, *)
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
