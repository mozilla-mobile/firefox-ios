// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Account
import SwiftKeychainWrapper
import LocalAuthentication
import Glean

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

private var disclosureIndicator: UIImageView {
    let disclosureIndicator = UIImageView()
    disclosureIndicator.image = UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate)
    disclosureIndicator.tintColor = UIColor.theme.tableView.accessoryViewTint
    disclosureIndicator.sizeToFit()
    return disclosureIndicator
}

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
    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .FxASignInToSync, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var accessibilityIdentifier: String? { return "SignInToSync" }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: nil)
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: .settings)
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.imageView?.image = UIImage.templateImageNamed("FxA-Default")
        cell.imageView?.tintColor = UIColor.theme.tableView.disabledRowText
        cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)! / 2
        cell.imageView?.layer.masksToBounds = true
    }
}

class SyncNowSetting: WithAccountSetting {
    let imageView = UIImageView(frame: CGRect(width: 30, height: 30))
    let syncIconWrapper = UIImage.createWithColor(CGSize(width: 30, height: 30), color: UIColor.clear)
    let syncBlueIcon = UIImage(named: "FxA-Sync-Blue")
    let syncIcon: UIImage? = {
        let image = UIImage(named: "FxA-Sync")
        return LegacyThemeManager.instance.currentName == .dark ? image?.tinted(withColor: .white) : image
    }()

    // Animation used to rotate the Sync icon 360 degrees while syncing is in progress.
    let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidFinishSyncing, object: nil)
    }

    fileprivate lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    fileprivate var syncNowTitle: NSAttributedString {
        if !DeviceInfo.hasConnectivity() {
            return NSAttributedString(
                string: .FxANoInternetConnection,
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.errorText,
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultMediumFont
                ]
            )
        }

        return NSAttributedString(
            string: .FxASyncNow,
            attributes: [
                NSAttributedString.Key.foregroundColor: self.enabled ? UIColor.theme.tableView.syncText : UIColor.theme.tableView.headerTextLight,
                NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont
            ]
        )
    }

    fileprivate let syncingTitle = NSAttributedString(string: .SyncingMessageWithEllipsis, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.syncText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultStandardFontSize, weight: UIFont.Weight.regular)])

    func startRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.add(self.continuousRotateAnimation, forKey: "rotateKey")
        }
    }

    @objc func stopRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.removeAllAnimations()
        }
    }

    override var accessoryType: UITableViewCell.AccessoryType { return .none }

    override var image: UIImage? {
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
            return NSAttributedString(string: message, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.errorText, NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .warning(let message):
            return  NSAttributedString(string: message, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.warningText, NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont])
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
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.headerTextLight, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)]
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.setAttributes(attributes, range: range)
        return attributedString
    }

    override var hidden: Bool { return !enabled }

    override var enabled: Bool {
        get {
            if !DeviceInfo.hasConnectivity() {
                return false
            }

            return profile.hasSyncableAccount()
        }
        set {
        }
    }

    fileprivate lazy var troubleshootButton: UIButton = {
        let troubleshootButton = UIButton(type: .roundedRect)
        troubleshootButton.setTitle(.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.tintColor = UIColor.theme.tableView.rowActionAccessory
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

        // Animation that loops continously until stopped
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(Double.pi)
        continuousRotateAnimation.isRemovedOnCompletion = true
        continuousRotateAnimation.duration = 0.5
        continuousRotateAnimation.repeatCount = .infinity

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

        NotificationCenter.default.post(name: .UserInitiatedSyncManually, object: nil)
        profile.syncManager.syncEverything(why: .syncNow)
    }
}

// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAccount), name: .FirefoxAccountProfileChanged, object: nil)
    }

    @objc func updateAccount(notification: Notification) {
        DispatchQueue.main.async {
            self.settings.tableView.reloadData()
        }
    }

    override var accessoryView: UIImageView? {
        return disclosureIndicator
    }

    override var title: NSAttributedString? {
        if let displayName = RustFirefoxAccounts.shared.userProfile?.displayName {
            return NSAttributedString(string: displayName, attributes: [NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.syncText])
        }

        if let email = RustFirefoxAccounts.shared.userProfile?.email {
            return NSAttributedString(string: email, attributes: [NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFontBold, NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.syncText])
        }

        return nil
    }

    override var status: NSAttributedString? {
        if RustFirefoxAccounts.shared.isActionNeeded {
            let string: String = .FxAAccountVerifyPassword
            let orange = UIColor.theme.tableView.warningText
            let range = NSRange(location: 0, length: string.count)
            let attrs = [NSAttributedString.Key.foregroundColor: orange]
            let res = NSMutableAttributedString(string: string)
            res.setAttributes(attrs, range: range)
            return res
        }
        return nil
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard !profile.rustFxA.accountNeedsReauth() else {
            let vc = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: nil)
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: .settings)
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        let viewController = SyncContentSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if let imageView = cell.imageView {
            imageView.subviews.forEach({ $0.removeFromSuperview() })
            imageView.frame = CGRect(width: 30, height: 30)
            imageView.layer.cornerRadius = (imageView.frame.height) / 2
            imageView.layer.masksToBounds = true

            imageView.image = UIImage(named: "placeholder-avatar")!.createScaled(CGSize(width: 30, height: 30))

            RustFirefoxAccounts.shared.avatar?.image.uponQueue(.main) { image in
                imageView.image = image.createScaled(CGSize(width: 30, height: 30))
            }
        }
    }
}

class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: documentsPath)
            for file in files {
                if file.hasPrefix("browser.") || file.hasPrefix("logins.") {
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
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let log = Logger.syncLogger
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                log.debug("Matcher: \(file)")
                return file.hasPrefix("browser.") || file.hasPrefix("logins.") || file.hasPrefix("metadata.")
            }
        } catch {
            print("Couldn't export browser data: \(error).")
        }
    }
}

class ExportLogDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy log files to app container", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Logger.copyPreviousLogsToDocuments()
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

class ForceCrashSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: Force Crash", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        Sentry.shared.crash()
    }
}

class ChangeToChinaSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: toggle China version (needs restart)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if UserDefaults.standard.bool(forKey: debugPrefIsChinaEdition) {
            UserDefaults.standard.removeObject(forKey: debugPrefIsChinaEdition)
        } else {
            UserDefaults.standard.set(true, forKey: debugPrefIsChinaEdition)
        }
    }
}

class SlowTheDatabase: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: simulate slow database operations", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        debugSimulateSlowDBOperations = !debugSimulateSlowDBOperations
    }
}

class ForgetSyncAuthStateDebugSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: forget Sync auth state", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile.rustFxA.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}

class SentryIDSetting: HiddenSetting {
    let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: "SentryDeviceAppHash") ?? "0000000000000000000000000000000000000000"
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Sentry ID: \(deviceAppHash)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        copyAppDeviceIDAndPresentAlert(by: navigationController)
    }

    func copyAppDeviceIDAndPresentAlert(by navigationController: UINavigationController?) {
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        getSelectedCell(by: navigationController)?.setSelected(false, animated: true)
        UIPasteboard.general.string = deviceAppHash
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func getSelectedCell(by navigationController: UINavigationController?) -> UITableViewCell? {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return tableView?.cellForRow(at: indexPath)
    }
}

class ShowEtpCoverSheet: HiddenSetting {
    let profile: Profile

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: ETP Cover Sheet On", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        BrowserViewController.foregroundBVC().hasTriedToPresentETPAlready = false
        // ETP is shown when user opens app for 3rd time on clean install.
        // Hence setting session to 2 (0,1,2) for 3rd install as it starts from 0 being 1st session
        self.profile.prefs.setInt(2, forKey: PrefsKeys.KeyInstallSession)
        self.profile.prefs.setString(ETPCoverSheetShowType.CleanInstall.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
    }
}

class ExperimentsSettings: HiddenSetting {
    override var title: NSAttributedString? { return NSAttributedString(string: "Experiments")}

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ExperimentsViewController(), animated: true)
    }
}

