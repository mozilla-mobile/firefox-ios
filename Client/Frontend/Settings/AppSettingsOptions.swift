/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account
import SwiftKeychainWrapper
import LocalAuthentication

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

// For great debugging!
class HiddenSetting: Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }
}

// Sync setting for connecting a Firefox Account.  Shown when we don't have an account.
class ConnectSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Sign In to Firefox", comment: "Text message / button in the settings table view"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var accessibilityIdentifier: String? { return "SignInToFirefox" }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = FxAContentViewController()
        viewController.delegate = self
        viewController.url = settings.profile.accountConfiguration.signInURL
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// Sync setting for disconnecting a Firefox Account.  Shown when we have an account.
class DisconnectSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .None }
    override var textAlignment: NSTextAlignment { return .Center }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Log Out", comment: "Button in settings screen to disconnect from your account"), attributes: [NSForegroundColorAttributeName: UIConstants.DestructiveRed])
    }

    override var accessibilityIdentifier: String? { return "LogOut" }

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
                self.settings.settings = self.settings.generateSettings()
                self.settings.SELfirefoxAccountDidChange()
            })
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

class SyncNowSetting: WithAccountSetting {
    static let NotificationUserInitiatedSyncManually = "NotificationUserInitiatedSyncManually"

    private lazy var timestampFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private var syncNowTitle: NSAttributedString {
        return NSAttributedString(
            string: NSLocalizedString("Sync Now", comment: "Sync Firefox Account"),
            attributes: [
                NSForegroundColorAttributeName: self.enabled ? UIColor.blackColor() : UIColor.grayColor(),
                NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont
            ]
        )
    }

    private let syncingTitle = NSAttributedString(string: Strings.SyncingMessageWithEllipsis, attributes: [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultStandardFontSize, weight: UIFontWeightRegular)])

    override var accessoryType: UITableViewCellAccessoryType { return .None }

    override var style: UITableViewCellStyle { return .Value1 }

    override var title: NSAttributedString? {
        if profile.syncManager.isSyncing {
            return syncingTitle
        }
        
        guard let syncStatus = profile.syncManager.syncState else {
            return syncNowTitle
        }

        switch syncStatus {
        case .Bad(let message):
            return NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIColor.redColor(), NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .Stale(let message):
            return  NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIColor.yellowColor(), NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        default:
            return syncNowTitle
        }
    }

    override var status: NSAttributedString? {
        guard let timestamp = profile.syncManager.lastSyncFinishTime else {
            return nil
        }

        let formattedLabel = timestampFormatter.stringFromDate(NSDate.fromTimestamp(timestamp))
        let attributedString = NSMutableAttributedString(string: formattedLabel)
        let attributes = [NSForegroundColorAttributeName: UIColor.grayColor(), NSFontAttributeName: UIFont.systemFontOfSize(12, weight: UIFontWeightRegular)]
        let range = NSMakeRange(0, attributedString.length)
        attributedString.setAttributes(attributes, range: range)
        return attributedString
    }

    override var enabled: Bool {
        return profile.hasSyncableAccount()
    }

    override func onConfigureCell(cell: UITableViewCell) {
        cell.textLabel?.attributedText = title
        cell.detailTextLabel?.attributedText = status
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
        cell.userInteractionEnabled = !profile.syncManager.isSyncing && enabled
        cell.selectionStyle = profile.syncManager.isSyncing ? .None : .Gray
    }

    override func onClick(navigationController: UINavigationController?) {
        NSNotificationCenter.defaultCenter().postNotificationName(SyncNowSetting.NotificationUserInitiatedSyncManually, object: nil)
        profile.syncManager.syncEverything()
    }
}

// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
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
            return NSAttributedString(string: account.email, attributes: [NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
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
class RequirePasswordDebugSetting: WithAccountSetting {
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
class RequireUpgradeDebugSetting: WithAccountSetting {
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
class ForgetSyncAuthStateDebugSetting: WithAccountSetting {
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


class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileManager = NSFileManager.defaultManager()
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(documentsPath)
            for file in files {
                if file.startsWith("browser.") || file.startsWith("logins.") {
                    try fileManager.removeItemInDirectory(documentsPath, named: file)
                }
            }
        } catch {
            print("Couldn't delete exported data: \(error).")
        }
    }
}

class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            let log = Logger.syncLogger
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                log.debug("Matcher: \(file)")
                return file.startsWith("browser.") || file.startsWith("logins.")
            }
        } catch {
            print("Couldn't export browser data: \(error).")
        }
    }
}

// Show the current version of Firefox
class VersionSetting : Setting {
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

    override func onConfigureCell(cell: UITableViewCell) {
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
class LicenseAndAcknowledgementsSetting: Setting {
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
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Your Rights", comment: "Your Rights settings section title"), attributes:
            [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
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

class SendFeedbackSetting: Setting {
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

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?) {
        super.init(
            prefs: prefs, prefKey: "settings.sendUsageData", defaultValue: true,
            attributedTitleText: NSAttributedString(string: NSLocalizedString("Send Anonymous Usage Data", tableName: "SendAnonymousUsageData", comment: "See http://bit.ly/1SmEXU1")),
            attributedStatusText: NSAttributedString(string: NSLocalizedString("More Info…", tableName: "SendAnonymousUsageData", comment: "See http://bit.ly/1SmEXU1"), attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]),
            settingDidChange: { AdjustIntegration.setEnabled($0) }
        )
    }

    override var url: NSURL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?) {
        super.init(title: NSAttributedString(string: NSLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
            delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        navigationController?.dismissViewControllerAnimated(true) {
            if let url = NSURL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}

// Opens the search settings pane
class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    override var accessibilityIdentifier: String? { return "Search" }

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

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate?) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        let loginsTitle = NSLocalizedString("Logins", comment: "Label used as an item in Settings. When touched, the user will be navigated to the Logins/Password manager.")
        super.init(title: NSAttributedString(string: loginsTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    override func onClick(_: UINavigationController?) {
        guard let authInfo = KeychainWrapper.authenticationInfo() else {
            settings?.navigateToLoginsList()
            return
        }

        if authInfo.requiresValidation() {
            AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.loginsTouchReason,
            success: {
                self.settings?.navigateToLoginsList()
            },
            cancel: nil,
            fallback: {
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self.settings)
            })
        } else {
            settings?.navigateToLoginsList()
        }
    }
}

class TouchIDPasscodeSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "TouchIDPasscode" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let title: String
        if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            title = AuthenticationStrings.touchIDPasscodeSetting
        } else {
            title = AuthenticationStrings.passcode
        }
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = AuthenticationSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = Strings.SettingsClearPrivateDataSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class PrivacyPolicySetting: Setting {
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

class ChinaSyncServiceSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .None }
    var prefs: Prefs { return settings.profile.prefs }
    let prefKey = "useChinaSyncService"

    override var title: NSAttributedString? {
        return NSAttributedString(string: "本地同步服务", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "禁用后使用全球服务同步数据", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(ChinaSyncServiceSetting.switchValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        control.on = prefs.boolForKey(prefKey) ?? true
        cell.accessoryView = control
        cell.selectionStyle = .None
    }

    @objc func switchValueChanged(toggle: UISwitch) {
        prefs.setObject(toggle.on, forKey: prefKey)
    }
}

class HomePageSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "HomePageSetting" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        super.init(title: NSAttributedString(string: Strings.SettingsHomePageSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = HomePageSettingsViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }

}
