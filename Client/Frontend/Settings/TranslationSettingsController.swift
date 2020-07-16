/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class TranslationSettingsController: ThemedTableViewController {
    struct UX {
        static var footerFontSize: CGFloat = 12
    }

    enum Section: Int {
        case translationOnOff
        case lightDarkPicker
    }

    private let profile: Profile
    private let setting: TranslationServices

    init(_ profile: Profile) {
        self.profile = profile
        self.setting = TranslationServices(prefs: profile.prefs)
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingTranslateSnackBarTitle
        tableView.accessibilityIdentifier = "Translate.Setting.Options"
        tableView.backgroundColor = UIColor.theme.tableView.headerBackground

        let headerFooterFrame = CGRect(width: self.view.frame.width, height: SettingsUX.TableViewHeaderFooterHeight)
        let headerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)
        tableView.tableHeaderView = headerView
        headerView.titleLabel.text = Strings.SettingTranslateSnackBarSectionHeader
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard !setting.translateOnOff else { return nil }

        let footer = UIView()
        let label = UILabel()
        footer.addSubview(label)
        label.text = Strings.SettingTranslateSnackBarSectionFooter
        label.numberOfLines = 0
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        label.font = UIFont.systemFont(ofSize: UX.footerFontSize)
        label.textColor = UIColor.theme.tableView.headerTextLight
        return footer
    }

    @objc func switchValueChanged(control: UISwitch) {
        self.setting.translateOnOff = control.isOn

        // Switch animation must begin prior to scheduling table view update animation (or the switch will be auto-synchronized to the slower tableview animation and makes the switch behaviour feel slow and non-standard).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.transition(with: self.tableView, duration: 0.2, options: .transitionCrossDissolve, animations: { self.tableView.reloadData()  })
        }

        TelemetryWrapper.recordEvent(category: .action, method: .change, object: .setting, value: "show-translation", extras: ["to": control.isOn ? "on" : "off"])
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.selectionStyle = .none
        let section = Section(rawValue: indexPath.section) ?? .translationOnOff
        switch section {
        case .translationOnOff:
            if indexPath.row == 0 {
                cell.textLabel?.text = Strings.SettingTranslateSnackBarSwitchTitle
                cell.detailTextLabel?.text = Strings.SettingTranslateSnackBarSwitchSubtitle
                cell.detailTextLabel?.numberOfLines = 4
                cell.detailTextLabel?.minimumScaleFactor = 0.5
                cell.detailTextLabel?.adjustsFontSizeToFitWidth = true

                let control = UISwitchThemed()
                control.accessibilityIdentifier = "TranslateSwitchValue"
                control.onTintColor = UIColor.theme.tableView.controlTint
                control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
                control.isOn = setting.translateOnOff

                // Add spacing between label and switch by wrapping the switch in a view.
                cell.accessoryView = UIView(frame: CGRect(width: 64, height: 44))
                cell.accessoryView?.addSubview(control)
                control.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview()
                }
            }

        case .lightDarkPicker:
            let thisService = setting.list[indexPath.row]
            cell.textLabel?.text = thisService.name

            let selectedService = setting.useTranslationService
            if thisService.id == selectedService.id {
                cell.accessoryType = .checkmark
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            } else {
                cell.accessoryType = .none
            }
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return !setting.translateOnOff ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return setting.list.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }

        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        setting.useTranslationService = setting.list[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != Section.translationOnOff.rawValue
    }
}