class ToggleChronTabs: HiddenSetting, FeatureFlagsProtocol {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureActiveForBuild(.chronologicalTabs) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle chronological tabs \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        featureFlags.toggleBuildFeature(.chronologicalTabs)
        updateCell(navigationController)
    }

    func updateCell(_ navigationController: UINavigationController?) {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        tableView?.reloadData()
    }
}

class TogglePullToRefresh: HiddenSetting, FeatureFlagsProtocol {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureActiveForBuild(.pullToRefresh) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle Pull to Refresh \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        featureFlags.toggleBuildFeature(.pullToRefresh)
        updateCell(navigationController)
    }

    func updateCell(_ navigationController: UINavigationController?) {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        tableView?.reloadData()
    }
}

class ToggleInactiveTabs: HiddenSetting, FeatureFlagsProtocol {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureActiveForBuild(.inactiveTabs) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle inactive tabs \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        featureFlags.toggleBuildFeature(.inactiveTabs)
        InactiveTabModel.hasRunInactiveTabFeatureBefore = false
        updateCell(navigationController)
    }

    func updateCell(_ navigationController: UINavigationController?) {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        tableView?.reloadData()
    }
}


class ResetJumpBackInContextualHint: HiddenSetting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ResetJumpBackInContextualHint.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "Reset: Jump back in contextual hint", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }


    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        self.profile.prefs.removeObjectForKey(PrefsKeys.ContextualHintJumpBackinKey)
    }
}

class OpenFiftyTabsDebugOption: HiddenSetting {

    override var accessibilityIdentifier: String? { return "OpenFiftyTabsOption.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "⚠️ Open 50 `mozilla.org` tabs ⚠️", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let url = URL(string: "https://www.mozilla.org") else { return }
        BrowserViewController.foregroundBVC().debugOpen(numberOfNewTabs: 50, at: url)
    }
}

// Show the current version of Firefox
class VersionSetting: Setting {
    unowned let settings: SettingsTableViewController

    override var accessibilityIdentifier: String? { return "FxVersion" }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "\(AppName.longName) \(VersionSetting.appVersion) (\(VersionSetting.appBuildNumber))", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    public static var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    public static var appBuildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DebugSettingsClickCount += 1
        if DebugSettingsClickCount >= 5 {
            DebugSettingsClickCount = 0
            ShowDebugSettings = !ShowDebugSettings
            settings.tableView.reloadData()
        }
    }

    override func onLongPress(_ navigationController: UINavigationController?) {
        copyAppVersionAndPresentAlert(by: navigationController)
    }

    func copyAppVersionAndPresentAlert(by navigationController: UINavigationController?) {
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        getSelectedCell(by: navigationController)?.setSelected(false, animated: true)
        UIPasteboard.general.string = self.title?.string
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func getSelectedCell(by navigationController: UINavigationController?) -> UITableViewCell? {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return tableView?.cellForRow(at: indexPath)
    }
}

// Opens the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsLicenses, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return URL(string: "\(InternalURL.baseUrl)/\(AboutLicenseHandler.path)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the App Store review page of this app
class AppStoreReviewSetting: Setting {

    override var title: NSAttributedString? {
        return NSAttributedString(string: .RatingsPrompt.Settings.RateOnAppStore, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        RatingPromptManager.goToAppStoreReview()
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsYourRights, attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ShowTour" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .AppSettingsShowTour, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {
            BrowserViewController.foregroundBVC().presentIntroViewController(true)
        })
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return URL(string: "https://mozilla.crowdicity.com/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SendUsageSettingMessage, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.headerTextLight]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SendUsageSettingLink, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.general.highlightBlue]))

        super.init(
            prefs: prefs, prefKey: AppConstants.PrefSendUsageData, defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SendUsageSettingTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                Glean.shared.setUploadEnabled($0)
                Experiments.shared.resetTelemetryIdentifiers()
            }
        )
    }

    override var accessibilityIdentifier: String? { return "SendAnonymousUsageData" }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class StudiesToggleSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleMessage, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.headerTextLight]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleLink, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.general.highlightBlue]))

        super.init(
            prefs: prefs, prefKey: AppConstants.PrefStudiesToggle, defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SettingsStudiesToggleTitle),
            attributedStatusText: statusText,
            settingDidChange: { enabled in
                Experiments.shared.globalUserParticipation = enabled
            }
        )
    }

    override var accessibilityIdentifier: String? { return "StudiesToggle" }

        override var url: URL? {
            return SupportUtils.URLForTopic("ios-studies")
        }

        override func onClick(_ navigationController: UINavigationController?) {
            setUpAndPushSettingsContentViewController(navigationController, self.url)
        }
}

