/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Base32
import Shared
import UIKit
import XCGLogger

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

// The following are only here because we use master for L10N and otherwise these strings would disappear from the v1.0 release
private let Bug1204635_S1 = NSLocalizedString("Clear Everything", tableName: "ClearPrivateData", comment: "Title of the Clear private data dialog.")
private let Bug1204635_S2 = NSLocalizedString("Are you sure you want to clear all of your data? This will also close all open tabs.", tableName: "ClearPrivateData", comment: "Message shown in the dialog prompting users if they want to clear everything")
private let Bug1204635_S3 = NSLocalizedString("Clear", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to Clear private data dialog")
private let Bug1204635_S4 = NSLocalizedString("Cancel", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to cancel clear private data dialog")

// The following are strings for bug 1162174 - Support third party passwords
private let Bug1162174_S1 = NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")

// A base TableViewCell, to help minimize initialization and allow recycling.
class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        // So that the seperator line goes all the way to the left edge.
        separatorInset = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting {
    private var _title: NSAttributedString?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: NSURL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCellStyle { return .Subtitle }

    var accessoryType: UITableViewCellAccessoryType { return .None }

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(cell: UITableViewCell) {
        cell.detailTextLabel?.attributedText = status
        cell.textLabel?.attributedText = title
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
    }

    // Called when the pref is tapped.
    func onClick(navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(navigationController: UINavigationController?) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

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
    unowned var settings: SettingsTableViewController

    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    private override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if settings.profile.getAccount() != nil {
            cell.selectionStyle = .None
        }
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

        // Reload the data to reflect the new Account immediately.
        settings.tableView.reloadData()
        // And start advancing the Account state in the background as well.
        settings.SELrefresh()

        settings.navigationController?.popToRootViewControllerAnimated(true)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        NSLog("didCancel")
        settings.navigationController?.popToRootViewControllerAnimated(true)
    }
}

private class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return !profile.hasAccount() }
}

private class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.hasAccount() }
}

// Sync setting for connecting a Firefox Account.  Shown when we don't have an account.
private class ConnectSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Sign In", comment: "Text message / button in the settings table view"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
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
        return NSAttributedString(string: NSLocalizedString("Log Out", comment: "Button in settings screen to disconnect from your account"), attributes: [NSForegroundColorAttributeName: UIConstants.DestructiveRed])
    }

    override func onClick(navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Log Out?", comment: "Title of the 'log out firefox account' alert"),
            message: NSLocalizedString("Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Text of the 'log out firefox account' alert"),
            preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button in the 'log out firefox account' alert"), style: .Cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Log Out", comment: "Disconnect button in the 'log out firefox account' alert"), style: .Destructive) { (action) in
                self.settings.profile.removeAccount()
                // Refresh, to show that we no longer have an Account immediately.
                self.settings.SELrefresh()
            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

private class SyncNowSetting: WithAccountSetting {
    private let syncNowTitle = NSAttributedString(string: NSLocalizedString("Sync Now", comment: "Sync Firefox Account"), attributes: [NSForegroundColorAttributeName: UIColor.blackColor(), NSFontAttributeName: UIConstants.DefaultStandardFont])

    private let syncingTitle = NSAttributedString(string: NSLocalizedString("Syncing…", comment: "Syncing Firefox Account"), attributes: [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(UIConstants.DefaultStandardFontSize, weight: UIFontWeightRegular)])

    override var accessoryType: UITableViewCellAccessoryType { return .None }

    override var style: UITableViewCellStyle { return .Value1 }

    override var title: NSAttributedString? {
        return profile.syncManager.isSyncing ? syncingTitle : syncNowTitle
    }

    override var status: NSAttributedString? {
        if let timestamp = profile.prefs.timestampForKey(PrefsKeys.KeyLastSyncFinishTime) {
            let label = NSLocalizedString("Last synced: %@", comment: "Last synced time label beside Sync Now setting option. Argument is the relative date string.")
            let formattedLabel = String(format: label, NSDate.fromTimestamp(timestamp).toRelativeTimeString())
            let attributedString = NSMutableAttributedString(string: formattedLabel)
            let attributes = [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)]
            let range = NSMakeRange(0, attributedString.length)
            attributedString.setAttributes(attributes, range: range)
            return attributedString
        }

        return nil
    }

    override func onConfigureCell(cell: UITableViewCell) {
        cell.textLabel?.attributedText = title
        cell.detailTextLabel?.attributedText = status
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
        cell.userInteractionEnabled = !profile.syncManager.isSyncing
    }

    override func onClick(navigationController: UINavigationController?) {
        profile.syncManager.syncEverything()
    }
}

