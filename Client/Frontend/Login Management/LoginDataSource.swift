// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

/// Data source for handling LoginData objects from a Cursor
class LoginDataSource: NSObject, UITableViewDataSource {
    // in case there are no items to run cellForRowAt on, use an empty state view
    fileprivate let emptyStateView = NoLoginsView()
    fileprivate var viewModel: LoginListViewModel

    let boolSettings: (BoolSetting, BoolSetting)

    init(viewModel: LoginListViewModel) {
        self.viewModel = viewModel
        boolSettings = (
            BoolSetting(prefs: viewModel.profile.prefs, prefKey: PrefsKeys.LoginsSaveEnabled, defaultValue: true, attributedTitleText: NSAttributedString(string: .SettingToSaveLogins)),
            BoolSetting(prefs: viewModel.profile.prefs, prefKey: PrefsKeys.LoginsShowShortcutMenuItem, defaultValue: true, attributedTitleText: NSAttributedString(string: .SettingToShowLoginsInAppMenu)))
        super.init()
    }

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.loginRecordSections.isEmpty {
            tableView.backgroundView = emptyStateView
            return 1
        }

        tableView.backgroundView = nil
        // Add one section for the settings section.
        return viewModel.loginRecordSections.count + 1
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == LoginsSettingsSection {
            return 2
        }
        return viewModel.loginsForSection(section)?.count ?? 0
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == LoginsSettingsSection {
            let cell = LoginListTableViewSettingsCell(style: .default, reuseIdentifier: CellReuseIdentifier)

            let hideSettings = viewModel.searchController?.isActive ?? false || tableView.isEditing
            let setting = indexPath.row == 0 ? boolSettings.0 : boolSettings.1
            setting.onConfigureCell(cell)
            if hideSettings {
                cell.isHidden = true
            } else if viewModel.isDuringSearchControllerDismiss {
            // Fade in the cell while dismissing the search or the cell showing suddenly looks janky
                cell.isHidden = false
                cell.contentView.alpha = 0
                cell.accessoryView?.alpha = 0
                UIView.animate(withDuration: 0.6) {
                    cell.contentView.alpha = 1
                    cell.accessoryView?.alpha = 1
                }
            }
            return cell
        } else {
            let cell = LoginListTableViewCell(style: .subtitle, reuseIdentifier: CellReuseIdentifier, inset: tableView.separatorInset)
            guard let login = viewModel.loginAtIndexPath(indexPath) else { return cell }
            let username = login.decryptedUsername
            cell.hostnameLabel.text = login.hostname
            cell.usernameLabel.text = username.isEmpty ? "(no username)" : username
            if NightModeHelper.hasEnabledDarkTheme(viewModel.profile.prefs) {
                cell.breachAlertImageView.tintColor = BreachAlertsManager.darkMode
            } else {
                cell.breachAlertImageView.tintColor = BreachAlertsManager.lightMode
            }
            if let breaches = viewModel.userBreaches, breaches.contains(login) {
                cell.breachAlertImageView.isHidden = false
            }
        return cell
        }
    }
}
