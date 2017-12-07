/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import Telemetry

class SettingsTableViewSearchCell: UITableViewCell {
    private let newLabel = UILabel()
    private let accessoryLabel = UILabel()
    private let spacerView = UIView()

    var accessoryLabelText: String? {
        get { return accessoryLabel.text }
        set {
            accessoryLabel.text = newValue
            accessoryLabel.sizeToFit()
        }
    }

    var label: String? {
        get { return newLabel.text }
        set {
            newLabel.text = newValue
            newLabel.sizeToFit()
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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

        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = UIConstants.colors.cellSelected
        selectedBackgroundView = backgroundColorView

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
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)

    // Hold a strong reference to the block detector so it isn't deallocated
    // in the middle of its detection.
    private let detector = BlockerEnabledDetector.makeInstance()

    private var isSafariEnabled = false
    private let searchEngineManager: SearchEngineManager
    private var highlightsButton: UIBarButtonItem?
    private let whatsNew: WhatsNewDelegate
    
    private let toggles = [
        BlockerToggle(label: UIConstants.strings.toggleSafari, setting: SettingsToggle.safari),
        BlockerToggle(label: UIConstants.strings.labelBlockAds, setting: SettingsToggle.blockAds, subtitle: UIConstants.strings.labelBlockAdsDescription),
        BlockerToggle(label: UIConstants.strings.labelBlockAnalytics, setting: SettingsToggle.blockAnalytics, subtitle: UIConstants.strings.labelBlockAnalyticsDescription),
        BlockerToggle(label: UIConstants.strings.labelBlockSocial, setting: SettingsToggle.blockSocial, subtitle: UIConstants.strings.labelBlockSocialDescription),
        BlockerToggle(label: UIConstants.strings.labelBlockOther, setting: SettingsToggle.blockOther, subtitle: UIConstants.strings.labelBlockOtherDescription),
        BlockerToggle(label: UIConstants.strings.labelBlockFonts, setting: SettingsToggle.blockFonts),
        BlockerToggle(label: UIConstants.strings.labelSendAnonymousUsageData, setting: SettingsToggle.sendAnonymousUsageData),
    ]

    /// Used to calculate cell heights.
    private lazy var dummyToggleCell: UITableViewCell = {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "dummyCell")
        cell.accessoryView = PaddedSwitch(switchView: UISwitch())
        return cell
    }()