// Opens the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?) {
        super.init(title: NSAttributedString(string: .AppSettingsHelp, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]),
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

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .AppSettingsSearch, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate?) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        super.init(title: NSAttributedString(string: .LoginsAndPasswordsTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]),
                   delegate: delegate)
    }

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        deselectRow()

        guard let navController = navigationController else { return }
        let navigationHandler: ((_ url: URL?) -> Void) = { url in
            guard let url = url else { return }
            UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.settingsOpenURLInNewTab(url)
        }

        if AppAuthenticator.canAuthenticateDeviceOwner() {
            if LoginOnboarding.shouldShow() {
                let loginOnboardingViewController = LoginOnboardingViewController(profile: profile, tabManager: tabManager)

                loginOnboardingViewController.doneHandler = {
                    loginOnboardingViewController.dismiss(animated: true)
                }

                loginOnboardingViewController.proceedHandler = {
                    LoginListViewController.create(authenticateInNavigationController: navController, profile: self.profile, settingsDelegate: BrowserViewController.foregroundBVC(), webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
                        guard let loginsVC = loginsVC else { return }
                        navController.pushViewController(loginsVC, animated: true)
                        // Remove the onboarding from the navigation stack so that we go straight back to settings
                        navController.viewControllers.removeAll { viewController in
                            viewController == loginOnboardingViewController
                        }
                    }
                }

                navigationController?.pushViewController(loginOnboardingViewController, animated: true)

                LoginOnboarding.setShown()
            } else {
                LoginListViewController.create(authenticateInNavigationController: navController, profile: profile, settingsDelegate: BrowserViewController.foregroundBVC(), webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
                    guard let loginsVC = loginsVC else { return }
                    navController.pushViewController(loginsVC, animated: true)
                }
            }
        } else {
            let viewController = DevicePasscodeRequiredViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

class ContentBlockerSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    override var accessoryView: UIImageView? { return disclosureIndicator }
    override var accessibilityIdentifier: String? { return "TrackingProtection" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: NSAttributedString(string: .SettingsTrackingProtectionSectionName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
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

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle: String = .SettingsDataManagementSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
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
        return NSAttributedString(string: .AppSettingsPrivacyPolicy, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class ChinaSyncServiceSetting: Setting {
    override var accessoryType: UITableViewCell.AccessoryType { return .none }
    var prefs: Prefs { return profile.prefs }
    let prefKey = PrefsKeys.KeyEnableChinaSyncService
    let profile: Profile
    let settings: UIViewController

    override var hidden: Bool { return !AppInfo.isChinaEdition }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "本地同步服务", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "禁用后使用全球服务同步数据", attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.headerTextLight])
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.settings = settings
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitchThemed()
        control.onTintColor = UIColor.theme.tableView.controlTint
        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? AppInfo.isChinaEdition
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc func switchValueChanged(_ toggle: UISwitch) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .chinaServerSwitch)
        guard profile.rustFxA.hasAccount() else {
            prefs.setObject(toggle.isOn, forKey: prefKey)
            RustFirefoxAccounts.reconfig(prefs: profile.prefs)
            return
        }

        // Show confirmation dialog for the user to sign out of FxA

        let msg = "更改此设置后，再次登录您的帐户" // "Sign-in again to your account after changing this setting"
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let ok = UIAlertAction(title: .OKString, style: .default) { _ in
            self.prefs.setObject(toggle.isOn, forKey: self.prefKey)
            self.profile.removeAccount()
            RustFirefoxAccounts.reconfig(prefs: self.profile.prefs)
        }
        let cancel = UIAlertAction(title: .CancelString, style: .default) { _ in
            toggle.setOn(!toggle.isOn, animated: true)
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        settings.present(alert, animated: true)
    }
}

class NewTabPageSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "NewTab" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getNewTabPage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsNewTabSectionName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

fileprivate func getDisclosureIndicator() -> UIImageView {
    let disclosureIndicator = UIImageView()
    disclosureIndicator.image = UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate)
    disclosureIndicator.tintColor = UIColor.theme.tableView.accessoryViewTint
    disclosureIndicator.sizeToFit()
    return disclosureIndicator
}

class HomeSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView {
        getDisclosureIndicator()
    }

    override var accessibilityIdentifier: String? { return "Home" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getHomePage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: .AppMenuOpenHomePageTitleString, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HomePageSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class TabsSetting: Setting {

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "TabsSetting" }

    init() {
        super.init(title: NSAttributedString(string: .Settings.SectionTitles.TabsTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = TabsSettingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class SiriPageSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "SiriSettings" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: .SettingsSiriSectionName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SiriSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

@available(iOS 14.0, *)
class DefaultBrowserSetting: Setting {
    override var accessibilityIdentifier: String? { return "DefaultBrowserSettings" }

    init() {
        super.init(title: NSAttributedString(string: String.DefaultBrowserMenuItem, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowActionAccessory]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .open, object: .settingsMenuSetAsDefaultBrowser)
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }
}

class OpenWithSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "OpenWith.Setting" }

    override var status: NSAttributedString {
        guard let provider = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption), provider != "mailto:" else {
            return NSAttributedString(string: "")
        }
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"), let dictRoot = NSArray(contentsOfFile: path) {
            let mailProvider = dictRoot.compactMap({$0 as? NSDictionary }).first { (dict) -> Bool in
                return (dict["scheme"] as? String) == provider
            }
            return NSAttributedString(string: (mailProvider?["name"] as? String) ?? "")
        }
        return NSAttributedString(string: "")
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: .SettingsOpenWithSectionName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AdvancedAccountSetting: HiddenSetting {
    let profile: Profile

    override var accessoryView: UIImageView? { return disclosureIndicator }

    override var accessibilityIdentifier: String? { return "AdvancedAccount.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .SettingsAdvancedAccountTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = AdvancedAccountSettingViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }

    override var hidden: Bool {
        return !ShowDebugSettings || profile.hasAccount()
    }
}

class ThemeSetting: Setting {
    let profile: Profile
    override var accessoryView: UIImageView? { return disclosureIndicator }
    override var style: UITableViewCell.CellStyle { return .value1 }
    override var accessibilityIdentifier: String? { return "DisplayThemeOption" }

    override var status: NSAttributedString {
        if LegacyThemeManager.instance.systemThemeIsOn {
            return NSAttributedString(string: .SystemThemeSectionHeader)
        } else if !LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeManualStatusLabel)
        } else if LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeAutomaticStatusLabel)
        }
        return NSAttributedString(string: "")
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsDisplayThemeTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ThemeSettingsController(), animated: true)
    }
}

extension BrowserViewController {
    /// ⚠️ !! WARNING !! ⚠️
    /// This function opens up x number of new tabs in the background.
    /// This is meant to test memory overflows with tabs on a device.
    /// DO NOT USE unless you're explicitly testing this feature.
    /// It should only be used from the debug menu.
    func debugOpen(numberOfNewTabs: Int?, at url: URL) {
        guard let numberOfNewTabs = numberOfNewTabs,
              numberOfNewTabs > 0
        else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            self.tabManager.addTab(URLRequest(url: url))
            self.debugOpen(numberOfNewTabs: numberOfNewTabs - 1, at: url)
        })
    }
}
