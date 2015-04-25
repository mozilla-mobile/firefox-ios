/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Base32
import Shared
import UIKit

// A base TableViewCell, to help minimize initialization and allow recycling.
class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        // So that the seperator line goes all the way to the left edge.
        separatorInset = UIEdgeInsetsZero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
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

    var accessoryType: UITableViewCellAccessoryType { return .None }

    // Called when the pref is tapped.
    func onClick(navigationController: UINavigationController?) { return }

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
private class AccountSetting: Setting, FxAContentViewControllerDelegate {
    let settings: SettingsTableViewController
    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var accessoryType: UITableViewCellAccessoryType { return .None }

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

private class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.getAccount() == nil }
}

private class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.getAccount() != nil }
}

// Sync setting for connecting a Firefox Account.  Shown when we don't have an account.
private class ConnectSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Sign in", comment: "Text message / button in the settings table view"))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = FxAContentViewController()
        viewController.delegate = self
        viewController.url = settings.profile.accountConfiguration.signInURL
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// Sync setting for disconnecting a Firefox Account.  Shown when we have an account.
private class DisconnectSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .None }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Disconnect", comment: "Button in settings screen to disconnect from your account"))
    }

    override func onClick(navigationController: UINavigationController?) {
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

// Sync setting that shows the current Firefox Account status.
private class AccountStatusSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

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
                return nil
            case .NeedsVerification:
                return NSAttributedString(string: NSLocalizedString("Verify your email address.", comment: "Text message in the settings table view"))
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

    override func onClick(navigationController: UINavigationController?) {
        let viewController = FxAContentViewController()
        viewController.delegate = self

        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .None, .NeedsVerification:
                let cs = NSURLComponents(URL: account.configuration.settingsURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .NeedsPassword:
                let cs = NSURLComponents(URL: account.configuration.forceAuthURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .NeedsUpgrade:
                // In future, we'll want to link to an upgrade page.
                return
            }
        }

        navigationController?.pushViewController(viewController, animated: true)
    }
}

// Show the current version of Firefox
private class VersionSetting : Setting {
    override var title: NSAttributedString? {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        return NSAttributedString(string: String(format: NSLocalizedString("Version %@ (%@)", comment: "Version number of Firefox shown in settings"), appVersion, buildNumber))
    }
}

// Opens the search settings pane
private class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Search", comment: "Open search section of settings")))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = NSLocalizedString("Clear private data", comment: "Clear private data setting")
        super.init(title: NSAttributedString(string: clearTitle))
    }

    override func onClick(navigationController: UINavigationController?) {
        let clearable = EverythingClearable(profile: profile, tabmanager: tabManager)

        var title: String { return NSLocalizedString("Clear Everything", tableName: "ClearPrivateData", comment: "Clear everything title") }
        var message: String { return NSLocalizedString("Are you sure you want all of your data? This will also close all open tabs.", tableName: "ClearPrivateData", comment: "Message shown in the dialog when clearing everything") }

        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)

        let clearString = NSLocalizedString("Clear", tableName: "ClearPrivateData", comment: "Clicking this button will cause us to clear your private data")
        alert.addAction(UIAlertAction(title: clearString, style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            clearable.clear()
        }))

        let cancelString = NSLocalizedString("Cancel", tableName: "ClearPrivateData", comment: "Cancel string in the clear private data dialog")
        alert.addAction(UIAlertAction(title: cancelString, style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in }))
        navigationController?.presentViewController(alert, animated: true) { () -> Void in }
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

        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")

        settings = [
            SettingSection(title: nil, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                DisconnectSetting(settings: self),
            ]),
            SettingSection(title: NSAttributedString(string: privacyTitle), children: [
                ClearPrivateDataSetting(settings: self)
            ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Search Settings", comment: "Search settings section title")), children: [
                SearchSetting(settings: self)
            ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting()
            ]),
        ]

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: Identifier)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            var cell: UITableViewCell!
            if let status = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = SettingsTableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath) as! UITableViewCell
            }
            cell.detailTextLabel?.attributedText = setting.status
            cell.textLabel?.attributedText = setting.title
            cell.accessoryType = setting.accessoryType
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath) as! UITableViewCell
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
            setting.onClick(navigationController)
        }
        return nil
    }
}
