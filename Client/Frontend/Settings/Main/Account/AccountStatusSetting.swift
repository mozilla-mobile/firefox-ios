// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Common
import Foundation
import Shared

// Sync setting that shows the current Firefox Account status.
class AccountStatusSetting: WithAccountSetting {
    private weak var settingsDelegate: AccountSettingsDelegate?
    private var notificationCenter: NotificationProtocol

    init(settings: SettingsTableViewController,
         settingsDelegate: AccountSettingsDelegate?,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)

        notificationCenter.addObserver(self,
                                       selector: #selector(updateAccount),
                                       name: .FirefoxAccountProfileChanged,
                                       object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
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
                    NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFontBold,
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
        }

        if let email = RustFirefoxAccounts.shared.userProfile?.email {
            return NSAttributedString(
                string: email,
                attributes: [
                    NSAttributedString.Key.font: LegacyDynamicFontHelper.defaultHelper.DefaultStandardFontBold,
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
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: .settings)

            if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
                settingsDelegate?.pressedToShowFirefoxAccount()
                return
            }

            let fxaParams = FxALaunchParams(entrypoint: .accountStatusSettingReauth, query: [:])
            let controller = FirefoxAccountSignInViewController(profile: profile, parentType: .settings, deepLinkParams: fxaParams)
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedToShowSyncContent()
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

            imageView.image = UIImage(named: StandardImageIdentifiers.Large.avatarCircle)?
                .createScaled(CGSize(width: 30, height: 30))
                .tinted(withColor: theme.colors.iconPrimary)

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
