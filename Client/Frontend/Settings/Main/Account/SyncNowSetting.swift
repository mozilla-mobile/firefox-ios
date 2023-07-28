// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SyncNowSetting: WithAccountSetting {
    private weak var settingsDelegate: AccountSettingsDelegate?
    private var notificationCenter: NotificationProtocol

    private let imageView = UIImageView(frame: CGRect(width: 30, height: 30))
    private let syncIconWrapper = UIImage.createWithColor(CGSize(width: 30, height: 30), color: UIColor.clear)
    private let syncBlueIcon = UIImage(named: "FxA-Sync-Blue")

    // Animation used to rotate the Sync icon 360 degrees while syncing is in progress.
    private let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

    init(settings: SettingsTableViewController,
         settingsDelegate: AccountSettingsDelegate?,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.settingsDelegate = settingsDelegate
        self.notificationCenter = notificationCenter
        super.init(settings: settings)

        notificationCenter.addObserver(self,
                                       selector: #selector(stopRotateSyncIcon),
                                       name: .ProfileDidFinishSyncing,
                                       object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    private lazy var timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private var syncNowTitle: NSAttributedString {
        if !DeviceInfo.hasConnectivity() {
            return NSAttributedString(
                string: .FxANoInternetConnection,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textWarning,
                    NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultMediumFont
                ]
            )
        }

        let syncText = theme.colors.textPrimary
        let headerLightText = theme.colors.textSecondary
        return NSAttributedString(
            string: .FxASyncNow,
            attributes: [
                NSAttributedString.Key.foregroundColor: self.enabled ? syncText : headerLightText,
                NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFont
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
                    NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .warning(let message):
            return  NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textWarning,
                    NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFont])
        case .inProgress:
            return NSAttributedString(
                string: .SyncingMessageWithEllipsis,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary,
                             NSAttributedString.Key.font: UIFont.systemFont(
                                ofSize: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFontSize,
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

    private lazy var troubleshootButton: UIButton = {
        let troubleshootButton = UIButton(type: .roundedRect)
        troubleshootButton.setTitle(.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.tintColor = theme.colors.actionPrimary
        troubleshootButton.titleLabel?.font = LegacyDynamicFontHelper.defaultHelper.DefaultSmallFont
        troubleshootButton.sizeToFit()
        return troubleshootButton
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "AmberCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    private lazy var errorIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "RedCaution"))
        imageView.sizeToFit()
        return imageView
    }()

    private let syncSUMOURL = SupportUtils.URLForTopic("sync-status-ios")

    @objc
    private func troubleshoot() {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.askedToOpen(url: syncSUMOURL, withTitle: title)
            return
        }

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

    private func addIcon(_ image: UIImageView, toCell cell: UITableViewCell) {
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

        profile.syncManager.syncEverything(why: .user)
        profile.pollCommands(forcePoll: true)
    }
}
