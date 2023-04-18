// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Common
import Foundation
import Shared
import Account
import LocalAuthentication
import Glean

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

struct SettingDisclosureUtility {
    static func buildDisclosureIndicator(theme: Theme) -> UIImageView {
        let disclosureIndicator = UIImageView()
        disclosureIndicator.image = UIImage(named: ImageIdentifiers.menuChevron)?.withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        disclosureIndicator.tintColor = theme.colors.actionSecondary
        disclosureIndicator.sizeToFit()
        return disclosureIndicator
    }
}

// MARK: - ConnectSetting
// Sync setting for connecting a Firefox Account. Shown when we don't have an account.
class ConnectSetting: WithoutAccountSetting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .Settings.Sync.ButtonTitle, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var accessibilityIdentifier: String? { return "SignInToSync" }

    override func onClick(_ navigationController: UINavigationController?) {
        let fxaParams = FxALaunchParams(entrypoint: .connectSetting, query: [:])
        let viewController = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: fxaParams)
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: .settings)
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.imageView?.image = UIImage.templateImageNamed("FxA-Default")
        cell.imageView?.tintColor = theme.colors.textDisabled
        cell.imageView?.layer.cornerRadius = (cell.imageView?.frame.size.width)! / 2
        cell.imageView?.layer.masksToBounds = true
    }
}

