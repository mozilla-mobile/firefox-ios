/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class AutocompleteSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
        super.viewDidLoad()
        title = UIConstants.strings.settingsAutocompleteSection
        navigationController?.navigationBar.tintColor = .accent

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != 0 ? 50 : 30
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.section == 0 {
            let blockerToggle = BlockerToggle(label: UIConstants.strings.settingsAutocompleteSection, setting: .enableCustomDomainAutocomplete)
            blockerToggle.toggle.isOn = Settings.getToggle(.enableDomainAutocomplete)
            blockerToggle.toggle.accessibilityIdentifier = "toggleAutocompleteSwitch"
            blockerToggle.toggle.addTarget(self, action: #selector(defaultToggleSwitched(_:)), for: .valueChanged)
            blockerToggle.toggle.onTintColor = .accent
            let toggleCell = SettingsTableViewToggleCell(style: .subtitle, reuseIdentifier: "enableCell", toggle: blockerToggle)
            toggleCell.setConfiguration(text: UIConstants.strings.autocompleteTopSites)
            cell = toggleCell
        } else {
            if indexPath.row == 0 {
                let blockerToggle = BlockerToggle(label: UIConstants.strings.settingsAutocompleteSection, setting: .enableCustomDomainAutocomplete)
                blockerToggle.toggle.isOn = Settings.getToggle(.enableCustomDomainAutocomplete)
                blockerToggle.toggle.accessibilityIdentifier = "toggleCustomAutocompleteSwitch"
                blockerToggle.toggle.addTarget(self, action: #selector(customToggleSwitched(_:)), for: .valueChanged)
                blockerToggle.toggle.onTintColor = .accent
                let toggleCell = SettingsTableViewToggleCell(style: .subtitle, reuseIdentifier: "enableCell", toggle: blockerToggle)
                toggleCell.setConfiguration(text: UIConstants.strings.autocompleteMySites)
                cell = toggleCell
            } else {
                let settingCell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: "newDomainCell")
                settingCell.accessoryType = .disclosureIndicator
                settingCell.accessibilityIdentifier = "customURLS"
                settingCell.setConfiguration(text: UIConstants.strings.autocompleteManageSitesLabel)
                cell = settingCell
            }
        }

        cell.textLabel?.textColor = .primaryText
        cell.layoutMargins = UIEdgeInsets.zero

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 && indexPath.row == 1 {
            let autocompleteSource = CustomCompletionSource(
                enableCustomDomainAutocomplete: { Settings.getToggle(.enableCustomDomainAutocomplete) },
                getCustomDomainSetting: { Settings.getCustomDomainSetting() },
                setCustomDomainSetting: { Settings.setCustomDomainSetting(domains: $0) }
            )
            let viewController = AutocompleteCustomUrlViewController(customAutocompleteSource: autocompleteSource)
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.autocompleteTopSitesDesc, AppInfo.productName), attributes: [.foregroundColor: UIColor.secondaryLabel])
            let footer = ActionFooterView(frame: .zero)
            footer.textLabel.attributedText = subtitle
            footer.detailTextButton.setTitle(UIConstants.strings.learnMore, for: .normal)
            footer.accessibilityIdentifier = "SettingsViewController.autocompleteLearnMore"
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreDefaultTapped))
            footer.detailTextButton.addGestureRecognizer(tapGesture)
            return footer

        case 1:
            let subtitle = NSMutableAttributedString(string: String(format: UIConstants.strings.autocompleteManageSitesDesc, AppInfo.productName), attributes: [.foregroundColor: UIColor.secondaryLabel])
            let footer = ActionFooterView(frame: .zero)
            footer.textLabel.attributedText = subtitle
            footer.detailTextButton.setTitle(UIConstants.strings.learnMore, for: .normal)
            footer.accessibilityIdentifier = "SettingsViewController.customAutocompleteLearnMore"
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreCustomapped))
            footer.detailTextButton.addGestureRecognizer(tapGesture)
            return footer

        default: return nil
        }
    }

    @objc
    private func defaultToggleSwitched(_ sender: UISwitch) {
        let enabled = sender.isOn
        Settings.set(enabled, forToggle: .enableDomainAutocomplete)
    }

    @objc
    private func customToggleSwitched(_ sender: UISwitch) {
        let enabled = sender.isOn
        Settings.set(enabled, forToggle: .enableCustomDomainAutocomplete)
    }

    @objc
    private func learnMoreDefaultTapped() {
        let contentViewController = SettingsContentViewController(url: URL(forSupportTopic: .autofillDomain))
        navigationController?.pushViewController(contentViewController, animated: true)
    }

    @objc
    private func learnMoreCustomapped() {
        let contentViewController = SettingsContentViewController(url: URL(forSupportTopic: .autofillDomain))
        navigationController?.pushViewController(contentViewController, animated: true)
    }
}
