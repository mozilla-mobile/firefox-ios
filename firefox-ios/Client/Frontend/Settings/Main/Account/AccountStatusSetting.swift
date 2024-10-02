// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Common
import Foundation
import Shared
import Account

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
        guard let profile = RustFirefoxAccounts.shared.userProfile else { return nil }

        let string = profile.displayName ?? profile.email

        return NSAttributedString(
            string: string,
            attributes: [
                NSAttributedString.Key.font: FXFontStyles.Bold.body.scaledFont(),
                NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
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
            settingsDelegate?.pressedToShowFirefoxAccount()
            return
        }

        settingsDelegate?.pressedToShowSyncContent()
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
                  let actionIconUrl = URL(string: str, invalidCharacters: false)
            else { return }

            GeneralizedImageFetcher().getImageFor(url: actionIconUrl) { image in
                guard let avatar = image else { return }

                imageView.image = avatar.createScaled(CGSize(width: 30, height: 30))
                    .withRenderingMode(.alwaysOriginal)
            }
        }
    }
}
