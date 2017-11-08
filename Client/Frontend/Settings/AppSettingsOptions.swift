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
    unowned let settings: SettingsTableViewController

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
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.FxASignIntoSync, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var accessibilityIdentifier: String? { return "SignInToSync" }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAContentViewController(profile: profile)
        viewController.delegate = self
        viewController.url = settings.profile.accountConfiguration.signInURL
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            let image = UIImage(named: "FxA-Default")
            cell.imageView?.image = image?.createScaled(CGSize(width: 30, height: 30))
            cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)! / 2
            cell.imageView?.layer.masksToBounds = true
        }
    }
}

// Sync setting for disconnecting a Firefox Account.  Shown when we have an account.
class DisconnectSetting: WithAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    override var textAlignment: NSTextAlignment { return .center }

    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.SettingsDisconnectSyncButton, attributes: [NSForegroundColorAttributeName: UIConstants.DestructiveRed])
    }

    override var accessibilityIdentifier: String? { return "SignOut" }

    override func onClick(_ navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: Strings.SettingsDisconnectSyncAlertTitle,
            message: NSLocalizedString("Firefox will stop syncing with your account, but won’t delete any of your browsing data on this device.", comment: "Text of the 'sign out firefox account' alert"),
            preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel) { (action) in
                // Do nothing.
            })
        alertController.addAction(
            UIAlertAction(title: Strings.SettingsDisconnectDestructiveAction, style: .destructive) { (action) in
                FxALoginHelper.sharedInstance.applicationDidDisconnect(UIApplication.shared)
                self.settings.settings = self.settings.generateSettings()
                self.settings.SELfirefoxAccountDidChange()

                LeanplumIntegration.sharedInstance.setUserAttributes(attributes: [UserAttributeKeyName.signedInSync.rawValue: self.profile.hasAccount()])
            })
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

class SyncNowSetting: WithAccountSetting {
    static let NotificationUserInitiatedSyncManually = "NotificationUserInitiatedSyncManually"
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    let syncIconWrapper = UIImage.createWithColor(CGSize(width: 30, height: 30), color: UIColor.clear)
    let syncBlueIcon = UIImage(named: "FxA-Sync-Blue")?.createScaled(CGSize(width: 20, height: 20))
    let syncIcon = UIImage(named: "FxA-Sync")?.createScaled(CGSize(width: 20, height: 20))
    
