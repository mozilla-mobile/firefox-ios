/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Base32
import Shared
import UIKit

// A base TableViewCell, to help minimize initialization and allow recycling
class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Prefs use NSAttributedStrings for styling. This is a helper function to make them a bit easier.
private func wrapString(string: String, comment: String) -> NSAttributedString {
    return NSAttributedString(string: NSLocalizedString(string, comment: comment))
}

enum SettingType {
    case ViewController, None
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting {
    private var _title: NSAttributedString?

    // The title shown on the pref
    var title: NSAttributedString? { return _title }

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var type: SettingType { return .None }

    // Called when the pref is tapped. Return true if you handled the tap
    func onClick(navigationController: UINavigationController?) -> Bool { return false }

    init(title: NSAttributedString? = nil) {
        self._title = title
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection : Setting {
    private let children: [Setting]

    init(title: NSAttributedString? = nil, children: [Setting]) {
        self.children = children
        super.init(title: title)
    }

    var count: Int {
        var count = 0
        for setting in children {
            if !setting.hidden {
                count++
            }
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children {
            if !setting.hidden {
                if i == val {
                    return setting
                }
                i++
            }
        }
        return nil
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
private class SyncSetting: Setting, FxAContentViewControllerDelegate {
    let settings: SettingsTableViewController
    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? {
        if let account = settings.profile.getAccount() {
            return wrapString("Disconnect", "Button in settings screen to disconnect from your account")
        }
        return wrapString("Sign in", "Text message / button in the settings table view")
    }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var type: SettingType { return .ViewController }

    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) -> Void {
        if data["keyFetchToken"].asString == nil || data["unwrapBKey"].asString == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data)!
        settings.profile.setAccount(account)

        settings.tableView.reloadData()
        settings.navigationController?.popToRootViewControllerAnimated(true)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        NSLog("didCancel")
        settings.navigationController?.popToRootViewControllerAnimated(true)
    }
}

// Sync setting for connection/disconnecting an FxA Account.
private class ConnectSetting: SyncSetting {
    override var title: NSAttributedString? {
        if let account = settings.profile.getAccount() {
            return wrapString("Disconnect", "Button in settings screen to disconnect from your account")
        }
        return wrapString("Sign in", "Text message / button in the settings table view")
    }

    override func onClick(navigationController: UINavigationController?) -> Bool {
        let viewController = FxAContentViewController()
        viewController.delegate = self
        if let account = settings.profile.getAccount() {
            maybeDisconnectAccount(navigationController)
        } else {
            viewController.url = settings.profile.accountConfiguration.signInURL
        }
        navigationController?.pushViewController(viewController, animated: true)
        return true
    }

    func maybeDisconnectAccount(navigationController: UIViewController?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Disconnect Firefox Account?", comment: "Title of the 'disconnect firefox account' alert"),
            message: NSLocalizedString("Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Text of the 'disconnect firefox account' alert"),
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button in the 'disconnect firefox account' alert"), style: .Cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Disconnect", comment: "Disconnect button in the 'disconnect firefox account' alert"), style: .Destructive) { (action) in
                self.settings.profile.setAccount(nil)
                self.settings.tableView.reloadData()
            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

// Sync setting that shows the current Firefox Account status
private class StatusSetting: SyncSetting {
    override var hidden: Bool {
        if let account = profile.getAccount() {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        if let account = profile.getAccount() {
            return NSAttributedString(string: account.email)
        }
        return nil
    }

    override var status: NSAttributedString? {
        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .None:
                break
            case .NeedsVerification:
                return wrapString("Verify your email address.", "Text message in the settings table view")
            case .NeedsPassword:
                let string = NSLocalizedString("Enter your password to connect.", comment: "Text message in the settings table view")
                let range = NSRange(location: 0, length: count(string))
                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
                let attrs : [NSObject : AnyObject]? = [NSForegroundColorAttributeName : orange]

                let res = NSMutableAttributedString(string: string)
                res.setAttributes(attrs, range: range)
                return res
            case .NeedsUpgrade:
                let string = NSLocalizedString("Upgrade Firefox to connect.", comment: "Text message in the settings table view")
                let range = NSRange(location: 0, length: count(string))
                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
                let attrs : [NSObject : AnyObject]? = [NSForegroundColorAttributeName : orange]

                let res = NSMutableAttributedString(string: string)
                res.setAttributes(attrs, range: range)
                return res
            }
        }
        return nil
    }

    override func onClick(navigationController: UINavigationController?) -> Bool {
        let viewController = FxAContentViewController()
        viewController.delegate = self

        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .None, .NeedsVerification:
                let cs = NSURLComponents(URL: profile.accountConfiguration.settingsURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .NeedsPassword:
                let cs = NSURLComponents(URL: profile.accountConfiguration.forceAuthURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .NeedsUpgrade:
                // In future, we'll want to link to an upgrade page.
                break
            }
        }

        navigationController?.pushViewController(viewController, animated: true)
        return true
    }
}

// Show the current version of Firefox
private class VersionSetting : Setting {
    override var title: NSAttributedString? {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        return wrapString(String(format: "Version %@ (%@)", appVersion, buildNumber), "Version number of Firefox shown in settings")
    }
}

// Opens the search settings pane
private class SearchSetting: Setting {
    let profile: Profile

    override var type: SettingType { return .ViewController }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: wrapString("Search", "Open search section of settings"))
    }

    override func onClick(navigationController: UINavigationController?) -> Bool {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        navigationController?.pushViewController(viewController, animated: true)
        return true
    }
}

private class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    override var type: SettingType { return .ViewController }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: wrapString("Clear private data", "Clear private data setting"))
    }

    override func onClick(navigationController: UINavigationController?) -> Bool {
        var clearable = EverythingClearable(profile: profile, tabmanager: tabManager)
        clearable.clear(navigationController!) { success in
        }
        return true
    }
}

// The base settings view controller.
class SettingsTableViewController: UITableViewController {
    private let Identifier = "CellIdentifier"
    private var settings: [SettingSection]!

    var profile: Profile!
    var tabManager: TabManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        settings = [
            SettingSection(title: nil, children: [
                StatusSetting(settings: self),
                ConnectSetting(settings: self)
            ]),
            SettingSection(title: wrapString("Privacy", "Privacy section title"), children: [
                ClearPrivateDataSetting(settings: self)
            ]),
            SettingSection(title: wrapString("Search Settings", "Search settings section title"), children: [
                SearchSetting(settings: self)
            ]),
            SettingSection(title: wrapString("About", "About settings section title"), children: [
                VersionSetting()
            ])
        ]

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: Identifier)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath) as! UITableViewCell

        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            cell.textLabel?.attributedText = setting.title
            cell.detailTextLabel?.attributedText = setting.status

            // If this setting will show a view controller, show the disclosure icon on the right
            if setting.type == .ViewController {
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.accessoryType = .None
            }
        }

        // So that the seperator line goes all the way to the left edge.
        cell.separatorInset = UIEdgeInsetsZero
        return cell
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = settings[section]
        return section.title?.string
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            if setting.onClick(navigationController) {
                return indexPath
            }
        }
        return nil
    }
}
