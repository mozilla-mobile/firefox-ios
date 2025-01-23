// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common
import ComponentLibrary

class ClearPrivateDataTableViewController: ThemedTableViewController {
    private var clearButton: UITableViewCell?

    private let sectionArrow = 0
    private let sectionToggles = 1
    private let sectionButton = 2
    private let numberOfSections = 3
    private let historyClearableIndex = 0

    private enum Keys: String {
        case keyTogglesPref = "clearprivatedata.toggles"
    }

    private var profile: Profile
    private var tabManager: TabManager

    private typealias DefaultCheckedState = Bool

    private lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
        var items: [(clearable: Clearable, checked: DefaultCheckedState)] = [
            (HistoryClearable(profile: profile, tabManager: tabManager), true),
            (CacheClearable(), true),
            (CookiesClearable(), true),
            (SiteDataClearable(), true),
            (TrackingProtectionClearable(), true),
            (DownloadedFilesClearable(), false), // Don't clear downloaded files by default
        ]

        let spotlightConfig = FxNimbus.shared.features.spotlightSearch.value()
        if spotlightConfig.enabled {
            items.append((SpotlightClearable(), false)) // On device only, so don't clear by default.)
        }

        return items
    }()

    private lazy var toggles: [Bool] = {
        // If the number of saved toggles doesn't match the number of clearables, just reset
        // and return the default values for the clearables.
        if let savedToggles = self.profile.prefs.arrayForKey(Keys.keyTogglesPref.rawValue) as? [Bool],
            savedToggles.count == self.clearables.count {
            return savedToggles
        }

        return self.clearables.map { $0.checked }
    }()

    private var clearButtonEnabled = true {
        didSet {
            let textWarningColor = currentTheme().colors.textCritical
            let textDisabledColor = currentTheme().colors.textDisabled
            clearButton?.textLabel?.textColor = clearButtonEnabled ? textWarningColor : textDisabledColor
        }
    }

    init(profile: Profile,
         tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager

        super.init(windowUUID: tabManager.windowUUID)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = .SettingsDataManagementTitle

        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width,
                                                                      height: SettingsUX.TableViewHeaderFooterHeight))
        footer.applyTheme(theme: currentTheme())
        tableView.tableFooterView = footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCellFor(indexPath: indexPath)
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        if indexPath.section == sectionArrow {
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = .SettingsWebsiteDataTitle
            cell.accessibilityIdentifier = AccessibilityIdentifiers.Settings.ClearData.websiteDataSection
            clearButton = cell
            return cell
        } else if indexPath.section == sectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
            cell.textLabel?.numberOfLines = 0
            let control = ThemedSwitch()
            control.applyTheme(theme: currentTheme())
            control.onTintColor = currentTheme().colors.actionPrimary
            control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
            control.isOn = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .none
            control.tag = indexPath.item
            return cell
        } else if let cell = cell as? ThemedCenteredTableViewCell {
            cell.setTitle(to: .SettingsClearPrivateDataClearButton)
            cell.setAccessibilities(
                traits: .button,
                identifier: AccessibilityIdentifiers.Settings.ClearData.clearPrivateDataSection)
            clearButton = cell
            return cell
        } else {
            return ThemedTableViewCell()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sectionArrow {
            return 1
        } else if section == sectionToggles {
            return clearables.count
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == sectionButton {
            // Highlight the button only if it's enabled.
            return clearButtonEnabled
        } else if indexPath.section == sectionArrow {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionArrow {
            let view = WebsiteDataManagementViewController(windowUUID: windowUUID)
            navigationController?.pushViewController(view, animated: true)
        } else if indexPath.section == sectionButton {
            let alert: UIAlertController
            if self.toggles[historyClearableIndex] && profile.hasAccount() {
                alert = clearSyncedHistoryAlert(okayCallback: clearPrivateData)
            } else {
                alert = clearPrivateDataAlert(okayCallback: clearPrivateData)
            }
            present(alert, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func dequeueCellFor(indexPath: IndexPath) -> ThemedTableViewCell {
        guard indexPath.section == sectionButton else {
            return super.dequeueCellFor(indexPath: indexPath)
        }

        if let cell = tableView.dequeueReusableCell(
            withIdentifier: ThemedCenteredTableViewCell.cellIdentifier,
            for: indexPath) as? ThemedCenteredTableViewCell {
            return cell
        }
        return ThemedTableViewCell()
    }
    private func clearPrivateData(_ action: UIAlertAction) {
        let toggles = self.toggles
        self.clearables
            .enumerated()
            .compactMap { (i, pair) in
                guard toggles[i] else { return nil }
                return pair.clearable.clear()
            }
            .allSucceed()
            .uponQueue(.main) { result in
                self.profile.prefs.setObject(self.toggles, forKey: Keys.keyTogglesPref.rawValue)

                // Disable the Clear Private Data button after it's clicked.
                self.clearButtonEnabled = false
            }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier
            ) as? ThemedTableSectionHeaderFooterView
        else { return nil }

        var sectionTitle: String?
        if section == sectionToggles {
            sectionTitle = .SettingsClearPrivateDataSectionName
        } else {
            sectionTitle = nil
        }
        headerView.titleLabel.text = sectionTitle
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    @objc
    private func switchValueChanged(_ toggle: UISwitch) {
        toggles[toggle.tag] = toggle.isOn

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)

        profile.prefs.setObject(toggles, forKey: Keys.keyTogglesPref.rawValue)
    }

    private func clearPrivateDataAlert(okayCallback: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "",
            message: .ClearPrivateDataAlertMessage,
            preferredStyle: .alert
        )

        let noOption = UIAlertAction(
            title: .ClearPrivateDataAlertCancel,
            style: .default,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: .ClearPrivateDataAlertOk,
            style: .destructive,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }

    private func clearSyncedHistoryAlert(okayCallback: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: "",
            message: .ClearSyncedHistoryAlertMessage,
            preferredStyle: .alert
        )

        let noOption = UIAlertAction(
            title: .ClearSyncedHistoryAlertCancel,
            style: .default,
            handler: nil
        )

        let okayOption = UIAlertAction(
            title: .ClearSyncedHistoryAlertOk,
            style: .destructive,
            handler: okayCallback
        )

        alert.addAction(okayOption)
        alert.addAction(noOption)
        return alert
    }
}
