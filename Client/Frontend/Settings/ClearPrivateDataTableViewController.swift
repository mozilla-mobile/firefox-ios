/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private let SectionArrow = 0
private let SectionToggles = 1
private let SectionButton = 2
private let NumberOfSections = 3
private let SectionHeaderFooterIdentifier = "SectionHeaderFooterIdentifier"
private let TogglesPrefKey = "clearprivatedata.toggles"

private let log = Logger.browserLogger

private let HistoryClearableIndex = 0

class ClearPrivateDataTableViewController: ThemedTableViewController {
    fileprivate var clearButton: UITableViewCell?

    var profile: Profile!
    var tabManager: TabManager!

    fileprivate typealias DefaultCheckedState = Bool

    // TODO: The next person to add a new clearable in the UI here needs to
    // refactor how we store the saved values. We currently save an array of
    // `Bool`s which is highly insufficient.
    // Bug 1445687 -- https://bugzilla.mozilla.org/show_bug.cgi?id=1445687
    fileprivate lazy var clearables: [(clearable: Clearable, checked: DefaultCheckedState)] = {
        var items: [(clearable: Clearable, checked: DefaultCheckedState)] = [
            (HistoryClearable(profile: self.profile), true),
            (CacheClearable(tabManager: self.tabManager), true),
            (CookiesClearable(tabManager: self.tabManager), true),
            (SiteDataClearable(tabManager: self.tabManager), true)
        ]
        if #available(iOS 11, *) {
            items.append((TrackingProtectionClearable(), true))
        }
        items.append((DownloadedFilesClearable(), false)) // Don't clear downloaded files by default
        return items
    }()

    fileprivate lazy var toggles: [Bool] = {
        // If the number of saved toggles doesn't match the number of clearables, just reset
        // and return the default values for the clearables.
        if let savedToggles = self.profile.prefs.arrayForKey(TogglesPrefKey) as? [Bool], savedToggles.count == self.clearables.count {
            return savedToggles
        }

        return self.clearables.map { $0.checked }
    }()

    fileprivate var clearButtonEnabled = true {
        didSet {
            clearButton?.textLabel?.textColor = clearButtonEnabled ? UIColor.theme.general.destructiveRed : UIColor.theme.tableView.disabledRowText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.SettingsDataManagementTitle

        tableView.register(ThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderFooterIdentifier)

        let footer = ThemedTableSectionHeaderFooterView(frame: CGRect(width: tableView.bounds.width, height: SettingsUX.TableViewHeaderFooterHeight))
        footer.showBottomBorder = false
        footer.showTopBorder = false
        tableView.tableFooterView = footer
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell()

        if indexPath.section == SectionArrow {
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = Strings.SettingsWebsiteDataTitle
            cell.accessibilityIdentifier = "WebsiteData"
            clearButton = cell
        } else if indexPath.section == SectionToggles {
            cell.textLabel?.text = clearables[indexPath.item].clearable.label
            let control = UISwitchThemed()
            control.onTintColor = UIColor.theme.tableView.controlTint
            control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
            control.isOn = toggles[indexPath.item]
            cell.accessoryView = control
            cell.selectionStyle = .none
            control.tag = indexPath.item
        } else {
            assert(indexPath.section == SectionButton)
            cell.textLabel?.text = Strings.SettingsClearPrivateDataClearButton
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = UIColor.theme.general.destructiveRed
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
        if section == SectionArrow {
            return 1
        } else if section == SectionToggles {
            return clearables.count
        }
        assert(section == SectionButton)
        return 1

    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == SectionButton {
            // Highlight the button only if it's enabled.
            return clearButtonEnabled
        }
        if indexPath.section == SectionArrow {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SectionArrow {
            let view = WebsiteDataManagementViewController()
            navigationController?.pushViewController(view, animated: true)
        } else if indexPath.section == SectionButton {
            // We have been asked to clear history and we have an account.
            // (Whether or not it's in a good state is irrelevant.)
            func clearPrivateData(_ action: UIAlertAction) {
                let toggles = self.toggles
                self.clearables
                    .enumerated()
                    .compactMap { (i, pair) in
                        guard toggles[i] else {
                            return nil
                        }
                        log.debug("Clearing \(pair.clearable).")
                        return pair.clearable.clear()
                    }
                    .allSucceed()
                    .uponQueue(.main) { result in
                        assert(result.isSuccess, "Private data cleared successfully")

                        LeanPlumClient.shared.track(event: .clearPrivateData)

                        self.profile.prefs.setObject(self.toggles, forKey: TogglesPrefKey)

                        // Disable the Clear Private Data button after it's clicked.
                        self.clearButtonEnabled = false
                        self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }
            if self.toggles[HistoryClearableIndex] && profile.hasAccount() {
                profile.syncManager.hasSyncedHistory().uponQueue(.main) { yes in
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
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderFooterIdentifier) as? ThemedTableSectionHeaderFooterView
        headerView?.showTopBorder = false
        var sectionTitle: String?
        if section == SectionToggles {
            sectionTitle = Strings.SettingsClearPrivateDataTitle
        } else {
            sectionTitle = nil
        }
        headerView?.titleLabel.text = sectionTitle
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SettingsUX.TableViewHeaderFooterHeight
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        toggles[toggle.tag] = toggle.isOn

        // Dim the clear button if no clearables are selected.
        clearButtonEnabled = toggles.contains(true)
    }
}
