// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

final class AdBlockerSetting: BoolSetting {
    static let learnMoreTopic = "block-ads-firefox-ios"

    private let subtitleText: String
    private let learnMoreText: String
    private weak var supportDelegate: SupportSettingsDelegate?

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Browsing.adBlockerTitle
    }

    init(
        prefs: Prefs,
        supportDelegate: SupportSettingsDelegate?,
        settingDidChange: @escaping (Bool) -> Void
    ) {
        self.subtitleText = .Settings.Browsing.AdBlocker.Description
        self.learnMoreText = .Settings.Browsing.AdBlocker.LearnMore
        self.supportDelegate = supportDelegate
        super.init(
            prefs: prefs,
            prefKey: PrefsKeys.BlockAds,
            defaultValue: false,
            attributedTitleText: NSAttributedString(string: String.Settings.Browsing.AdBlocker.Title),
            attributedStatusText: NSAttributedString(string: String.Settings.Browsing.AdBlocker.Description),
            settingDidChange: settingDidChange
        )
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        guard let cell = cell as? ThemedLearnMoreTableViewCell else { return }
        guard let title = title?.string else { return }

        cell.configure(
            title: title,
            subtitle: subtitleText,
            learnMoreText: learnMoreText,
            a11yId: AccessibilityIdentifiers.Settings.Browsing.adBlockerLearnMore,
            theme: theme
        )

        control.configureSwitch(
            onTintColor: theme.colors.actionPrimary,
            isEnabled: enabled
        )
        displayBool(control.switchView)
        control.switchView.accessibilityLabel = "\(title), \(subtitleText)"
        if let accessibilityIdentifier {
            cell.setAccessibilities(traits: .none, identifier: accessibilityIdentifier)
        }

        cell.accessoryView = control
        cell.selectionStyle = .none

        cell.learnMoreDidTap = { [weak self] in
            let url = SupportUtils.URLForTopic(AdBlockerSetting.learnMoreTopic)
            self?.supportDelegate?.askedToOpen(
                url: url,
                withTitle: NSAttributedString(string: String.Settings.Browsing.AdBlocker.Title)
            )
        }
    }
}