// Sync setting that shows the current Firefox Account status.
private class AccountStatusSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType {
        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .NeedsVerification:
                // We link to the resend verification email page.
                return .DisclosureIndicator
            case .NeedsPassword:
                 // We link to the re-enter password page.
                return .DisclosureIndicator
            case .None, .NeedsUpgrade:
                // In future, we'll want to link to /settings and an upgrade page, respectively.
                return .None
            }
        }
        return .DisclosureIndicator
    }

    override var title: NSAttributedString? {
        if let account = profile.getAccount() {
            return NSAttributedString(string: account.email, attributes: [NSFontAttributeName: UIConstants.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
        }
        return nil
    }

    override var status: NSAttributedString? {
        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .None:
                return nil
            case .NeedsVerification:
                return NSAttributedString(string: NSLocalizedString("Verify your email address.", comment: "Text message in the settings table view"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
            case .NeedsPassword:
                let string = NSLocalizedString("Enter your password to connect.", comment: "Text message in the settings table view")
                let range = NSRange(location: 0, length: string.characters.count)
                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
                let attrs = [NSForegroundColorAttributeName : orange]
                let res = NSMutableAttributedString(string: string)
                res.setAttributes(attrs, range: range)
                return res
            case .NeedsUpgrade:
                let string = NSLocalizedString("Upgrade Firefox to connect.", comment: "Text message in the settings table view")
                let range = NSRange(location: 0, length: string.characters.count)
                let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
                let attrs = [NSForegroundColorAttributeName : orange]
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
            case .NeedsVerification:
                let cs = NSURLComponents(URL: account.configuration.settingsURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .NeedsPassword:
                let cs = NSURLComponents(URL: account.configuration.forceAuthURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(NSURLQueryItem(name: "email", value: account.email))
                viewController.url = cs?.URL
            case .None, .NeedsUpgrade:
                // In future, we'll want to link to /settings and an upgrade page, respectively.
                return
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// For great debugging!
private class RequirePasswordDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
        if let account = profile.getAccount() where account.actionNeeded != FxAActionNeeded.NeedsPassword {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require password", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        profile.getAccount()?.makeSeparated()
        settings.tableView.reloadData()
    }
}


// For great debugging!
private class RequireUpgradeDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
        if let account = profile.getAccount() where account.actionNeeded != FxAActionNeeded.NeedsUpgrade {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require upgrade", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        profile.getAccount()?.makeDoghouse()
        settings.tableView.reloadData()
    }
}

// For great debugging!
private class ForgetSyncAuthStateDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
        if let _ = profile.getAccount() {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: forget Sync auth state", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        profile.getAccount()?.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}

// For great debugging!
private class HiddenSetting: Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }
}

extension NSFileManager {
    public func removeItemInDirectory(directory: String, named: String) throws {
        if let file = NSURL.fileURLWithPath(directory).URLByAppendingPathComponent(named).path {
            try self.removeItemAtPath(file)
        }
    }
}

private class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            try NSFileManager.defaultManager().removeItemInDirectory(documentsPath, named: "browser.db")
        } catch {
            print("Couldn't delete exported data: \(error).")
        }
    }
}

private class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        if let browserDB = NSURL.fileURLWithPath(documentsPath).URLByAppendingPathComponent("browser.db").path {
            do {
                try self.settings.profile.files.copy("browser.db", toAbsolutePath: browserDB)
            } catch {
                print("Couldn't export browser data: \(error).")
            }
        }
    }
}

// Show the current version of Firefox
private class VersionSetting : Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        return NSAttributedString(string: String(format: NSLocalizedString("Version %@ (%@)", comment: "Version number of Firefox shown in settings"), appVersion, buildNumber), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    private override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.selectionStyle = .None
    }

    override func onClick(navigationController: UINavigationController?) {
        if AppConstants.BuildChannel != .Aurora {
            DebugSettingsClickCount += 1
            if DebugSettingsClickCount >= 5 {
                DebugSettingsClickCount = 0
                ShowDebugSettings = !ShowDebugSettings
                settings.tableView.reloadData()
            }
        }
    }
}

