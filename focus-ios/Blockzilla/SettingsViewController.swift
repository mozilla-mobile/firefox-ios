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
        setupDynamicFont()

        if #available(iOS 10.0, *) {
            newLabel.adjustsFontForContentSizeCategory = true
            accessoryLabel.adjustsFontForContentSizeCategory = true
        } else {
            NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { _ in
                self.setupDynamicFont()
            }
        }

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
            make.width.equalTo(UIConstants.layout.settingsFirstTitleOffset)
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

    private func setupDynamicFont() {
        newLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        accessoryLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    }
}

class SettingsTableViewToggleCell: SettingsTableViewCell {
    private let newLabel = SmartLabel()
    private let newDetailLabel = SmartLabel()
    private let spacerView = UIView()
    var navigationController: UINavigationController?
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, toggle: BlockerToggle) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        newLabel.numberOfLines = 0
        newLabel.text = toggle.label
        textLabel?.numberOfLines = 0
        textLabel?.text = toggle.label
        
        newDetailLabel.numberOfLines = 0
        newDetailLabel.text = toggle.subtitle
        detailTextLabel?.numberOfLines = 0
        detailTextLabel?.text = nil
        
        backgroundColor = UIConstants.colors.cellBackground
        newLabel.textColor = UIConstants.colors.settingsTextLabel
        textLabel?.textColor = UIConstants.colors.settingsTextLabel
        layoutMargins = UIEdgeInsets.zero
        newDetailLabel.textColor = UIConstants.colors.settingsDetailLabel
        detailTextLabel?.textColor = UIConstants.colors.settingsDetailLabel
        
        accessoryView = PaddedSwitch(switchView: toggle.toggle)
        selectionStyle = .none
        
        // Add "Learn More" button recognition
        if toggle.label == UIConstants.strings.labelSendAnonymousUsageData || toggle.label == UIConstants.strings.settingsSearchSuggestions {
            
            addSubview(newLabel)
            addSubview(newDetailLabel)
            addSubview(spacerView)
            
            textLabel?.isHidden = true
            
            let selector = toggle.label == UIConstants.strings.labelSendAnonymousUsageData ? #selector(tappedLearnMoreFooter) : #selector(tappedLearnMoreSearchSuggestionsFooter)
            let learnMoreButton = UIButton()
            learnMoreButton.setTitle(UIConstants.strings.learnMore, for: .normal)
            learnMoreButton.setTitleColor(UIConstants.colors.settingsLink, for: .normal)
            if let cellFont = detailTextLabel?.font {
                learnMoreButton.titleLabel?.font = UIFont(name: cellFont.fontName, size: cellFont.pointSize)
            }
            let tapGesture = UITapGestureRecognizer(target: self, action: selector)
            learnMoreButton.addGestureRecognizer(tapGesture)
            addSubview(learnMoreButton)
            
            // Adjust the offsets to allow the buton to fit
            spacerView.snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.trailing.equalTo(textLabel!.snp.leading)
            }
            
            newLabel.snp.makeConstraints { make in
                make.leading.equalTo(spacerView.snp.trailing)
                make.top.equalToSuperview().offset(8)
            }
            
            learnMoreButton.snp.makeConstraints { make in
                make.leading.equalTo(spacerView.snp.trailing)
                make.bottom.equalToSuperview().offset(4)
            }
            
            newDetailLabel.snp.makeConstraints { make in
                let lineHeight = newLabel.font.lineHeight
                make.top.equalToSuperview().offset(10 + lineHeight)
                make.leading.equalTo(spacerView.snp.trailing)
                make.trailing.equalTo(contentView)
                
                if let learnMoreHeight = learnMoreButton.titleLabel?.font.lineHeight {
                    make.bottom.equalToSuperview().offset(-8 - learnMoreHeight)
                }
            }
            
            newLabel.setupShrinkage()
            newDetailLabel.setupShrinkage()
        }
    }
    
    private func tappedFooter(topic: String) {
        guard let url = SupportUtils.URLForTopic(topic: topic) else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }
    
    @objc func tappedLearnMoreFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(topic: UIConstants.strings.sumoTopicUsageData)
    }
    
    @objc func tappedLearnMoreSearchSuggestionsFooter(gestureRecognizer: UIGestureRecognizer) {
        tappedFooter(topic: UIConstants.strings.sumoTopicSearchSuggestion)
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
            case .search: return 3
            case .siri: return 3
            case .integration: return 1
            case .mozilla:
                // Show tips option should not be displayed for users that do not see tips
                return TipManager.shared.shouldShowTips() ? 3 : 2
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
            } else {
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

    private var toggles = [Int: [Int: BlockerToggle]]()

    private func getSectionIndex(_ section: Section) -> Int? {
        return Section.getSections().index(where: { $0 == section })
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
                toggles[privacyIndex] =  [1: blockFontsToggle, 2: biometricToggle, 3: usageDataToggle]
            } else {
                toggles[privacyIndex] = [1: blockFontsToggle, 2: usageDataToggle]
            }
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
        doneButton.accessibilityIdentifier = "SettingsViewController.doneButton"
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

        initializeToggles()
        for (sectionIndex, toggleArray) in toggles {
            for (cellIndex, blockerToggle) in toggleArray {
                let toggle = blockerToggle.toggle
                toggle.onTintColor = UIConstants.colors.toggleOn
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
        case .privacy:
            if indexPath.row == 0 {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "trackingCell")
                cell.textLabel?.text = String(format: UIConstants.strings.trackingProtectionLabel)
                cell.accessibilityIdentifier = "settingsViewController.trackingCell"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell = setupToggleCell(indexPath: indexPath, navigationController: navigationController)
            }
        case .search:
            if indexPath.row < 2 {
                guard let searchCell = tableView.dequeueReusableCell(withIdentifier: "accessoryCell") as? SettingsTableViewAccessoryCell else { fatalError("Accessory cells do not exist") }
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
        case .mozilla where TipManager.shared.shouldShowTips():
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
        case .mozilla where !TipManager.shared.shouldShowTips():
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
            if toggle.label == UIConstants.strings.labelSendAnonymousUsageData ||
                toggle.label == UIConstants.strings.settingsSearchSuggestions {
                height += 10
            }
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
            } else if indexPath.row == 1 {
                SiriShortcuts().manageSiri(for: SiriShortcuts.activityType.eraseAndOpen, in: self)
                UserDefaults.standard.set(false, forKey: TipManager.TipKey.siriEraseTip)
            } else {
                let siriFavoriteVC = SiriFavoriteViewController()
                navigationController?.pushViewController(siriFavoriteVC, animated: true)
            }
        case .mozilla where TipManager.shared.shouldShowTips():
            if indexPath.row == 1 {
                aboutClicked()
            } else if indexPath.row == 2 {
                let appId = AppInfo.config.appId
                if let reviewURL = URL(string: "https://itunes.apple.com/app/id\(appId)?action=write-review"), UIApplication.shared.canOpenURL(reviewURL) {
                    UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
                }
            }
        case .mozilla where !TipManager.shared.shouldShowTips():
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

    @objc private func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func aboutClicked() {
        navigationController!.pushViewController(AboutViewController(), animated: true)
    }

    @objc private func whatsNewClicked() {
        highlightsButton?.tintColor = UIColor.white
        guard let focusURL = SupportUtils.URLForTopic(topic: UIConstants.strings.sumoTopicWhatsNew) else { return }
        guard let klarURL = SupportUtils.URLForTopic(topic: UIConstants.strings.klarSumoTopicWhatsNew) else { return }

        if AppInfo.isKlar {
            navigationController?.pushViewController(SettingsContentViewController(url: klarURL), animated: true)
        } else {
            navigationController?.pushViewController(SettingsContentViewController(url: focusURL), animated: true)
        }

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
        } else if toggle.setting == .biometricLogin {
            UserDefaults.standard.set(false, forKey: TipManager.TipKey.biometricTip)
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