    // Animation used to rotate the Sync icon 360 degrees while syncing is in progress.
    let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    
    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncNowSetting.stopRotateSyncIcon), name: NotificationProfileDidFinishSyncing, object: nil)
    }
    
    fileprivate lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    fileprivate var syncNowTitle: NSAttributedString {
        if !DeviceInfo.hasConnectivity() {
            return NSAttributedString(
                string: Strings.FxANoInternetConnection,
                attributes: [
                    NSForegroundColorAttributeName: UIColor.red,
                    NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultMediumFont
                ]
            )
        }
        
        return NSAttributedString(
            string: NSLocalizedString("Sync Now", comment: "Sync Firefox Account"),
            attributes: [
                NSForegroundColorAttributeName: self.enabled ? UIConstants.TableViewRowSyncTextColor : UIColor.gray,
                NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont
            ]
        )
    }

    fileprivate let syncingTitle = NSAttributedString(string: Strings.SyncingMessageWithEllipsis, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowSyncTextColor, NSFontAttributeName: UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultStandardFontSize, weight: UIFontWeightRegular)])

    func startRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.add(self.continuousRotateAnimation, forKey: "rotateKey")
        }
    }
    
    func stopRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.removeAllAnimations()
        }
    }

    override var accessoryType: UITableViewCellAccessoryType { return .none }

    override var style: UITableViewCellStyle { return .value1 }
    
    override var image: UIImage? {
        if !AppConstants.MOZ_SHOW_FXA_AVATAR {
            return nil
        }
        
        guard let syncStatus = profile.syncManager.syncDisplayState else {
            return syncIcon
        }
        
        switch syncStatus {
        case .inProgress:
            return syncBlueIcon
        default:
            return syncIcon
        }
    }

    override var title: NSAttributedString? {
        guard let syncStatus = profile.syncManager.syncDisplayState else {
            return syncNowTitle
        }

        switch syncStatus {
        case .bad(let message):
            guard let message = message else { return syncNowTitle }
            return NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowErrorTextColor, NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .warning(let message):
            return  NSAttributedString(string: message, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowWarningTextColor, NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .inProgress:
            return syncingTitle
        default:
            return syncNowTitle
        }
    }

    override var status: NSAttributedString? {
        guard let timestamp = profile.syncManager.lastSyncFinishTime else {
            return nil
        }

        let formattedLabel = timestampFormatter.string(from: Date.fromTimestamp(timestamp))
        let attributedString = NSMutableAttributedString(string: formattedLabel)
        let attributes = [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)]
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.setAttributes(attributes, range: range)
        return attributedString
    }

    override var enabled: Bool {
        if !DeviceInfo.hasConnectivity() {
            return false
        }

        return profile.hasSyncableAccount()
    }

    fileprivate lazy var troubleshootButton: UIButton = {
        let troubleshootButton = UIButton(type: UIButtonType.roundedRect)
        troubleshootButton.setTitle(Strings.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.tintColor = UIConstants.TableViewRowActionAccessoryColor
        troubleshootButton.titleLabel?.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        troubleshootButton.sizeToFit()
        return troubleshootButton
    }()

    fileprivate lazy var warningIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AmberCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    fileprivate lazy var errorIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "RedCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    fileprivate let syncSUMOURL = SupportUtils.URLForTopic("sync-status-ios")

    @objc fileprivate func troubleshoot() {
        let viewController = SettingsContentViewController()
        viewController.url = syncSUMOURL
        settings.navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        cell.textLabel?.attributedText = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let syncStatus = profile.syncManager.syncDisplayState {
            switch syncStatus {
            case .bad(let message):
                if let _ = message {
                    // add the red warning symbol
                    // add a link to the MANA page
                    cell.detailTextLabel?.attributedText = nil
                    cell.accessoryView = troubleshootButton
                    addIcon(errorIcon, toCell: cell)
                } else {
                    cell.detailTextLabel?.attributedText = status
                    cell.accessoryView = nil
                }
            case .warning(_):
                // add the amber warning symbol
                // add a link to the MANA page
                cell.detailTextLabel?.attributedText = nil
                cell.accessoryView = troubleshootButton
                addIcon(warningIcon, toCell: cell)
            case .good:
                cell.detailTextLabel?.attributedText = status
                fallthrough
            default:
                cell.accessoryView = nil
            }
        } else {
            cell.accessoryView = nil
        }
        cell.accessoryType = accessoryType
        cell.isUserInteractionEnabled = !profile.syncManager.isSyncing && DeviceInfo.hasConnectivity()
        
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            // Animation that loops continously until stopped
            continuousRotateAnimation.fromValue = 0.0
            continuousRotateAnimation.toValue = CGFloat(Double.pi)
            continuousRotateAnimation.isRemovedOnCompletion = true
            continuousRotateAnimation.duration = 0.5
            continuousRotateAnimation.repeatCount = Float.infinity
            
            // To ensure sync icon is aligned properly with user's avatar, an image is created with proper
            // dimensions and color, then the scaled sync icon is added as a subview.
            imageView.contentMode = .center
            imageView.image = image
            
            cell.imageView?.subviews.forEach({ $0.removeFromSuperview() })
            cell.imageView?.image = syncIconWrapper
            cell.imageView?.addSubview(imageView)
            
            if let syncStatus = profile.syncManager.syncDisplayState {
                switch syncStatus {
                case .inProgress:
                    self.startRotateSyncIcon()
                default:
                    self.stopRotateSyncIcon()
                }
            }
        }
    }

    fileprivate func addIcon(_ image: UIImageView, toCell cell: UITableViewCell) {
        cell.contentView.addSubview(image)

        cell.textLabel?.snp.updateConstraints { make in
            make.leading.equalTo(image.snp.trailing).offset(5)
            make.trailing.lessThanOrEqualTo(cell.contentView)
            make.centerY.equalTo(cell.contentView)
        }

        image.snp.makeConstraints { make in
            make.leading.equalTo(cell.contentView).offset(17)
            make.top.equalTo(cell.textLabel!).offset(2)
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if !DeviceInfo.hasConnectivity() {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: SyncNowSetting.NotificationUserInitiatedSyncManually), object: nil)
        profile.syncManager.syncEverything(why: .syncNow)
    }
}

// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(AccountStatusSetting.updateAccount(notification:)), name: NotificationFirefoxAccountProfileChanged, object: nil)
    }
    
    func updateAccount(notification: Notification) {
        DispatchQueue.main.async {
            self.settings.tableView.reloadData()
        }
    }
    
    override var image: UIImage? {
        if !AppConstants.MOZ_SHOW_FXA_AVATAR {
            return nil
        }
        
        if let image = profile.getAccount()?.fxaProfile?.avatar.image {
            return image.createScaled(CGSize(width: 30, height: 30))
        }
        
        let image = UIImage(named: "placeholder-avatar")
        return image?.createScaled(CGSize(width: 30, height: 30))
    }
    
    override var accessoryType: UITableViewCellAccessoryType {
        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .needsVerification:
                // We link to the resend verification email page.
                return .disclosureIndicator
            case .needsPassword:
                 // We link to the re-enter password page.
                return .disclosureIndicator
            case .none:
                // We link to FxA web /settings.
                return .disclosureIndicator
            case .needsUpgrade:
                // In future, we'll want to link to an upgrade page.
                return .none
            }
        }
        return .disclosureIndicator
    }

    override var title: NSAttributedString? {
        if let account = profile.getAccount() {
            
            if let displayName = account.fxaProfile?.displayName {
                return NSAttributedString(string: displayName, attributes: [NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowSyncTextColor])
            }
            
            if let email = account.fxaProfile?.email {
                return NSAttributedString(string: email, attributes: [NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowSyncTextColor])
            }
            
            return NSAttributedString(string: account.email, attributes: [NSFontAttributeName: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSForegroundColorAttributeName: UIConstants.TableViewRowSyncTextColor])
        }
        return nil
    }

    override var status: NSAttributedString? {
        if let account = profile.getAccount() {
            var string: String
            
            switch account.actionNeeded {
            case .none:
                return nil
            case .needsVerification:
                string = NSLocalizedString("Verify your email address.", comment: "Text message in the settings table view")
                break
            case .needsPassword:
                string = NSLocalizedString("Enter your password to connect.", comment: "Text message in the settings table view")
                break
            case .needsUpgrade:
                string = NSLocalizedString("Upgrade Firefox to connect.", comment: "Text message in the settings table view")
                break
            }
            
            let orange = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
            let range = NSRange(location: 0, length: string.characters.count)
            let attrs = [NSForegroundColorAttributeName: orange]
            let res = NSMutableAttributedString(string: string)
            res.setAttributes(attrs, range: range)
            return res
        }
        return nil
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAContentViewController(profile: profile)
        viewController.delegate = self

        if let account = profile.getAccount() {
            switch account.actionNeeded {
            case .none, .needsVerification:
                var cs = URLComponents(url: account.configuration.settingsURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(URLQueryItem(name: "email", value: account.email))
                if let url = try? cs?.asURL() {
                    viewController.url = url
                }
            case .needsPassword:
                var cs = URLComponents(url: account.configuration.forceAuthURL, resolvingAgainstBaseURL: false)
                cs?.queryItems?.append(URLQueryItem(name: "email", value: account.email))
                if let url = try? cs?.asURL() {
                    viewController.url = url
                }
            case .needsUpgrade:
                // In future, we'll want to link to an upgrade page.
                return
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            cell.imageView?.subviews.forEach({ $0.removeFromSuperview() })
            cell.imageView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.height)! / 2
            cell.imageView?.layer.masksToBounds = true
            cell.imageView?.image = image
        }
    }
}