    init(searchEngineManager: SearchEngineManager, whatsNew: WhatsNewDelegate) {
        self.searchEngineManager = searchEngineManager
        self.whatsNew = whatsNew
        super.init(nibName: nil, bundle: nil)

        tableView.register(SettingsTableViewSearchCell.self, forCellReuseIdentifier: "searchCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.colors.background

        title = UIConstants.strings.settingsTitle

        let navigationBar = navigationController!.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = UIConstants.colors.background
        navigationBar.tintColor = UIConstants.colors.navigationButton
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIConstants.colors.navigationTitle]

        highlightsButton = UIBarButtonItem(title: UIConstants.strings.whatsNewTitle, style: .plain, target: self, action: #selector(whatsNewClicked))
        highlightsButton?.image = UIImage(named: "highlight")
        highlightsButton?.accessibilityIdentifier = "SettingsViewController.whatsNewButton"
        navigationItem.rightBarButtonItem = highlightsButton
        
        if whatsNew.shouldShowWhatsNew() {
            highlightsButton?.tintColor = UIConstants.colors.settingsLink
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

        toggles.forEach { blockerToggle in
            let toggle = blockerToggle.toggle
            toggle.onTintColor = UIConstants.colors.toggleOn
            toggle.tintColor = UIConstants.colors.toggleOff
            toggle.addTarget(self, action: #selector(toggleSwitched(_:)), for: .valueChanged)
            toggle.isOn = Settings.getToggle(blockerToggle.setting)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSafariEnabledState()
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

    fileprivate func toggleForIndexPath(_ indexPath: IndexPath) -> BlockerToggle {
        var index = (indexPath as NSIndexPath).row
        for i in 1..<(indexPath as NSIndexPath).section {
            index += tableView.numberOfRows(inSection: i)
        }
        
        return toggles[index]
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 2:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.toggleOn])
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.trackersDescriptionLabel, AppInfo.productName), attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.settingsDetailLabel])
            let space = NSAttributedString(string: " ", attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.toggleOn])
            subtitle.append(space)
            subtitle.append(learnMore)
            cell.detailTextLabel?.attributedText = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessibilityIdentifier = "SettingsViewController.trackingProtectionLearnMoreCell"
            cell.selectionStyle = .none
            cell.backgroundColor = UIConstants.colors.background
            cell.layoutMargins = UIEdgeInsets.zero

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedTrackingProtectionLearnMoreFooter))
            cell.addGestureRecognizer(tapGesture)

            return cell
        case 4:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.toggleOn])
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.detailTextSendUsageData, AppInfo.productName), attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.settingsDetailLabel])
            let space = NSAttributedString(string: " ", attributes: [NSAttributedStringKey.foregroundColor : UIConstants.colors.toggleOn])
            subtitle.append(space)
            subtitle.append(learnMore)
            cell.detailTextLabel?.attributedText = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessibilityIdentifier = "SettingsViewController.learnMoreCell"
            cell.selectionStyle = .none
            cell.backgroundColor = UIConstants.colors.background
            cell.layoutMargins = UIEdgeInsets.zero

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedLearnMoreFooter))
            cell.addGestureRecognizer(tapGesture)

            return cell
        default: return nil
        }
    }

    @objc func tappedTrackingProtectionLearnMoreFooter(sender: UIGestureRecognizer) {
        guard let url = SupportUtils.URLForTopic(topic: "tracking-protection-focus-ios") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    @objc func tappedLearnMoreFooter(gestureRecognizer: UIGestureRecognizer) {
        guard let url = SupportUtils.URLForTopic(topic: "usage-data") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 4 || section == 2 ? 50 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        switch indexPath.section {
        case 0:
            guard let searchCell = tableView.dequeueReusableCell(withIdentifier: "searchCell") as? SettingsTableViewSearchCell else { fatalError("No Search Cells!") }

            let label = indexPath.row == 0 ? UIConstants.strings.settingsSearchLabel : UIConstants.strings.settingsAutocompleteSection
            let autocompleteLabel = Settings.getToggle(.enableDomainAutocomplete) || Settings.getToggle(.enableCustomDomainAutocomplete) ? UIConstants.strings.autocompleteCustomEnabled : UIConstants.strings.autocompleteCustomDisabled
            let accessoryLabel = indexPath.row == 0 ? searchEngineManager.activeEngine.name : autocompleteLabel
            let identifier = indexPath.row == 0 ? "SettingsViewController.searchCell" : "SettingsViewController.autocompleteCell"

            searchCell.accessoryLabelText = accessoryLabel
            searchCell.label = label
            searchCell.accessoryType = .disclosureIndicator
            searchCell.accessibilityIdentifier = identifier

            cell = searchCell
        default:
            if indexPath.section == 4 && indexPath.row == 1 {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "aboutCell")
                cell.textLabel?.text = UIConstants.strings.aboutTitle
                cell.accessibilityIdentifier = "settingsViewController.about"
            } else {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "toggleCell")
                let toggle = toggleForIndexPath(indexPath)
                cell.textLabel?.text = toggle.label
                cell.textLabel?.numberOfLines = 0
                cell.accessoryView = PaddedSwitch(switchView: toggle.toggle)
                cell.detailTextLabel?.text = toggle.subtitle
                cell.detailTextLabel?.numberOfLines = 0
                cell.selectionStyle = .none
            }
        }

        cell.backgroundColor = UIConstants.colors.background
        cell.textLabel?.textColor = UIConstants.colors.settingsTextLabel
        cell.layoutMargins = UIEdgeInsets.zero
        cell.detailTextLabel?.textColor = UIConstants.colors.settingsDetailLabel

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Search.
        case 1: return 1 // Integration.
        case 2: return 4 // Privacy.
        case 3: return 1 // Performance.
        case 4: return 2 // Mozilla.
        default:
            assertionFailure("Invalid section")
            return 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Height for the Search Engine and Learn More row.
        if indexPath.section == 0 { return UITableViewAutomaticDimension }
        if indexPath.section == 5 ||
            (indexPath.section == 4 && indexPath.row == 1) {
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
        let attrs: [NSAttributedStringKey: Any] = [.font: label.font]
        let boundingRect = NSString(string: text).boundingRect(with: size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attrs, context: nil)
        return boundingRect.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelText: String
        var groupingOffset = 16
        switch section {
        case 0:
            labelText = UIConstants.strings.settingsSearchTitle
            groupingOffset = 3
        case 1: labelText = UIConstants.strings.toggleSectionIntegration
        case 2: labelText = UIConstants.strings.toggleSectionPrivacy
        case 3: labelText = UIConstants.strings.toggleSectionPerformance
        case 4: labelText = UIConstants.strings.toggleSectionMozilla
        default: return nil
        }

        // Hack: We want the header view's margin to match the cells, so we create an empty
        // cell with a blank space as text to layout the text label. From there, we can define
        // constraints for our custom label based on the cell's label.
        let cell = UITableViewCell()
        cell.textLabel?.text = " "
        cell.backgroundColor = UIConstants.colors.background

        let label = UILabel()
        label.text = labelText
        label.textColor = UIConstants.colors.tableSectionHeader
        label.font = UIConstants.fonts.tableSectionHeader
        cell.contentView.addSubview(label)

        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(cell.textLabel!)
            make.centerY.equalTo(cell.textLabel!).offset(groupingOffset)
        }

        // Hack to cover header separator line
        let footer = UIView()
        footer.backgroundColor = UIConstants.colors.background

        cell.addSubview(footer)
        cell.sendSubview(toBack: footer)

        footer.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.bottom.equalToSuperview().offset(1)
            make.leading.trailing.equalToSuperview()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != 0 ? 50 : 30
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let searchSettingsViewController = SearchSettingsViewController(searchEngineManager: searchEngineManager)
                searchSettingsViewController.delegate = self
                navigationController?.pushViewController(searchSettingsViewController, animated: true)
            } else if indexPath.row == 1 {
                let autcompleteSettingViewController = AutocompleteSettingViewController()
                navigationController?.pushViewController(autcompleteSettingViewController, animated: true)
            }
        case 4:
            if indexPath.row == 1 {
                aboutClicked()
            }
        default: break
        }
    }

    private func updateSafariEnabledState() {
        let safariToggle = self.toggles.first { $0.setting == .safari }!.toggle

        safariToggle.isEnabled = false

        detector.detectEnabled(view) { [weak self] enabled in
            safariToggle.isOn = enabled && Settings.getToggle(.safari)
            safariToggle.isEnabled = true
            self?.isSafariEnabled = enabled
        }
    }

    @objc private func aboutClicked() {
        navigationController!.pushViewController(AboutViewController(), animated: true)
    }
    
    @objc private func whatsNewClicked() {
        highlightsButton?.tintColor = UIColor.white
        
        guard let url = SupportUtils.URLForTopic(topic: "whats-new-focus-ios-4") else { return }
        navigationController?.pushViewController(SettingsContentViewController(url: url), animated: true)
        
        whatsNew.didShowWhatsNew()
    }

    @objc private func toggleSwitched(_ sender: UISwitch) {
        let toggle = toggles.filter { $0.toggle == sender }.first!

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
        }

        switch toggle.setting {
        case .safari where sender.isOn && !isSafariEnabled:
            let instructionsViewController = SafariInstructionsViewController()
            navigationController!.pushViewController(instructionsViewController, animated: true)
            updateSetting()
        case .blockOther where sender.isOn:
            let alertController = UIAlertController(title: nil, message: UIConstants.strings.settingsBlockOtherMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: UIConstants.strings.settingsBlockOtherNo, style: UIAlertActionStyle.default) { _ in
                sender.isOn = false
                updateSetting()
            })
            alertController.addAction(UIAlertAction(title: UIConstants.strings.settingsBlockOtherYes, style: UIAlertActionStyle.destructive) { _ in
                updateSetting()
            })
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
            present(alertController, animated: true, completion: nil)
        default:
            updateSetting()
        }
    }
}

extension SettingsViewController: SearchSettingsViewControllerDelegate {
    func searchSettingsViewController(_ searchSettingsViewController: SearchSettingsViewController, didSelectEngine engine: SearchEngine) {
        (tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SettingsTableViewSearchCell)?.accessoryLabelText = engine.name
    }
}

private class BlockerToggle {
    let toggle = UISwitch()
    let label: String
    let setting: SettingsToggle
    let subtitle: String?

    init(label: String, setting: SettingsToggle, subtitle: String? = nil) {
        self.label = label
        self.setting = setting
        self.subtitle = subtitle
        toggle.accessibilityIdentifier = "BlockerToggle.\(setting.rawValue)"
    }
}
