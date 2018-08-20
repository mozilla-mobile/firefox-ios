/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

class AutocompleteSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 2
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIConstants.colors.background
        
        title = UIConstants.strings.settingsAutocompleteSection

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIConstants.colors.background
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIConstants.colors.settingsSeparator
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelText: String
        var groupingOffset = 16

        switch section {
        case 0:
            labelText = UIConstants.strings.autocompleteDefaultSectionTitle
            groupingOffset = 3
        case 1: labelText = UIConstants.strings.autocompleteCustomSectionTitle
        default: fatalError("No title for section: \(section)")
        }

        // Hack: We want the header view's margin to match the cells, so we create an empty
        // cell with a blank space as text to layout the text label. From there, we can define
        // constraints for our custom label based on the cell's label.
        let cell = UITableViewCell()
        cell.textLabel?.text = " "
        cell.backgroundColor = UIConstants.colors.background

        let label = SmartLabel()
        label.text = labelText
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
        return section != 0 ? 50 : 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if (indexPath.section == 0) {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "enableCell")
            cell.textLabel?.text = UIConstants.strings.autocompleteLabel
            
            let toggle = UISwitch()
            toggle.addTarget(self, action: #selector(defaultToggleSwitched(_:)), for: .valueChanged)
            toggle.accessibilityIdentifier = "toggleAutocompleteSwitch"
            toggle.isOn = Settings.getToggle(.enableDomainAutocomplete)
            toggle.onTintColor = UIConstants.colors.toggleOn
            cell.accessoryView = PaddedSwitch(switchView: toggle)
            
        } else {
            if indexPath.row == 0 {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "enableCell")
                cell.textLabel?.text = UIConstants.strings.autocompleteLabel

                let toggle = UISwitch()
                toggle.addTarget(self, action: #selector(customToggleSwitched(_:)), for: .valueChanged)
                toggle.accessibilityIdentifier = "toggleCustomAutocompleteSwitch"
                toggle.isOn = Settings.getToggle(.enableCustomDomainAutocomplete)
                toggle.onTintColor = UIConstants.colors.toggleOn
                cell.accessoryView = PaddedSwitch(switchView: toggle)
            } else {
                cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "newDomainCell")
                cell.accessoryType = .disclosureIndicator
                cell.accessibilityIdentifier = "customURLS"
                cell.textLabel?.text = UIConstants.strings.autocompleteCustomSectionLabel
            }
        }
        
        cell.backgroundColor = UIConstants.colors.cellBackground
        cell.textLabel?.textColor = UIConstants.colors.settingsTextLabel
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 1 {
            let viewController = AutocompleteCustomUrlViewController(customAutocompleteSource: CustomCompletionSource())
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [.foregroundColor : UIConstants.colors.settingsLink])
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.autocompleteDefaultDescription, AppInfo.productName), attributes: [.foregroundColor : UIConstants.colors.settingsDetailLabel])
            let space = NSAttributedString(string: " ", attributes: [:])
            subtitle.append(space)
            subtitle.append(learnMore)
            cell.detailTextLabel?.attributedText = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessibilityIdentifier = "SettingsViewController.autocompleteLearnMore"
            cell.selectionStyle = .none
            cell.backgroundColor = UIConstants.colors.background
            cell.layoutMargins = UIEdgeInsets.zero

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreDefaultTapped))
            cell.addGestureRecognizer(tapGesture)

            return cell
        case 1:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let learnMore = NSAttributedString(string: UIConstants.strings.learnMore, attributes: [.foregroundColor : UIConstants.colors.settingsLink])
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.autocompleteCustomDescription, AppInfo.productName), attributes: [.foregroundColor : UIConstants.colors.settingsDetailLabel])
            let space = NSAttributedString(string: " ", attributes: [:])
            subtitle.append(space)
            subtitle.append(learnMore)
            cell.detailTextLabel?.attributedText = subtitle
            cell.detailTextLabel?.numberOfLines = 0
            cell.accessibilityIdentifier = "SettingsViewController.customAutocompleteLearnMore"
            cell.selectionStyle = .none
            cell.backgroundColor = UIConstants.colors.background
            cell.layoutMargins = UIEdgeInsets.zero

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreCustomapped))
            cell.addGestureRecognizer(tapGesture)

            return cell
        default: return nil
        }
    }

    @objc private func defaultToggleSwitched(_ sender: UISwitch) {
        let enabled = sender.isOn
        Settings.set(enabled, forToggle: .enableDomainAutocomplete)
    }

    @objc private func customToggleSwitched(_ sender: UISwitch) {
        let enabled = sender.isOn
        Settings.set(enabled, forToggle: .enableCustomDomainAutocomplete)
    }

    @objc private func learnMoreDefaultTapped() {
        guard let url = SupportUtils.URLForTopic(topic: "autofill-domain-ios") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    @objc private func learnMoreCustomapped() {
        guard let url = SupportUtils.URLForTopic(topic: "autofill-domain-ios") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        navigationController?.pushViewController(contentViewController, animated: true)
    }
}



