/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import Telemetry
import LocalAuthentication
import Intents
import IntentsUI

class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = UIConstants.colors.cellSelected
        selectedBackgroundView = backgroundColorView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingsTableViewAccessoryCell: SettingsTableViewCell {
    private let newLabel = SmartLabel()
    let accessoryLabel = SmartLabel()
    private let spacerView = UIView()

    var accessoryLabelText: String? {
        get { return accessoryLabel.text }
        set {
            accessoryLabel.text = newValue
            accessoryLabel.sizeToFit()
        }
    }

    var labelText: String? {
        get { return newLabel.text }
        set {
            newLabel.text = newValue
            newLabel.sizeToFit()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        newLabel.numberOfLines = 0
        newLabel.lineBreakMode = .byWordWrapping
        textLabel?.numberOfLines = 0
        textLabel?.text = " "

        contentView.addSubview(accessoryLabel)
        contentView.addSubview(newLabel)
        contentView.addSubview(spacerView)

        newLabel.textColor = UIConstants.colors.settingsTextLabel
        accessoryLabel.textColor = UIConstants.colors.settingsDetailLabel
        accessoryType = .disclosureIndicator

        accessoryLabel.setContentHuggingPriority(.required, for: .horizontal)
        accessoryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessoryLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }

        newLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        newLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        spacerView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalTo(textLabel!.snp.leading)
        }

        newLabel.snp.makeConstraints { make in
            make.leading.equalTo(spacerView.snp.trailing)
            make.top.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-11)
            make.trailing.equalTo(accessoryLabel.snp.leading).offset(-10)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum Section: String {
        case privacy, search, siri, integration, mozilla
        
        var numberOfRows: Int {
            switch self {
            case .privacy:
                if BiometryType(context: LAContext()).hasBiometry { return 4 }
                return 3
            case .search: return 2
            case .siri: return 3
            case .integration: return 1
            case .mozilla: return 2
            }
        }
        
        var headerText: String? {
            switch self {
            case .privacy: return UIConstants.strings.toggleSectionPrivacy
            case .search: return UIConstants.strings.settingsSearchTitle
            case .siri: return UIConstants.strings.siriShortcutsTitle
            case .integration: return UIConstants.strings.toggleSectionSafari
            case .mozilla: return UIConstants.strings.toggleSectionMozilla
            }
        }

        static func getSections() -> [Section] {
            if #available(iOS 12.0, *) {
                return [.privacy, .search, .siri, integration, .mozilla]
            }
            else {
                return [.privacy, .search, integration, .mozilla]
            }
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
            }
        }
    }
    
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)

    // Hold a strong reference to the block detector so it isn't deallocated
    // in the middle of its detection.
    private let detector = BlockerEnabledDetector.makeInstance()
    private let biometryType = BiometryType(context: LAContext())
    private var isSafariEnabled = false
    private let searchEngineManager: SearchEngineManager
    private var highlightsButton: UIBarButtonItem?
    private let whatsNew: WhatsNewDelegate
    private lazy var sections = {
        Section.getSections()
    }()

    private var toggles = [Int : BlockerToggle]()

    private var initialToggles : [Int : BlockerToggle]  {
        let blockFontsToggle = BlockerToggle(label: UIConstants.strings.labelBlockFonts, setting: SettingsToggle.blockFonts)
        let usageDataSubtitle = String(format: UIConstants.strings.detailTextSendUsageData, AppInfo.productName)
        let usageDataToggle = BlockerToggle(label: UIConstants.strings.labelSendAnonymousUsageData, setting: SettingsToggle.sendAnonymousUsageData, subtitle: usageDataSubtitle)
        let safariToggle = BlockerToggle(label: UIConstants.strings.toggleSafari, setting: SettingsToggle.safari)
        var toggles = [Int : BlockerToggle]()
        if let biometricToggle = createBiometricLoginToggleIfAvailable() {
            toggles = [
                1: blockFontsToggle,
                2: biometricToggle,
                3: usageDataToggle,
                6: safariToggle
            ]
        }
        else {
            toggles = [
                1: blockFontsToggle,
                2: usageDataToggle,
                5: safariToggle
            ]
        }
        if #available(iOS 12.0, *) {
            if let safariRow = toggles.first(where: { $1 == safariToggle })?.key {
                toggles.removeValue(forKey: safariRow)
                toggles[(safariRow +  Section.siri.numberOfRows)] = safariToggle
            }
        }
        return toggles
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
        view.backgroundColor = UIConstants.colors.background

        title = UIConstants.strings.settingsTitle

        let navigationBar = navigationController!.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = UIConstants.colors.settingsNavBar
        navigationBar.tintColor = UIConstants.colors.navigationButton
        navigationBar.titleTextAttributes = [.foregroundColor: UIConstants.colors.navigationTitle]
        
        let navBarBorderRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.25)
        UIGraphicsBeginImageContextWithOptions(navBarBorderRect.size, false, 0.0)
        UIConstants.colors.settingsNavBorder.setFill()
        UIRectFill(navBarBorderRect)
        if let borderImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            navigationController?.navigationBar.shadowImage = borderImage
        }
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
        doneButton.tintColor = UIConstants.Photon.Magenta60
        navigationItem.leftBarButtonItem = doneButton

        highlightsButton = UIBarButtonItem(title: UIConstants.strings.whatsNewTitle, style: .plain, target: self, action: #selector(whatsNewClicked))
        highlightsButton?.image = UIImage(named: "highlight")
        highlightsButton?.accessibilityIdentifier = "SettingsViewController.whatsNewButton"
        navigationItem.rightBarButtonItem = highlightsButton
        
        if whatsNew.shouldShowWhatsNew() {
            highlightsButton?.tintColor = UIConstants.colors.whatsNew
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.colors.background
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIConstants.colors.settingsSeparator
        tableView.allowsSelection = true
        tableView.estimatedRowHeight = 44

        toggles = initialToggles
        for (i, blockerToggle) in toggles {
            let toggle = blockerToggle.toggle
            toggle.onTintColor = UIConstants.colors.toggleOn
            toggle.addTarget(self, action: #selector(toggleSwitched(_:)), for: .valueChanged)
            toggle.isOn = Settings.getToggle(blockerToggle.setting)
            toggles[i] = blockerToggle
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSafariEnabledState()
        tableView.reloadData()
        if shouldScrollToSiri {
            guard let siriSection = sections.index(where: {$0 == Section.siri}) else {
                shouldScrollToSiri = false
                return
            }
            let siriIndexPath = IndexPath(row: 0, section: siriSection)
            tableView.scrollToRow(at: siriIndexPath, at: .none , animated: false)
            shouldScrollToSiri = false
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
    
    fileprivate func createBiometricLoginToggleIfAvailable() -> BlockerToggle? {
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

    fileprivate func toggleForIndexPath(_ indexPath: IndexPath) -> BlockerToggle {
        var index = (indexPath as NSIndexPath).row
        for i in 0..<(indexPath as NSIndexPath).section {
            index += tableView.numberOfRows(inSection: i)
        }
        guard let toggle = toggles[index] else { return BlockerToggle(label: "Error", setting: SettingsToggle.blockAds) }
        return toggle
    }

    @objc func tappedLearnMoreFooter(gestureRecognizer: UIGestureRecognizer) {
        guard let url = SupportUtils.URLForTopic(topic: "usage-data") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        switch sections[indexPath.section] {
        case .search:
            guard let searchCell = tableView.dequeueReusableCell(withIdentifier: "accessoryCell") as? SettingsTableViewAccessoryCell else { fatalError("Accessory cells do not exist") }

            let label = indexPath.row == 0 ? UIConstants.strings.settingsSearchLabel : UIConstants.strings.settingsAutocompleteSection
            let autocompleteLabel = Settings.getToggle(.enableDomainAutocomplete) || Settings.getToggle(.enableCustomDomainAutocomplete) ? UIConstants.strings.autocompleteCustomEnabled : UIConstants.strings.autocompleteCustomDisabled
            let accessoryLabel = indexPath.row == 0 ? searchEngineManager.activeEngine.name : autocompleteLabel
            let identifier = indexPath.row == 0 ? "SettingsViewController.searchCell" : "SettingsViewController.autocompleteCell"

            searchCell.accessoryLabelText = accessoryLabel
            searchCell.labelText = label
            searchCell.accessibilityIdentifier = identifier

            cell = searchCell
        case .siri:
            guard #available(iOS 12.0, *), let siriCell = tableView.dequeueReusableCell(withIdentifier: "accessoryCell") as? SettingsTableViewAccessoryCell else { fatalError("No accessory cells") }
            if indexPath.row == 0 {
                siriCell.labelText = UIConstants.strings.eraseSiri
                siriCell.accessibilityIdentifier = "settingsViewController.siriEraseCell"
                SiriShortcuts().hasAddedActivity(type: .erase) { (result: Bool) in
                    siriCell.accessoryLabel.text = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                }
            } else if indexPath.row == 1 {
                    siriCell.labelText = UIConstants.strings.eraseAndOpenSiri
                    siriCell.accessibilityIdentifier = "settingsViewController.siriEraseAndOpenCell"
                    SiriShortcuts().hasAddedActivity(type: .eraseAndOpen) { (result: Bool) in
                        siriCell.accessoryLabel.text = result ? UIConstants.strings.Edit : UIConstants.strings.addToSiri
                    }
            } else {
                siriCell.labelText = UIConstants.strings.openUrlSiri
                siriCell.accessibilityIdentifier = "settingsViewController.siriOpenURLCell"
                SiriShortcuts().hasAddedActivity(type: .openURL) { (result: Bool) in
                    siriCell.accessoryLabel.text = result ? UIConstants.strings.Edit : UIConstants.strings.add
                }
            }
            cell = siriCell
        case .mozilla:
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
            if sections[indexPath.section] == .privacy && indexPath.row == 0 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "trackingCell")
                cell.textLabel?.text = String(format: UIConstants.strings.trackingProtectionLabel)
                cell.accessibilityIdentifier = "settingsViewController.trackingCell"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "toggleCell")
                let toggle = toggleForIndexPath(indexPath)
                cell.textLabel?.text = toggle.label
                cell.textLabel?.numberOfLines = 0
                cell.accessoryView = PaddedSwitch(switchView: toggle.toggle)
                cell.detailTextLabel?.text = toggle.subtitle
                cell.detailTextLabel?.numberOfLines = 0
                cell.selectionStyle = .none
                if toggle.label == UIConstants.strings.labelSendAnonymousUsageData {
                    let selector = #selector(tappedLearnMoreFooter)
                    let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [.foregroundColor : UIConstants.colors.settingsLink])
                    let space = NSAttributedString(string: " ", attributes: [:])
                    guard let subtitle = toggle.subtitle else { return cell }
                    let attributedSubtitle = NSMutableAttributedString(string: subtitle)
                    attributedSubtitle.append(space)
                    attributedSubtitle.append(learnMore)
                    cell.detailTextLabel?.attributedText = attributedSubtitle
                    let tapGesture = UITapGestureRecognizer(target: self, action: selector)
                    cell.addGestureRecognizer(tapGesture)
                }
            }
        }

        cell.backgroundColor = UIConstants.colors.cellBackground
        cell.textLabel?.textColor = UIConstants.colors.settingsTextLabel
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = UIConstants.colors.settingsDetailLabel

        cell.textLabel?.setupShrinkage()
        cell.detailTextLabel?.setupShrinkage()

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].numberOfRows
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Height for the Search Engine and Learn More row.
        if indexPath.section == 0 { return UITableView.automaticDimension }
        if indexPath.section == 5 ||
            (indexPath.section == 4 && indexPath.row >= 1) {
            return 44
        }

        // We have to manually calculate the cell height since UITableViewCell doesn't correctly
        // layout multiline detailTextLabels.
        let toggle = toggleForIndexPath(indexPath)
        let tableWidth = tableView.frame.width
        let accessoryWidth = dummyToggleCell.accessoryView!.frame.width
        let insetsWidth = 2 * tableView.separatorInset.left
        let width = tableWidth - accessoryWidth - insetsWidth

        var height = heightForLabel(dummyToggleCell.textLabel!, width: width, text: toggle.label)
        if let subtitle = toggle.subtitle {
            height += heightForLabel(dummyToggleCell.detailTextLabel!, width: width, text: subtitle)
        }

        return height + 22
    }

    private func heightForLabel(_ label: UILabel, width: CGFloat, text: String) -> CGFloat {
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs: [NSAttributedString.Key: Any] = [.font: label.font]
        let boundingRect = NSString(string: text).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var groupingOffset = UIConstants.layout.settingsDefaultTitleOffset
        
        if sections[section] == .privacy {
            groupingOffset = UIConstants.layout.settingsFirstTitleOffset
        }

        // Hack: We want the header view's margin to match the cells, so we create an empty
        // cell with a blank space as text to layout the text label. From there, we can define
        // constraints for our custom label based on the cell's label.
        let cell = UITableViewCell()
        cell.textLabel?.text = " "
        cell.backgroundColor = UIConstants.colors.background

        let label = SmartLabel()
        label.text = sections[section].headerText
        label.textColor = UIConstants.colors.tableSectionHeader
        label.font = UIConstants.fonts.tableSectionHeader
        cell.contentView.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(cell.textLabel!)
            make.centerY.equalTo(cell.textLabel!).offset(groupingOffset)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section] == .privacy ? 50 : 30
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section] {
        case .privacy:
            if indexPath.row == 0 {
                let trackingProtectionVC = TrackingProtectionViewController()
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
                UserDefaults.standard.set(false, forKey: TipManager.TipKey.siriEraseTip)
            }
            else if indexPath.row == 1 {
                SiriShortcuts().manageSiri(for: SiriShortcuts.activityType.eraseAndOpen, in: self)
                UserDefaults.standard.set(false, forKey: TipManager.TipKey.siriEraseTip)
            }
            else {
                let siriFavoriteVC = SiriFavoriteViewController()
                navigationController?.pushViewController(siriFavoriteVC, animated: true)
            }
        case .mozilla:
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
        guard let safariIndex = toggles.first(where: { $1.setting ==  SettingsToggle.safari})?.key,
            let safariToggle = toggles[safariIndex]?.toggle else { return }
        safariToggle.isEnabled = false

        detector.detectEnabled(view) { [weak self] enabled in
            safariToggle.isOn = enabled && Settings.getToggle(.safari)
            safariToggle.isEnabled = true
            self?.isSafariEnabled = enabled
        }
    }

    @objc private func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func aboutClicked() {
        navigationController!.pushViewController(AboutViewController(), animated: true)
    }
    
    @objc private func whatsNewClicked() {
        highlightsButton?.tintColor = UIColor.white
        
        guard let url = SupportUtils.URLForTopic(topic: "whats-new-focus-ios-7") else { return }
        navigationController?.pushViewController(SettingsContentViewController(url: url), animated: true)
        
        whatsNew.didShowWhatsNew()
    }

    @objc private func toggleSwitched(_ sender: UISwitch) {
        let toggle = toggles.values.filter { $0.toggle == sender }.first!

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
        } else if toggle.setting == .biometricLogin {
            UserDefaults.standard.set(false, forKey: TipManager.TipKey.biometricTip)
        }

        switch toggle.setting {
        case .safari where sender.isOn && !isSafariEnabled:
            let instructionsViewController = SafariInstructionsViewController()
            navigationController!.pushViewController(instructionsViewController, animated: true)
            updateSetting()
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
