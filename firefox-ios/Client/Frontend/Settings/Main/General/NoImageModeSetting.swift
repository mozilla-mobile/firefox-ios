// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class NoImageModeSetting: BoolSetting {
    init(profile: Profile) {
        let noImageEnabled = NoImageModeHelper.isActivated(profile.prefs)
        let didChange = { (isEnabled: Bool) in
            NoImageModeHelper.toggle(isEnabled: isEnabled, profile: profile)
        }

        super.init(
            prefs: profile.prefs,
            prefKey: NoImageModePrefsKey.NoImageModeStatus,
            defaultValue: noImageEnabled,
            attributedTitleText: NSAttributedString(string: .Settings.Toggle.NoImageMode),
            attributedStatusText: nil,
            settingDidChange: { isEnabled in
                didChange(isEnabled)
            }
        )
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.NoImageMode.title
    }
}
