/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class OpenWithSettingsViewController: ThemedTableViewController {
    typealias MailtoProviderEntry = (name: String, scheme: String, enabled: Bool)
    var mailProviderSource = [MailtoProviderEntry]()

    fileprivate let prefs: Prefs
    fileprivate var currentChoice: String = "mailto"

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsOpenWithSectionName

        tableView.accessibilityIdentifier = "OpenWithPage.Setting.Options"

        let headerFooterFrame = CGRect(width: self.view.frame.width, height: SettingsUX.TableViewHeaderFooterHeight)
        let headerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.titleLabel.text = Strings.SettingsOpenWithPageTitle.uppercased()
        let footerView = ThemedTableSectionHeaderFooterView(frame: headerFooterFrame)

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDidBecomeActive()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice, forKey: PrefsKeys.KeyMailToOption)
    }

    @objc func appDidBecomeActive() {
        reloadMailProviderSource()
        updateCurrentChoice()
        tableView.reloadData()
    }

    func updateCurrentChoice() {
        var previousChoiceAvailable: Bool = false
        if let prefMailtoScheme = self.prefs.stringForKey(PrefsKeys.KeyMailToOption) {
            mailProviderSource.forEach({ (name, scheme, enabled) in
                if scheme == prefMailtoScheme {
                    previousChoiceAvailable = enabled
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
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            mailProviderSource = dictRoot.map {  dict in
                let nsDict = dict as! NSDictionary
                return (name: nsDict["name"] as! String, scheme: nsDict["scheme"] as! String,
                        enabled: canOpenMailScheme(nsDict["scheme"] as! String))
            }
        }
    }

    func canOpenMailScheme(_ scheme: String) -> Bool {
        if let url = URL(string: scheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThemedTableViewCell()
        let option = mailProviderSource[indexPath.row]

        cell.textLabel?.attributedText = NSAttributedString.tableRowTitle(option.name, enabled: option.enabled)
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
}
