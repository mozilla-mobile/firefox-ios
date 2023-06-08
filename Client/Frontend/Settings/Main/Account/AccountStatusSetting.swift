// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared

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