// For great debugging!
class RequirePasswordDebugSetting: WithAccountSetting {
    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
        if let account = profile.getAccount(), account.actionNeeded != FxAActionNeeded.needsPassword {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require password", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
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
        if let account = profile.getAccount(), account.actionNeeded != FxAActionNeeded.needsUpgrade {
            return false
        }
        return true
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: require upgrade", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
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

    override func onClick(_ navigationController: UINavigationController?) {
        profile.getAccount()?.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}

class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsPath)
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

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let log = Logger.syncLogger
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                log.debug("Matcher: \(file)")
                return file.startsWith("browser.") || file.startsWith("logins.") || file.startsWith("metadata.")
            }
        } catch {
            print("Couldn't export browser data: \(error).")
        }
    }
}

/*
 FeatureSwitchSetting is a boolean switch for features that are enabled via a FeatureSwitch.
 These are usually features behind a partial release and not features released to the entire population.
 */
class FeatureSwitchSetting: BoolSetting {
    let featureSwitch: FeatureSwitch
    let prefs: Prefs

    init(prefs: Prefs, featureSwitch: FeatureSwitch, with title: NSAttributedString) {
        self.featureSwitch = featureSwitch
        self.prefs = prefs
        super.init(prefs: prefs, defaultValue: featureSwitch.isMember(prefs), attributedTitleText: title)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }

    override func displayBool(_ control: UISwitch) {
        control.isOn = featureSwitch.isMember(prefs)
    }

    override func writeBool(_ control: UISwitch) {
        self.featureSwitch.setMembership(control.isOn, for: self.prefs)
    }

}

class EnableBookmarkMergingSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Enable Bidirectional Bookmark Sync ", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        AppConstants.shouldMergeBookmarks = true
    }
}

class ForceCrashSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Force Crash", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Sentry.shared.crash()
    }
}

// Show the current version of Firefox
class VersionSetting: Setting {
    unowned let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return NSAttributedString(string: String(format: NSLocalizedString("Version %@ (%@)", comment: "Version number of Firefox shown in settings"), appVersion, buildNumber), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DebugSettingsClickCount += 1
        if DebugSettingsClickCount >= 5 {
            DebugSettingsClickCount = 0
            ShowDebugSettings = !ShowDebugSettings
            settings.tableView.reloadData()
        }
    }
}

// Opens the the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        return URL(string: WebServer.sharedInstance.URLForResource("license", module: "about"))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Your Rights", comment: "Your Rights settings section title"), attributes:
            [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ShowTour" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Show Tour", comment: "Show the on-boarding screen again from the settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.browserViewController.presentIntroViewController(true)
            }
        })
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Send Feedback", comment: "Menu item in settings used to open input.mozilla.org where people can submit feedback"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: URL? {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        return URL(string: "https://input.mozilla.org/feedback/fxios/\(appVersion)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?) {
        super.init(
            prefs: prefs, prefKey: AppConstants.PrefSendUsageData, defaultValue: true,
            attributedTitleText: NSAttributedString(string: Strings.SendUsageSettingTitle),
            attributedStatusText: createStatusText(),
            settingDidChange: {
                AdjustIntegration.setEnabled($0)
                LeanplumIntegration.sharedInstance.setUserAttributes(attributes: [UserAttributeKeyName.telemetryOptIn.rawValue: $0])
                LeanplumIntegration.sharedInstance.setEnabled($0)
            }
        )
    }

    private func createStatusText() -> NSAttributedString {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: Strings.SendUsageSettingMessage, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: Strings.SendUsageSettingLink, attributes: [NSForegroundColorAttributeName: UIConstants.HighlightBlue]))
        return statusText
    }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?) {
        super.init(title: NSAttributedString(string: NSLocalizedString("Help", comment: "Show the SUMO support page from the Support section in the settings. see http://mzl.la/1dmM8tZ"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
            delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}

// Opens the search settings pane
class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var style: UITableViewCellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Search", comment: "Open search section of settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class SyncSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "Sync" }

    override var hidden: Bool { return !(profile.hasAccount() && profile.hasSyncableAccount() && profile.syncManager.lastSyncFinishTime != nil) }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: Strings.SettingsSyncSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SyncContentSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

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

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        guard let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() else {
            settings?.navigateToLoginsList()
            LeanplumIntegration.sharedInstance.track(eventName: .openedLogins)
            return
        }

        if authInfo.requiresValidation() {
            AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.loginsTouchReason,
            success: {
                self.settings?.navigateToLoginsList()
                LeanplumIntegration.sharedInstance.track(eventName: .openedLogins)
            },
            cancel: {
                self.deselectRow()
            },
            fallback: {
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self.settings)
                self.deselectRow()
            })
        } else {
            settings?.navigateToLoginsList()
            LeanplumIntegration.sharedInstance.track(eventName: .openedLogins)
        }
    }
}

class TouchIDPasscodeSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "TouchIDPasscode" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate? = nil) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        let localAuthContext = LAContext()

        let title: String
        if localAuthContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            if #available(iOS 11.0, *), localAuthContext.biometryType == .typeFaceID {
                title = AuthenticationStrings.faceIDPasscodeSetting
            } else {
                title = AuthenticationStrings.touchIDPasscodeSetting
            }
        } else {
            title = AuthenticationStrings.passcode
        }
        super.init(title: NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AuthenticationSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

@available(iOS 11, *)
class ContentBlockerSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    override var accessibilityIdentifier: String? { return "TrackingProtection" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: NSAttributedString(string: Strings.SettingsTrackingProtectionSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = Strings.SettingsClearPrivateDataSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
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

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

class ChinaSyncServiceSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    var prefs: Prefs { return settings.profile.prefs }
    let prefKey = "useChinaSyncService"

    override var title: NSAttributedString? {
        return NSAttributedString(string: "本地同步服务", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "禁用后使用全球服务同步数据", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(ChinaSyncServiceSetting.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? self.profile.isChinaEdition
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        prefs.setObject(toggle.isOn, forKey: prefKey)
    }
}

class StageSyncServiceDebugSetting: WithoutAccountSetting {
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    var prefs: Prefs { return settings.profile.prefs }

    var prefKey: String = "useStageSyncService"

    override var hidden: Bool {
        if !ShowDebugSettings {
            return true
        }
        if let _ = profile.getAccount() {
            return true
        }
        return false
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Debug: use stage servers", comment: "Debug option"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var status: NSAttributedString? {
        // Derive the configuration we display from the profile. Currently, this could be either a custom
        // FxA server or FxA stage servers.
        let isOn = prefs.boolForKey(prefKey) ?? false
        let isCustomSync = prefs.boolForKey(PrefsKeys.KeyUseCustomSyncService) ?? false
        
        var configurationURL = ProductionFirefoxAccountConfiguration().authEndpointURL
        if isCustomSync {
            configurationURL = CustomFirefoxAccountConfiguration(prefs: profile.prefs).authEndpointURL
        } else if isOn {
            configurationURL = StageFirefoxAccountConfiguration().authEndpointURL
        }

        return NSAttributedString(string: configurationURL.absoluteString, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: #selector(StageSyncServiceDebugSetting.switchValueChanged(_:)), for: UIControlEvents.valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? false
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        prefs.setObject(toggle.isOn, forKey: prefKey)
        settings.tableView.reloadData()
    }
}

class HomePageSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "Homepage" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        super.init(title: NSAttributedString(string: Strings.SettingsHomePageSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HomePageSettingsViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NewTabPageSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "NewTab" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: Strings.SettingsNewTabSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabContentSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class OpenWithSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "OpenWith.Setting" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: Strings.SettingsOpenWithSectionName, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AdvanceAccountSetting: HiddenSetting {
    let profile: Profile
    
    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }
    
    override var accessibilityIdentifier: String? { return "AdvanceAccount.Setting" }
    
    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.SettingsAdvanceAccountTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    
    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }
    
    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AdvanceAccountSettingViewController()        
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    override var hidden: Bool {
        return !ShowDebugSettings || profile.hasAccount()
    }
}
