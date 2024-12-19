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
    private let syncIconWrapper = UIImage.createWithColor(
        CGSize(width: 30, height: 30),
        color: UIColor.clear
    )
    private let syncIcon = UIImage(named: StandardImageIdentifiers.Large.sync)

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

    private var syncNowTitle: NSAttributedString? {
        guard let theme else { return nil }

        if !DeviceInfo.hasConnectivity() {
            return NSAttributedString(
                string: .FxANoInternetConnection,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textCritical,
                    NSAttributedString.Key.font: FXFontStyles.Regular.body.scaledFont()
                ]
            )
        }

        let syncText = theme.colors.textPrimary
        let headerLightText = theme.colors.textSecondary
        return NSAttributedString(
            string: .FxASyncNow,
            attributes: [
                NSAttributedString.Key.foregroundColor: self.enabled ? syncText : headerLightText,
                NSAttributedString.Key.font: FXFontStyles.Regular.body.scaledFont()
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
        guard let profile, let theme else { return nil }
        guard let syncStatus = profile.syncManager.syncDisplayState else {
            return syncIcon?.tinted(withColor: theme.colors.iconPrimary)
        }

        switch syncStatus {
        case .inProgress:
            return syncIcon?.tinted(withColor: theme.colors.iconAccent)
        default:
            return syncIcon?.tinted(withColor: theme.colors.iconPrimary)
        }
    }

    override var title: NSAttributedString? {
        guard let profile, let theme, let syncStatus = profile.syncManager.syncDisplayState else {
            return syncNowTitle
        }

        switch syncStatus {
        case .bad(nil):
            return syncNowTitle
        case .bad(let message?),
             .warning(let message):
            return NSAttributedString(
                string: message,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textCritical,
                    NSAttributedString.Key.font: FXFontStyles.Regular.body.scaledFont()
                ]
            )
        case .inProgress:
            return NSAttributedString(
                string: .SyncingMessageWithEllipsis,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary,
                    NSAttributedString.Key.font: FXFontStyles.Regular.body.scaledFont()
                ]
            )
        default:
            return syncNowTitle
        }
    }

    override var status: NSAttributedString? {
        guard let profile, let theme, let timestamp = profile.syncManager.lastSyncFinishTime else {
            return nil
        }

        let formattedLabel = timestampFormatter.string(from: Date.fromTimestamp(timestamp))
        let attributedString = NSMutableAttributedString(string: formattedLabel)
        let attributes = [
            NSAttributedString.Key.foregroundColor: theme.colors.textSecondary,
            NSAttributedString.Key.font: FXFontStyles.Regular.caption1.scaledFont()
        ]
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

            return profile?.hasSyncableAccount() ?? false
        }
        // swiftlint:disable unused_setter_value
        set { }
        // swiftlint:enable unused_setter_value
    }

    private lazy var troubleshootButton: UIButton = .build { [weak self] troubleshootButton in
        guard let self = self, let theme = self.theme else { return }
        troubleshootButton.setTitle(.FirefoxSyncTroubleshootTitle, for: .normal)
        troubleshootButton.addTarget(self, action: #selector(self.troubleshoot), for: .touchUpInside)
        troubleshootButton.setTitleColor(theme.colors.textCritical, for: .normal)
        troubleshootButton.titleLabel?.font = FXFontStyles.Regular.caption1.scaledFont()
    }

    private lazy var accessoryViewContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.spacing = 4
    }

    private lazy var warningIcon: UIImageView = {
        let image = UIImage(named: StandardImageIdentifiers.Large.warningFill)
        guard let theme else { return UIImageView(image: image) }
        return UIImageView(image: image?.tinted(withColor: theme.colors.iconCritical))
    }()

    private lazy var errorIcon: UIImageView = {
        let image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.warningFill)
        guard let theme else { return UIImageView(image: image) }
        return UIImageView(image: image?.tinted(withColor: theme.colors.iconCritical))
    }()

    private let syncSUMOURL = SupportUtils.URLForTopic("sync-status-ios")

    @objc
    private func troubleshoot() {
        settingsDelegate?.askedToOpen(url: syncSUMOURL, withTitle: title)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.textLabel?.attributedText = title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if let syncStatus = profile?.syncManager.syncDisplayState {
            switch syncStatus {
            case .bad(let message):
                if message != nil {
                    // add the red warning symbol
                    // add a link to the MANA page
                    cell.detailTextLabel?.attributedText = nil
                    addAccessoryView(with: errorIcon, to: cell)
                } else {
                    cell.detailTextLabel?.attributedText = status
                    cell.accessoryView = nil
                }
            case .warning:
                // add the amber warning symbol
                // add a link to the MANA page
                cell.detailTextLabel?.attributedText = nil
                addAccessoryView(with: warningIcon, to: cell)
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
        cell.isUserInteractionEnabled = !(profile?.syncManager.isSyncing ?? false) && DeviceInfo.hasConnectivity()

        // Animation that loops continuously until stopped
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(-Double.pi)
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

        if let syncStatus = profile?.syncManager.syncDisplayState {
            switch syncStatus {
            case .inProgress:
                self.startRotateSyncIcon()
            default:
                self.stopRotateSyncIcon()
            }
        }
    }

    private func addAccessoryView(with image: UIImageView, to cell: UITableViewCell) {
        DispatchQueue.main.async { [weak self] in
            guard let troubleshootButton = self?.troubleshootButton else { return }
            self?.accessoryViewContainer.addArrangedSubview(image)
            self?.accessoryViewContainer.addArrangedSubview(troubleshootButton)
            cell.accessoryView = self?.accessoryViewContainer
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if !DeviceInfo.hasConnectivity() {
            return
        }

        profile?.syncManager.syncEverything(why: .user)
        profile?.pollCommands(forcePoll: true)
    }
}