// Opens the the license page in a new tab
private class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: WebServer.sharedInstance.URLForResource("license", module: "about"))
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens about:rights page in the content view controller
private class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Your Rights", comment: "Your Rights settings section title"), attributes:
            [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    private override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the on-boarding screen again
private class ShowIntroductionSetting: Setting {
    let profile: Profile

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        navigationController?.dismissViewControllerAnimated(true, completion: {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.browserViewController.presentIntroViewController(true)
            }
        })
    }
}

private class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Send Feedback", comment: "Show an input.mozilla.org page where people can submit feedback"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        return NSURL(string: "https://input.mozilla.org/feedback/fxios/\(appVersion)")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the the SUMO page in a new tab
private class OpenSupportPageSetting: Setting {
    init() {
        super.init(title: NSAttributedString(string: NSLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        navigationController?.dismissViewControllerAnimated(true, completion: {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                let rootNavigationController = appDelegate.rootViewController
                rootNavigationController.popViewControllerAnimated(true)
                if let url = NSURL(string: "https://support.mozilla.org/products/ios") {
                    appDelegate.browserViewController.openURLInNewTab(url)
                }
            }
        })
    }
}

class UseCompactTabLayoutSetting: Setting {
    let profile: Profile

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Use Compact Tabs", comment: "Setting to enable compact tabs in the tab overview"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        control.on = profile.prefs.boolForKey("CompactTabLayout") ?? true
        cell.accessoryView = control
        cell.selectionStyle = .None
    }

    @objc func switchValueChanged(control: UISwitch) {
        profile.prefs.setBool(control.on, forKey: "CompactTabLayout")
    }
}

// Opens the search settings pane
private class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Search", comment: "Open search section of settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
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

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = NSLocalizedString("Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private class SendCrashReportsSetting: Setting {
    let profile: Profile

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Send Crash Reports", comment: "Setting to enable the sending of crash reports"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        control.on = profile.prefs.boolForKey("crashreports.send.always") ?? false
        cell.accessoryView = control
    }

    @objc func switchValueChanged(control: UISwitch) {
        profile.prefs.setBool(control.on, forKey: "crashreports.send.always")
        configureActiveCrashReporter(profile.prefs.boolForKey("crashreports.send.always"))
    }
}

private class ClosePrivateTabs: Setting {
    let profile: Profile

    private let titleText = NSLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs")
    private let statusText =
        NSLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'")

    override var status: NSAttributedString? {
        return NSAttributedString(string: statusText, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: titleText, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        control.on = profile.prefs.boolForKey("settings.closePrivateTabs") ?? false
        cell.accessoryView = control
    }

    @objc func switchValueChanged(control: UISwitch) {
        profile.prefs.setBool(control.on, forKey: "settings.closePrivateTabs")
        configureActiveCrashReporter(profile.prefs.boolForKey("settings.closePrivateTabs"))
    }
}

private class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

private class PopupBlockingSettings: Setting {
    let prefs: Prefs
    let tabManager: TabManager!

    let prefKey = "blockPopups"

    init(settings: SettingsTableViewController) {
        self.prefs = settings.profile.prefs
        self.tabManager = settings.tabManager
        let title = NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")
        let attributes = [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]
        super.init(title: NSAttributedString(string: title, attributes: attributes))
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        control.on = prefs.boolForKey(prefKey) ?? true
        cell.accessoryView = control
        cell.selectionStyle = .None
    }

    @objc func switchValueChanged(toggle: UISwitch) {
        prefs.setObject(toggle.on, forKey: prefKey)
    }
}

// The base settings view controller.
class SettingsTableViewController: UITableViewController {
    private let Identifier = "CellIdentifier"
    private let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    private var settings = [SettingSection]()

    var profile: Profile!
    var tabManager: TabManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")
        let accountDebugSettings: [Setting]
        if AppConstants.BuildChannel != .Aurora {
            accountDebugSettings = [
                // Debug settings:
                RequirePasswordDebugSetting(settings: self),
                RequireUpgradeDebugSetting(settings: self),
                ForgetSyncAuthStateDebugSetting(settings: self),
            ]
        } else {
            accountDebugSettings = []
        }

        var generalSettings = [
            SearchSetting(settings: self),
            PopupBlockingSettings(settings: self),
        ]

        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            generalSettings +=  [UseCompactTabLayoutSetting(settings: self)]
        }

