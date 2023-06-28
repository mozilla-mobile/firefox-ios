// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.ShowIntroduction.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate?) {
        self.settingsDelegate = settingsDelegate
        let attributes = [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
        super.init(title: NSAttributedString(string: .AppSettingsShowTour,
                                             attributes: attributes))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .settingsMenuShowTour
        )

        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedShowTour()
        } else {
            navigationController?.dismiss(animated: true) {
                NotificationCenter.default.post(name: .PresentIntroView, object: self)
            }
        }
    }
}
