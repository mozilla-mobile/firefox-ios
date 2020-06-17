/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
            BoolSetting(prefs: viewModel.profile.prefs, prefKey: PrefsKeys.LoginsSaveEnabled, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingToSaveLogins)),
            BoolSetting(prefs: viewModel.profile.prefs, prefKey: PrefsKeys.LoginsShowShortcutMenuItem, defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.SettingToShowLoginsInAppMenu)))
        super.init()
    }

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.dataSource.loginRecordSections.isEmpty {
            tableView.backgroundView = emptyStateView
            return 1
        }

        tableView.backgroundView = nil
        // Add one section for the settings section.
        return viewModel.dataSource.loginRecordSections.count + 1
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == LoginsSettingsSection {
            return 2
        }
        return viewModel.dataSource.loginsForSection(section)?.count ?? 0
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: CellReuseIdentifier)

        if indexPath.section == LoginsSettingsSection {
            let hideSettings = viewModel.dataSource.searchController?.isActive ?? false || tableView.isEditing
            let setting = indexPath.row == 0 ? boolSettings.0 : boolSettings.1
            setting.onConfigureCell(cell)
            if hideSettings {
                cell.isHidden = true
            }

            // Fade in the cell while dismissing the search or the cell showing suddenly looks janky
            if viewModel.isDuringSearchControllerDismiss {
                cell.isHidden = false
                cell.contentView.alpha = 0
                cell.accessoryView?.alpha = 0
                UIView.animate(withDuration: 0.6) {
                    cell.contentView.alpha = 1
                    cell.accessoryView?.alpha = 1
                }
            }
        } else {
            guard let login = viewModel.dataSource.loginAtIndexPath(indexPath) else { return cell }
            cell.textLabel?.text = login.hostname
            cell.detailTextColor = UIColor.theme.tableView.rowDetailText
            cell.detailTextLabel?.text = login.username
            cell.accessoryType = .disclosureIndicator
        }
        // Need to override the default background multi-select color to support theming
        cell.multipleSelectionBackgroundView = UIView()
        cell.applyTheme()
        return cell
    }
}