        settings += [
            SettingSection(title: nil, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                SyncNowSetting(settings: self)
            ] + accountDebugSettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("General", comment: "General settings section title")), children: generalSettings)
        ]

        var privacySettings: [Setting]
        if #available(iOS 9, *) {
            privacySettings = [
                ClearPrivateDataSetting(settings: self),
                ClosePrivateTabs(settings: self),
                SendCrashReportsSetting(settings: self),
                PrivacyPolicySetting()
            ]
        } else {
            privacySettings = [
                ClearPrivateDataSetting(settings: self),
                SendCrashReportsSetting(settings: self),
                PrivacyPolicySetting()
            ]
        }

        settings += [
            SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                ShowIntroductionSetting(settings: self),
                SendFeedbackSetting(),
                OpenSupportPageSetting()
            ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
                YourRightsSetting(),
                DisconnectSetting(settings: self),
                ExportBrowserDataSetting(settings: self),
                DeleteExportedDataSetting(settings: self),
            ])
        ]

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.registerClass(SettingsTableSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)
        tableView.tableFooterView = SettingsTableFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 128))

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELsyncDidChangeState", name: ProfileDidStartSyncingNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELsyncDidChangeState", name: ProfileDidFinishSyncingNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        SELrefresh()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ProfileDidStartSyncingNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ProfileDidFinishSyncingNotification, object: nil)
    }

    @objc private func SELsyncDidChangeState() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    @objc private func SELrefresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        if let account = self.profile.getAccount() {
            account.advance().upon { _ in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.reloadData()
        }
    }

    // MARK: Bluetooth Keyboard Shortcuts

    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override var keyCommands: [AnyObject]? {
        get {
            return [
                UIKeyCommand(input: "t", modifierFlags: .Command, action: "openNewTab"), // CMD+T
                UIKeyCommand(input: "b", modifierFlags: .Command, action: "openNewTab") // CMD+N
            ]
        }
    }

    func openNewTab() {
        navigationController?.dismissViewControllerAnimated(true, completion: {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                let rootNavigationController = appDelegate.rootViewController
                rootNavigationController.popViewControllerAnimated(true)
                appDelegate.browserViewController.openNewTab()
            }
        })
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            var cell: UITableViewCell!
            if let _ = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = SettingsTableViewCell(style: setting.style, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
            }
            setting.onConfigureCell(cell)
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderIdentifier) as! SettingsTableSectionHeaderView
        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle
        }

        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        return headerView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // empty headers should be 13px high, but headers with text should be 44
        var height: CGFloat = 13
        let section = settings[section]
        if let sectionTitle = section.title {
            if sectionTitle.length > 0 {
                height = 44
            }
        }
        return height
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            setting.onClick(navigationController)
        }
        return nil
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //make account/sign-in and close private tabs rows taller, as per design specs
        if indexPath.section == 0 && indexPath.row == 0 {
            return 64
        }

        if #available(iOS 9, *) {
            if indexPath.section == 2 && indexPath.row == 1 {
                return 64
            }
        }

        return 44
    }
}

class SettingsTableFooterView: UIView {
    var logo: UIImageView = {
        var image =  UIImageView(image: UIImage(named: "settingsFlatfox"))
        image.contentMode = UIViewContentMode.Center
        return image
    }()

    private lazy var topBorder: CALayer = {
        let topBorder = CALayer()
        topBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return topBorder
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        layer.addSublayer(topBorder)
        addSubview(logo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topBorder.frame = CGRectMake(0.0, 0.0, frame.size.width, 0.5)
        logo.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    }
}

class SettingsTableSectionHeaderView: UITableViewHeaderFooterView {
    var showTopBorder: Bool = true {
        didSet {
            topBorder.hidden = !showTopBorder
        }
    }

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.hidden = !showBottomBorder
        }
    }

    var titleLabel: UILabel = {
        var headerLabel = UILabel()
        var frame = headerLabel.frame
        frame.origin.x = 15
        frame.origin.y = 25
        headerLabel.frame = frame
        headerLabel.textColor = UIConstants.TableViewHeaderTextColor
        headerLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
        return headerLabel
    }()

    private lazy var topBorder: CALayer = {
        let topBorder = CALayer()
        topBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return topBorder
    }()

    private lazy var bottomBorder: CALayer = {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return bottomBorder
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        addSubview(titleLabel)
        clipsToBounds = true
        layer.addSublayer(topBorder)
        layer.addSublayer(bottomBorder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomBorder.frame = CGRectMake(0.0, frame.size.height - 0.5, frame.size.width, 0.5)
        topBorder.frame = CGRectMake(0.0, 0.0, frame.size.width, 0.5)
        titleLabel.sizeToFit()
    }
}
