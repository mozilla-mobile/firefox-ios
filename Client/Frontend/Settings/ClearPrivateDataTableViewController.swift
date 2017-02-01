/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private let SectionToggles = 0
private let SectionButton = 1
private let NumberOfSections = 2
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
private let TogglesPrefKey = "clearprivatedata.toggles"

private let log = Logger.browserLogger

private let HistoryClearableIndex = 0

class ClearPrivateDataTableViewController: UITableViewController {
    fileprivate var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    fileprivate typealias DefaultCheckedState = Bool

    fileprivate lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
        return [
            (HistoryClearable(profile: self.profile), true),
            (CacheClearable(tabManager: self.tabManager), true),
            (CookiesClearable(tabManager: self.tabManager), true),
            (SiteDataClearable(tabManager: self.tabManager), true),
        ]
    }()

    fileprivate lazy var toggles: [Bool] = {
        if let savedToggles = self.profile.prefs.arrayForKey(TogglesPrefKey) as? [Bool] {
            return savedToggles
        }

        return self.clearables.map { $0.checked }
    }()

    fileprivate var clearButtonEnabled = true {
        didSet {
            clearButton?.textLabel?.textColor = clearButtonEnabled ? UIConstants.DestructiveRed : UIColor.lightGray
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.SettingsClearPrivateDataTitle

        tableView.register(SettingsTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        let footer = SettingsTableSectionHeaderFooterView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: UIConstants.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        tableView.tableFooterView = footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)

        if indexPath.section == SectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
            let control = UISwitch()
            control.onTintColor = UIConstants.ControlTintColor
            control.addTarget(self, action: #selector(ClearPrivateDataTableViewController.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
            control.isOn = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .none
            control.tag = indexPath.item
        } else {
            assert(indexPath.section == SectionButton)
            cell.textLabel?.text = Strings.SettingsClearPrivateDataClearButton
            cell.textLabel?.textAlignment = NSTextAlignment.center
            cell.textLabel?.textColor = UIConstants.DestructiveRed
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityIdentifier = "ClearPrivateData"
            clearButton = cell
        }

        return cell
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionToggles {
            return clearables.count
        }

        assert(section == SectionButton)
        return 1
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == SectionButton else { return false }

        // Highlight the button only if it's enabled.
        return clearButtonEnabled
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == SectionButton else { return }

        func clearPrivateData(_ action: UIAlertAction) {
            let toggles = self.toggles
            self.clearables
                .enumerated()
                .flatMap { (i, pair) in
                    guard toggles[i] else {
                        return nil
                    }
                    log.debug("Clearing \(pair.clearable).")
                    return pair.clearable.clear()
                }
                .allSucceed()
                .upon { result in
                    assert(result.isSuccess, "Private data cleared successfully")

                    self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)

                    DispatchQueue.main.async {
                        // Disable the Clear Private Data button after it's clicked.
                        self.clearButtonEnabled = false
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    }
            }
        }

        // We have been asked to clear history and we have an account.
        // (Whether or not it's in a good state is irrelevant.)
        if self.toggles[HistoryClearableIndex] && profile.hasAccount() {
            profile.syncManager.hasSyncedHistory().uponQueue(DispatchQueue.main) { yes in
                // Err on the side of warning, but this shouldn't fail.
                let alert: UIAlertController
                if yes.successValue ?? true {
                    // Our local database contains some history items that have been synced.
                    // Warn the user before clearing.
                    alert = UIAlertController.clearSyncedHistoryAlert(okayCallback: clearPrivateData)
                } else {
                    alert = UIAlertController.clearPrivateDataAlert(okayCallback: clearPrivateData)
                }
                self.present(alert, animated: true, completion: nil)
                return
            }
        } else {
            let alert = UIAlertController.clearPrivateDataAlert(okayCallback: clearPrivateData)
            self.present(alert, animated: true, completion: nil)
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as! SettingsTableSectionHeaderFooterView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIConstants.TableViewHeaderFooterHeight
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        toggles[toggle.tag] = toggle.isOn

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)
    }
}
