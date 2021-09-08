/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit
import Telemetry
import Glean

protocol TrackingProtectionDelegate: class {
    func trackingProtectionDidToggleProtection(enabled: Bool)
}

class TrackingProtectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var modalDelegate: ModalDelegate?
    private let webViewController = WebViewController(userAgent: UserAgent.shared)
    private var isOpenedFromSetting = false
    weak var delegate: TrackingProtectionDelegate?
    private var trackingProtectionEnabled: Bool {
        get {
            Settings.getToggle(trackingProtectionToggle.setting)
        }
        set {
            tableView.reloadData()
        }
    }

    private let trackingProtectionToggle = BlockerToggle(label: UIConstants.strings.trackingProtectionToggleLabel, setting: SettingsToggle.trackingProtection)
    private let toggles = [
        BlockerToggle(label: UIConstants.strings.labelBlockAds2, setting: SettingsToggle.blockAds),
        BlockerToggle(label: UIConstants.strings.labelBlockAnalytics, setting: SettingsToggle.blockAnalytics),
        BlockerToggle(label: UIConstants.strings.labelBlockSocial, setting: SettingsToggle.blockSocial),
        BlockerToggle(label: UIConstants.strings.labelBlockOther, setting: SettingsToggle.blockOther)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalDelegate = self
        isOpenedFromSetting = self.navigationController?.viewControllers.count != 1
        
        view.backgroundColor = .primaryBackground
        title = UIConstants.strings.trackingProtectionLabel
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.primaryText]
        navigationController?.navigationBar.tintColor = .accent
        
        if !isOpenedFromSetting {
            let doneButton = UIBarButtonItem(title: UIConstants.strings.done, style: .plain, target: self, action: #selector(doneTapped))
            doneButton.tintColor = .accentButton
            navigationItem.rightBarButtonItem = doneButton
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.layoutIfNeeded()
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.barTintColor = .primaryBackground
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .primaryBackground
        tableView.separatorColor = .searchSeparator.withAlphaComponent(0.65)
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(15)
            make.leading.trailing.equalTo(self.view).inset(UIConstants.layout.trackingProtectionTableInset)
            make.bottom.equalTo(self.view)
        }

        for blockerToggle in toggles {
            let toggle = blockerToggle.toggle
            toggle.onTintColor = .accent
            toggle.tintColor = .darkGray
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            toggle.isOn = Settings.getToggle(blockerToggle.setting)
        }
    }

    @objc private func doneTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func tappedMoreSettings() {
        if !isOpenedFromSetting {
            self.dismiss(animated: true) { [weak self] in
                self?.showSettings()
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
    }
    
    private func showSettings() {
        guard let modalDelegate = modalDelegate else { return }

        let settingsViewController = SettingsViewController(searchEngineManager: SearchEngineManager(prefs: UserDefaults.standard), whatsNew: BrowserToolset(), shouldScrollToSiri: false)
        let settingsNavController = UINavigationController(rootViewController: settingsViewController)
        settingsNavController.modalPresentationStyle = .formSheet

        modalDelegate.presentModal(viewController: settingsNavController, animated: true)

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.settingsButton)

    }
    
    @objc private func toggleChanged(_ sender: UISwitch) {
        let toggle = toggles.filter { $0.toggle == sender }.first!

        func updateSetting() {
            let telemetryEvent = TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: "setting", value: toggle.setting.rawValue)
            telemetryEvent.addExtra(key: "to", value: sender.isOn)
            Telemetry.default.recordEvent(telemetryEvent)

            Settings.set(sender.isOn, forToggle: toggle.setting)
            ContentBlockerHelper.shared.reload()

            let sourceOfChange = isOpenedFromSetting ? "Settings" : "Panel"
            
            switch toggle.setting {
            case .blockAds:
                GleanMetrics.TrackingProtection.trackerSettingChanged.record(.init(isEnabled: sender.isOn, sourceOfChange: sourceOfChange, trackerChanged: "Advertising"))
            case .blockAnalytics:
                GleanMetrics.TrackingProtection.trackerSettingChanged.record(.init(isEnabled: sender.isOn, sourceOfChange: sourceOfChange, trackerChanged: "Analytics"))
            case .blockSocial:
                GleanMetrics.TrackingProtection.trackerSettingChanged.record(.init(isEnabled: sender.isOn, sourceOfChange: sourceOfChange, trackerChanged: "Social"))
            case .blockOther:
                GleanMetrics.TrackingProtection.trackerSettingChanged.record(.init(isEnabled: sender.isOn, sourceOfChange: sourceOfChange, trackerChanged: "Content"))
            default:
                break
            }
        }

        switch toggle.setting {
        case .blockOther where sender.isOn:
            let alertController = UIAlertController(title: nil, message: UIConstants.strings.settingsBlockOtherMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: UIConstants.strings.settingsBlockOtherNo, style: .default) { _ in
                sender.isOn = false
                updateSetting()
            })
            alertController.addAction(UIAlertAction(title: UIConstants.strings.settingsBlockOtherYes, style: .destructive) { _ in
                updateSetting()
            })
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
            present(alertController, animated: true, completion: nil)
        default:
            updateSetting()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return trackingProtectionEnabled ? 4 : 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            return trackingProtectionEnabled ? toggles.count : 1
        default:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return statsCell()
        case 1:
            return trackingProtectionCell()
        case 2:
            return trackingProtectionEnabled ? trackersCell(index: indexPath.row) : settingsCell()
        case 3:
            return settingsCell()
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.roundedCorners(tableView: tableView, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return headerView()
        case 2:
            return trackingProtectionEnabled ? trackersHeader() : nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 1 {
            let footer = UITableViewCell(style: .subtitle, reuseIdentifier: "trackingProtectionStatusFooter")
            footer.textLabel?.text = trackingProtectionEnabled ? UIConstants.strings.trackingProtectionOn : UIConstants.strings.trackingProtectionOff
            footer.textLabel?.textColor = .primaryText.withAlphaComponent(0.6)
            footer.textLabel?.numberOfLines = 0
            return footer
        }
        return nil
    }
    
    @objc func tappedTrackingProtectionLearnMoreHeader(sender: UIGestureRecognizer) {
        let contentViewController = SettingsContentViewController(url: URL(forSupportTopic: .trackingProtection))
        navigationController?.pushViewController(contentViewController, animated: true)
    }
    
    private func statsCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "trackingStats")
        cell.textLabel?.text = String(format: UIConstants.strings.trackersBlockedSince, getAppInstallDate())
        cell.textLabel?.textColor = .primaryText.withAlphaComponent(0.6)
        cell.textLabel?.font = UIConstants.fonts.trackingProtectionStatsText
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = getNumberOfTrackersBlocked()
        cell.detailTextLabel?.textColor = .primaryText
        cell.detailTextLabel?.font = UIConstants.fonts.trackingProtectionStatsDetail
        cell.backgroundColor = .secondaryBackground
        cell.selectionStyle = .none
        return cell
    }
    
    private func trackingProtectionCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "trackingProtectionToggleCell")
        trackingProtectionToggle.toggle.onTintColor = .accent
        trackingProtectionToggle.toggle.tintColor = .darkGray
        trackingProtectionToggle.toggle.addTarget(self, action: #selector(toggleProtection(sender:)), for: .valueChanged)
        trackingProtectionToggle.toggle.isOn = Settings.getToggle(trackingProtectionToggle.setting)
        cell.textLabel?.text = trackingProtectionToggle.label
        cell.textLabel?.textColor = .primaryText
        cell.textLabel?.numberOfLines = 0
        cell.accessoryView = PaddedSwitch(switchView: trackingProtectionToggle.toggle)
        cell.backgroundColor = .secondaryBackground
        cell.selectionStyle = .none

        return cell
    }
    
    private func trackersCell(index: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "trackingToggleCell")
        let toggle = toggles[index]
        cell.textLabel?.text = toggle.label
        cell.textLabel?.textColor = .primaryText
        cell.accessoryView = PaddedSwitch(switchView: toggle.toggle)
        cell.backgroundColor = .secondaryBackground
        cell.selectionStyle = .none

        return cell
    }
    
    private func settingsCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "trackingSettingsCell")
        cell.textLabel?.text = UIConstants.strings.trackingProtectionMoreSettings
        cell.textLabel?.textColor = .accentButton
        cell.backgroundColor = .secondaryBackground
        cell.selectionStyle = .none
        
        let selector = #selector(tappedMoreSettings)
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        cell.addGestureRecognizer(tapGesture)
        
        return cell
    }
    
    private func headerView() -> UIView {
        let textLabel = UILabel()
        textLabel.isUserInteractionEnabled = true
        textLabel.numberOfLines = 0
        
        let text = NSMutableAttributedString(string: String(format: UIConstants.strings.trackersDescriptionLabel2, AppInfo.productName), attributes: [.foregroundColor: UIColor.primaryText, .font: UIConstants.fonts.trackingProtectionHeader])
        let learnMore = NSAttributedString(string: UIConstants.strings.trackingProtectionLearnMore, attributes: [.foregroundColor: UIColor.accentButton, .font: UIConstants.fonts.trackingProtectionHeader])
        let space = NSAttributedString(string: "\n", attributes: [:])
        text.append(space)
        text.append(learnMore)
        textLabel.attributedText = text
        
        textLabel.backgroundColor = .primaryBackground
        
        let selector = #selector(tappedTrackingProtectionLearnMoreHeader)
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        textLabel.addGestureRecognizer(tapGesture)
        
        return textLabel
    }
    
    private func trackersHeader() -> UITableViewCell {
        let header = UITableViewCell(style: .subtitle, reuseIdentifier: "trackersHeader")
        header.textLabel?.text = UIConstants.strings.trackersHeader.uppercased()
        header.textLabel?.textColor = .primaryText.withAlphaComponent(0.6)
        header.textLabel?.numberOfLines = 0
        
        return header
    }
    
    private func getAppInstallDate() -> String {
        let urlToDocumentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        if let installDate = (try! FileManager.default.attributesOfItem(atPath: urlToDocumentsFolder.path)[FileAttributeKey.creationDate]) as? Date {
            let stringDate = dateFormatter.string(from: installDate)
            return stringDate
        }
        return dateFormatter.string(from: Date())
    }
        
    private func getNumberOfTrackersBlocked() -> String {
        let numberOfTrackersBlocked = NSNumber(integerLiteral: UserDefaults.standard.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: numberOfTrackersBlocked) ?? "0"
    }
    
    @objc private func toggleProtection(sender: UISwitch) {
        let toggle = trackingProtectionToggle
        let telemetryEvent = TelemetryEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.change, object: "setting", value: toggle.setting.rawValue)
        telemetryEvent.addExtra(key: "to", value: sender.isOn)
        Telemetry.default.recordEvent(telemetryEvent)

        GleanMetrics.TrackingProtection.trackingProtectionChanged.record(.init(isEnabled: sender.isOn))
        GleanMetrics.TrackingProtection.hasEverChangedEtp.set(true)

        Settings.set(sender.isOn, forToggle: toggle.setting)
        trackingProtectionEnabled = sender.isOn
        
        delegate?.trackingProtectionDidToggleProtection(enabled: sender.isOn)
    }
}

extension TrackingProtectionViewController: ModalDelegate {
    
    func presentModal(viewController: UIViewController, animated: Bool) {
        UIApplication.shared.windows.first?.rootViewController?.present(viewController, animated: animated, completion: nil)
    }
}
