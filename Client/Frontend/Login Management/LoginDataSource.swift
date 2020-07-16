/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit

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
        let cell = LoginListTableViewCell(style: .subtitle, reuseIdentifier: CellReuseIdentifier)

        // Need to override the default background multi-select color to support theming
        cell.multipleSelectionBackgroundView = UIView()
        cell.applyTheme()

        if indexPath.section == LoginsSettingsSection {
            let hideSettings = viewModel.searchController?.isActive ?? false || tableView.isEditing
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
            guard let login = viewModel.loginAtIndexPath(indexPath) else { return cell }
            cell.textLabel?.text = login.hostname
            cell.detailTextColor = UIColor.theme.tableView.rowDetailText
            cell.detailTextLabel?.text = login.username
            if let breaches = viewModel.userBreaches, breaches.contains(login) {
                cell.breachAlertImageView.isHidden = false
                if !viewModel.breachIndexPath.contains(indexPath) {
                    viewModel.setBreachIndexPath(indexPath: indexPath)
                }
            }
        }
        return cell
    }
}

class LoginListTableViewCell: ThemedTableViewCell {
    lazy var breachAlertImageView: UIImageView = {
        let image = UIImage(named: "Breached Website")
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()
    let breachAlertSize: CGFloat = 24

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(breachAlertImageView)
        breachAlertImageView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailing).offset(-LoginTableViewCellUX.HorizontalMargin)
            make.width.equalTo(breachAlertSize)
            make.height.equalTo(breachAlertSize)
        }

        textLabel?.snp.remakeConstraints({ make in
            make.leading.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
            make.trailing.equalTo(breachAlertImageView.snp.leading).offset(-LoginTableViewCellUX.HorizontalMargin/2)
            make.top.bottom.equalTo(contentView)
            make.centerY.equalTo(contentView)
            if let detailTextLabel = self.detailTextLabel {
                make.bottom.equalTo(detailTextLabel.snp.top)
                make.top.equalTo(contentView.snp.top).offset(LoginTableViewCellUX.HorizontalMargin)
            }
        })

        // Need to override the default background multi-select color to support theming
        self.multipleSelectionBackgroundView = UIView()
        self.applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
