// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

class OpenWithSettingsViewController: ThemedTableViewController {
    struct MailtoProviderEntry {
        let name: String
        let scheme: String
        let enabled: Bool
    }

    var mailProviderSource = [MailtoProviderEntry]()

    fileprivate let prefs: Prefs
    fileprivate var currentChoice: String = "mailto"

    init(prefs: Prefs, windowUUID: WindowUUID) {
        self.prefs = prefs
        super.init(windowUUID: windowUUID)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .SettingsOpenWithSectionName

        tableView.accessibilityIdentifier = "OpenWithPage.Setting.Options"
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDidBecomeActive()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice, forKey: PrefsKeys.KeyMailToOption)
    }

    @objc
    func appDidBecomeActive() {
        reloadMailProviderSource()
        updateCurrentChoice()
        tableView.reloadData()
    }

    func updateCurrentChoice() {
        var previousChoiceAvailable = false
        if let prefMailtoScheme = self.prefs.stringForKey(PrefsKeys.KeyMailToOption) {
            mailProviderSource.forEach({ item in
                if item.scheme == prefMailtoScheme {
                    previousChoiceAvailable = item.enabled
                }
            })
        }

        if !previousChoiceAvailable {
            self.prefs.setString(mailProviderSource[0].scheme, forKey: PrefsKeys.KeyMailToOption)
        }

        if let updatedMailToClient = self.prefs.stringForKey(PrefsKeys.KeyMailToOption) {
            self.currentChoice = updatedMailToClient
        }
    }

    func reloadMailProviderSource() {
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"),
           let dictRoot = NSArray(contentsOfFile: path) {
            mailProviderSource = dictRoot.compactMap { dict in
                guard let nsDict = dict as? NSDictionary,
                      let name = nsDict["name"] as? String,
                      let scheme = nsDict["scheme"] as? String
                else { return nil }

                return (MailtoProviderEntry(name: name,
                                            scheme: scheme,
                                            enabled: canOpenMailScheme(scheme)))
            }
        }
    }

    func canOpenMailScheme(_ scheme: String) -> Bool {
        if let url = URL(string: scheme, invalidCharacters: false) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCellFor(indexPath: indexPath)
        let option = mailProviderSource[indexPath.row]

        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))

        cell.textLabel?.attributedText = tableRowTitle(option.name, enabled: option.enabled)
        cell.accessoryType = (currentChoice == option.scheme && option.enabled) ? .checkmark : .none
        cell.isUserInteractionEnabled = option.enabled

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailProviderSource.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentChoice = mailProviderSource[indexPath.row].scheme
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = super.tableView(
            tableView,
            viewForHeaderInSection: section
        ) as? ThemedTableSectionHeaderFooterView else { return nil }

        headerView.titleLabel.text = .SettingsOpenWithPageTitle.uppercased()
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    private func tableRowTitle(_ string: String, enabled: Bool) -> NSAttributedString {
        var color: [NSAttributedString.Key: UIColor]
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        if enabled {
            color = [
                NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
            ]
        } else {
            color = [
                NSAttributedString.Key.foregroundColor: theme.colors.textDisabled
            ]
        }

        return NSAttributedString(string: string, attributes: color)
    }
}
