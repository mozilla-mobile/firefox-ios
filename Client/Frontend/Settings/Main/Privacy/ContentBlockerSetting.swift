// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ContentBlockerSetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let profile: Profile
    private var tabManager: TabManager!

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.ContentBlocker.title
    }

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

    init(settings: SettingsTableViewController,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.settingsDelegate = settingsDelegate
        super.init(title: NSAttributedString(string: .SettingsTrackingProtectionSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedContentBlocker()
            return
        }

        let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}