// MARK: - SyncNowSetting
class SyncNowSetting: WithAccountSetting {
    let imageView = UIImageView(frame: CGRect(width: 30, height: 30))
    let syncIconWrapper = UIImage.createWithColor(CGSize(width: 30, height: 30), color: UIColor.clear)
    let syncBlueIcon = UIImage(named: "FxA-Sync-Blue")

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
                    NSAttributedString.Key.foregroundColor: theme.colors.textWarning,
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultMediumFont
                ]
            )
        }

        let syncText = theme.colors.textPrimary
        let headerLightText = theme.colors.textSecondary
        return NSAttributedString(
            string: .FxASyncNow,
            attributes: [
                NSAttributedString.Key.foregroundColor: self.enabled ? syncText : headerLightText,
                NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont
            ]
        )
    }

    func startRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.add(self.continuousRotateAnimation, forKey: "rotateKey")
        }
    }

    @objc
    func stopRotateSyncIcon() {
        DispatchQueue.main.async {
            self.imageView.layer.removeAllAnimations()
        }
    }

    override var accessoryType: UITableViewCell.AccessoryType { return .none }

    override var image: UIImage? {
        let syncIcon = UIImage(named: "FxA-Sync")?.tinted(withColor: theme.colors.iconPrimary)

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
            return NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textWarning,
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .warning(let message):
            return  NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textWarning,
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .inProgress:
            return NSAttributedString(
                string: .SyncingMessageWithEllipsis,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary,
                             NSAttributedString.Key.font: UIFont.systemFont(
                                ofSize: DynamicFontHelper.defaultHelper.DefaultStandardFontSize,
                                weight: UIFont.Weight.regular)])
        default:
            return syncNowTitle
        }
    }

    override var status: NSAttributedString? {
        guard let timestamp = profile.syncManager.lastSyncFinishTime else { return nil }

        let formattedLabel = timestampFormatter.string(from: Date.fromTimestamp(timestamp))
        let attributedString = NSMutableAttributedString(string: formattedLabel)
        let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)]
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
        // swiftlint:disable unused_setter_value
        set { }
        // swiftlint:enable unused_setter_value
    }

    fileprivate lazy var troubleshootButton: UIButton = {
        let troubleshootButton = UIButton(type: .roundedRect)
        troubleshootButton.setTitle(.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.tintColor = theme.colors.actionPrimary
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

    @objc
    fileprivate func troubleshoot() {
        let viewController = SettingsContentViewController()
        viewController.url = syncSUMOURL
        settings.navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.textLabel?.attributedText = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let syncStatus = profile.syncManager.syncDisplayState {
            switch syncStatus {
            case .bad(let message):
                if message != nil {
                    // add the red warning symbol
                    // add a link to the MANA page
                    cell.detailTextLabel?.attributedText = nil
                    cell.accessoryView = troubleshootButton
                    addIcon(errorIcon, toCell: cell)
                } else {
                    cell.detailTextLabel?.attributedText = status
                    cell.accessoryView = nil
                }
            case .warning:
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

        // Animation that loops continuously until stopped
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(Double.pi)
        continuousRotateAnimation.isRemovedOnCompletion = true
        continuousRotateAnimation.duration = 0.5
        continuousRotateAnimation.repeatCount = .infinity

        // To ensure sync icon is aligned properly with user's avatar, an image is created with proper
        // dimensions and color, then the scaled sync icon is added as a subview.
        imageView.contentMode = .center
        imageView.image = image
        imageView.transform = CGAffineTransform(scaleX: -1, y: 1)

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
        profile.pollCommands(forcePoll: true)
    }
}

// MARK: - AccountStatusSetting
// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
    override init(settings: SettingsTableViewController) {
        super.init(settings: settings)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAccount), name: .FirefoxAccountProfileChanged, object: nil)
    }

    @objc
    func updateAccount(notification: Notification) {
        DispatchQueue.main.async {
            self.settings.tableView.reloadData()
        }
    }

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var title: NSAttributedString? {
        if let displayName = RustFirefoxAccounts.shared.userProfile?.displayName {
            return NSAttributedString(
                string: displayName,
                attributes: [
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFontBold,
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
        }

        if let email = RustFirefoxAccounts.shared.userProfile?.email {
            return NSAttributedString(
                string: email,
                attributes: [
                    NSAttributedString.Key.font: DynamicFontHelper.defaultHelper.DefaultStandardFontBold,
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
        }

        return nil
    }

    override var status: NSAttributedString? {
        if RustFirefoxAccounts.shared.isActionNeeded {
            let string: String = .FxAAccountVerifyPassword
            let color = theme.colors.textWarning
            let range = NSRange(location: 0, length: string.count)
            let attrs = [NSAttributedString.Key.foregroundColor: color]
            let res = NSMutableAttributedString(string: string)
            res.setAttributes(attrs, range: range)
            return res
        }
        return nil
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard !profile.rustFxA.accountNeedsReauth() else {
            let fxaParams = FxALaunchParams(entrypoint: .accountStatusSettingReauth, query: [:])
            let controller = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: fxaParams)
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: .settings)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        let viewController = SyncContentSettingsViewController()
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if let imageView = cell.imageView {
            imageView.subviews.forEach({ $0.removeFromSuperview() })
            imageView.frame = CGRect(width: 30, height: 30)
            imageView.layer.cornerRadius = (imageView.frame.height) / 2
            imageView.layer.masksToBounds = true

            imageView.image = UIImage(named: ImageIdentifiers.placeholderAvatar)?
                .createScaled(CGSize(width: 30, height: 30))

            guard let str = RustFirefoxAccounts.shared.userProfile?.avatarUrl,
                  let actionIconUrl = URL(string: str)
            else { return }

            GeneralizedImageFetcher().getImageFor(url: actionIconUrl) { image in
                guard let avatar = image else { return }

                imageView.image = avatar.createScaled(CGSize(width: 30, height: 30))
                    .withRenderingMode(.alwaysOriginal)
            }
        }
    }
}

// MARK: - Hidden Settings
/// Used for only for debugging purposes. These settings are hidden behind a
/// 5-tap gesture on the Firefox version cell in the Settings Menu
class HiddenSetting: Setting {
    unowned let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }

    func updateCell(_ navigationController: UINavigationController?) {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        tableView?.reloadData()
    }
}

class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
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
        } catch {}
    }
}

class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                return file.hasPrefix("browser.") || file.hasPrefix("logins.") || file.hasPrefix("metadata.")
            }
        } catch {}
    }
}

class ExportLogDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy log files to app container", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        DefaultLogger.shared.copyLogsToDocuments()
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
        return NSAttributedString(string: "💥 Debug: Force Crash", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        fatalError("Force crash")
    }
}

class ChangeToChinaSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: toggle China version (needs restart)", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if UserDefaults.standard.bool(forKey: AppInfo.debugPrefIsChinaEdition) {
            UserDefaults.standard.removeObject(forKey: AppInfo.debugPrefIsChinaEdition)
        } else {
            UserDefaults.standard.set(true, forKey: AppInfo.debugPrefIsChinaEdition)
        }
    }
}

class SlowTheDatabase: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: "Debug: simulate slow database operations", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        debugSimulateSlowDBOperations = !debugSimulateSlowDBOperations
    }
}

class ForgetSyncAuthStateDebugSetting: HiddenSetting {
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Debug: forget Sync auth state",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settings.profile.rustFxA.syncAuthState.invalidate()
        settings.tableView.reloadData()
    }
}

class SentryIDSetting: HiddenSetting {
    let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: "SentryDeviceAppHash") ?? "0000000000000000000000000000000000000000"
    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Sentry ID: \(deviceAppHash)",
            attributes: [
                NSAttributedString.Key.foregroundColor: theme.colors.textPrimary,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
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

class ExperimentsSettings: HiddenSetting {
    override var title: NSAttributedString? { return NSAttributedString(string: "Experiments")}

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ExperimentsViewController(), animated: true)
    }
}

class TogglePullToRefresh: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle Pull to Refresh \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly)
        featureFlags.set(feature: .pullToRefresh, to: newStatus)
        updateCell(navigationController)
    }
}

class ResetWallpaperOnboardingPage: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let seenStatus = UserDefaults.standard.bool(forKey: PrefsKeys.Wallpapers.OnboardingSeenKey) ? "SEEN" : "UNSEEN"
        return NSAttributedString(string: "Reset wallpaper onboarding sheet (\(seenStatus))",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        UserDefaults.standard.set(false, forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
        updateCell(navigationController)
    }
}

class ToggleInactiveTabs: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(string: "Toggle inactive tabs \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly)
        featureFlags.set(feature: .inactiveTabs, to: newStatus)
        InactiveTabModel.hasRunInactiveTabFeatureBefore = false
        updateCell(navigationController)
    }
}

class ToggleHistoryGroups: HiddenSetting, FeatureFlaggable {
    override var title: NSAttributedString? {
        let toNewStatus = featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly) ? "OFF" : "ON"
        return NSAttributedString(
            string: "Toggle history groups \(toNewStatus)",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let newStatus = !featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly)
        featureFlags.set(feature: .historyGroups, to: newStatus)
        updateCell(navigationController)
    }
}

class ResetContextualHints: HiddenSetting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ResetContextualHints.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(
            string: "Reset all contextual hints",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        PrefsKeys.ContextualHints.allCases.forEach {
            self.profile.prefs.removeObjectForKey($0.rawValue)
        }
    }
}

