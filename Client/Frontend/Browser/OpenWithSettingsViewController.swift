/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class OpenWithSettingsViewController: UITableViewController {
    typealias MailtoProviderEntry = (name: String, scheme: String, enabled: Bool)
    var mailProviderSource = [MailtoProviderEntry]()

    fileprivate let prefs: Prefs
    fileprivate var currentChoice: String = "mailto"

    fileprivate let BasicCheckmarkCell = "BasicCheckmarkCell"

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsOpenWithSectionName

        tableView.accessibilityIdentifier = "OpenWithPage.Setting.Options"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BasicCheckmarkCell)
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor

        let headerFooterFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.width, height: UIConstants.TableViewHeaderFooterHeight))
        let headerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        headerView.titleLabel.text = Strings.SettingsOpenWithPageTitle
        headerView.showTopBorder = false
        headerView.showBottomBorder = true

        let footerView = SettingsTableSectionHeaderFooterView(frame: headerFooterFrame)
        footerView.showTopBorder = true
        footerView.showBottomBorder = false

        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView

        NotificationCenter.default.addObserver(self, selector: #selector(OpenWithSettingsViewController.appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appDidBecomeActive()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.prefs.setString(currentChoice, forKey: PrefsKeys.KeyMailToOption)
    }

    func appDidBecomeActive() {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: BasicCheckmarkCell, for: indexPath)

        let option = mailProviderSource[indexPath.row]

        cell.textLabel?.attributedText = NSAttributedString.tableRowTitle(option.name)
        cell.accessoryType = (currentChoice == option.scheme && option.enabled) ? .checkmark : .none

        cell.textLabel?.textColor = option.enabled ? UIConstants.TableViewRowTextColor : UIConstants.TableViewDisabledRowTextColor
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