class OpenFiftyTabsDebugOption: HiddenSetting {
    override var accessibilityIdentifier: String? { return "OpenFiftyTabsOption.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "⚠️ Open 50 `mozilla.org` tabs ⚠️", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let url = URL(string: "https://www.mozilla.org") else { return }

        let object = OpenTabNotificationObject(type: .debugOption(50, url))
        NotificationCenter.default.post(name: .OpenTabNotification, object: object)
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
        return NSAttributedString(string: "\(AppName.shortName) \(AppInfo.appVersion) (\(AppInfo.buildNumber))", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
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
        return NSAttributedString(string: .AppSettingsLicenses, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
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
        return NSAttributedString(string: .Settings.About.RateOnAppStore, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        RatingPromptManager.goToAppStoreReview()
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsYourRights,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
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
        let attributes = [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
        super.init(title: NSAttributedString(string: .AppSettingsShowTour,
                                             attributes: attributes))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: .PresentIntroView, object: self)

            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .settingsMenuShowTour
            )
        })
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://connect.mozilla.org/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SendUsageSettingMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SendUsageSettingLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SendUsageSettingTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                AdjustHelper.setEnabled($0)
                Glean.shared.setUploadEnabled($0)
                Experiments.setTelemetrySetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
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
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SettingsStudiesToggleTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                Experiments.setStudiesSetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setStudiesSetting(prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true)
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
    init(delegate: SettingsDelegate?, theme: Theme) {
        super.init(title: NSAttributedString(string: .AppSettingsHelp, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
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

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var style: UITableViewCell.CellStyle { return .value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine?.shortName ?? "") }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .AppSettingsSearch, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController(profile: profile)

        navigationController?.pushViewController(viewController, animated: true)
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    private let appAuthenticator: AppAuthenticationProtocol
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController,
         delegate: SettingsDelegate?,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.appAuthenticator = appAuthenticator
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        super.init(
            title: NSAttributedString(
                string: .Settings.Passwords.Title,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            ),
            delegate: delegate
        )
    }

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        deselectRow()

        guard let navController = navigationController else { return }
        let navigationHandler: (_ url: URL?) -> Void = { url in
            guard let url = url else { return }
            UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.settingsOpenURLInNewTab(url)
        }

        if appAuthenticator.canAuthenticateDeviceOwner() {
            if LoginOnboarding.shouldShow() {
                let loginOnboardingViewController = LoginOnboardingViewController(profile: profile, tabManager: tabManager)

                loginOnboardingViewController.doneHandler = {
                    loginOnboardingViewController.dismiss(animated: true)
                }

                loginOnboardingViewController.proceedHandler = {
                    LoginListViewController.create(
                        didShowFromAppMenu: false,
                        authenticateInNavigationController: navController,
                        profile: self.profile,
                        webpageNavigationHandler: navigationHandler
                    ) { loginsVC in
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
                LoginListViewController.create(
                    didShowFromAppMenu: false,
                    authenticateInNavigationController: navController,
                    profile: profile,
                    webpageNavigationHandler: navigationHandler
                ) { loginsVC in
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
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var accessibilityIdentifier: String? { return "TrackingProtection" }

    override var status: NSAttributedString? {
        let isOn = profile.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing

        if isOn {
            let currentBlockingStrength = profile
                .prefs
                .stringForKey(ContentBlockingConfig.Prefs.StrengthKey)
                .flatMap(BlockingStrength.init(rawValue:)) ?? .basic
            return NSAttributedString(string: currentBlockingStrength.settingStatus)
        } else {
            return NSAttributedString(string: .Settings.Homepage.Shortcuts.ToggleOff)
        }
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: NSAttributedString(string: .SettingsTrackingProtectionSectionName, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
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

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle: String = .SettingsDataManagementSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AutofillCreditCardSettings: Setting, FeatureFlaggable {
    private let profile: Profile
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var accessibilityIdentifier: String? { return "AutofillCreditCard" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        let title: String = .SettingsAutofillCreditCard
        super.init(title: NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Telemetry
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillSettings)
        let viewModel = CreditCardSettingsViewModel(profile: profile)
        let viewController = CreditCardSettingsViewController(
            creditCardViewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsPrivacyPolicy, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
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
        return NSAttributedString(string: "本地同步服务",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var status: NSAttributedString? {
        return NSAttributedString(string: "禁用后使用全球服务同步数据",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary])
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.settings = settings
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        let control = UISwitch()
        control.onTintColor = theme.colors.actionPrimary
        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        control.isOn = prefs.boolForKey(prefKey) ?? AppInfo.isChinaEdition
        cell.accessoryView = control
        cell.selectionStyle = .none
    }

    @objc
    func switchValueChanged(_ toggle: UISwitch) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .chinaServerSwitch)
        guard profile.rustFxA.hasAccount() else {
            prefs.setObject(toggle.isOn, forKey: prefKey)
            RustFirefoxAccounts.reconfig(prefs: profile.prefs)
            return
        }

        // Show confirmation dialog for the user to sign out of FxA

        let msg = "更改此设置后，再次登录您的帐户" // "Sign-in again to your account after changing this setting"
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let okString = UIAlertAction(title: .OKString, style: .default) { _ in
            self.prefs.setObject(toggle.isOn, forKey: self.prefKey)
            self.profile.removeAccount()
            RustFirefoxAccounts.reconfig(prefs: self.profile.prefs)
        }
        let cancel = UIAlertAction(title: .CancelString, style: .default) { _ in
            toggle.setOn(!toggle.isOn, animated: true)
        }
        alert.addAction(okString)
        alert.addAction(cancel)
        settings.present(alert, animated: true)
    }
}

class NewTabPageSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "NewTab" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getNewTabPage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsNewTabSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class HomeSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "Home" }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getHomePage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsHomePageSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = HomePageSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class TabsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "TabsSetting" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: .Settings.SectionTitles.TabsTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = TabsSettingsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NotificationsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Setting.notifications }

    let profile: Profile

    init(theme: Theme, profile: Profile) {
        self.profile = profile
        super.init(title: NSAttributedString(string: .Settings.Notifications.Title,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NotificationsSettingsViewController(prefs: profile.prefs, hasAccount: profile.hasAccount())
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class SiriPageSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "SiriSettings" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: .SettingsSiriSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SiriSettingsViewController(prefs: profile.prefs)
        viewController.profile = profile
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class NoImageModeSetting: BoolSetting {
    init(settings: SettingsTableViewController) {
        let noImageEnabled = NoImageModeHelper.isActivated(settings.profile.prefs)
        let didChange = { (isEnabled: Bool) in
            NoImageModeHelper.toggle(isEnabled: isEnabled,
                                     profile: settings.profile,
                                     tabManager: settings.tabManager)
        }

        super.init(
            prefs: settings.profile.prefs,
            prefKey: NoImageModePrefsKey.NoImageModeStatus,
            defaultValue: noImageEnabled,
            attributedTitleText: NSAttributedString(string: .Settings.Toggle.NoImageMode),
            attributedStatusText: nil,
            settingDidChange: { isEnabled in
                didChange(isEnabled)
            }
        )
    }

    override var accessibilityIdentifier: String? { return "NoImageMode" }
}

@available(iOS 14.0, *)
class DefaultBrowserSetting: Setting {
    override var accessibilityIdentifier: String? { return "DefaultBrowserSettings" }

    init(theme: Theme) {
        super.init(title: NSAttributedString(string: String.DefaultBrowserMenuItem,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .open, object: .settingsMenuSetAsDefaultBrowser)
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
    }
}

class OpenWithSetting: Setting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "OpenWith.Setting" }

    override var status: NSAttributedString {
        guard let provider = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption) else {
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

        super.init(title: NSAttributedString(string: .SettingsOpenWithSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AdvancedAccountSetting: HiddenSetting {
    let profile: Profile

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "AdvancedAccount.Setting" }

    override var title: NSAttributedString? {
        return NSAttributedString(string: .SettingsAdvancedAccountTitle, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
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
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
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
        super.init(title: NSAttributedString(string: .SettingsDisplayThemeTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ThemeSettingsController(), animated: true)
    }
}

class SearchBarSetting: Setting {
    let viewModel: SearchBarSettingsViewModel

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting }

    override var status: NSAttributedString {
        return NSAttributedString(string: viewModel.searchBarTitle )
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.viewModel = SearchBarSettingsViewModel(prefs: settings.profile.prefs)
        super.init(title: NSAttributedString(string: viewModel.title,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = SearchBarSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
