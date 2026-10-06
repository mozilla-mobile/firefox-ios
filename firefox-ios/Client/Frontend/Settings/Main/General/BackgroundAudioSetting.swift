// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class BackgroundAudioSetting: BoolSetting {
    init(prefs: Prefs) {
        super.init(
            prefs: prefs,
            prefKey: PrefsKeys.BackgroundAudio,
            defaultValue: FxNimbus.shared.features.backgroundAudioFeature.value().defaultOn,
            attributedTitleText: NSAttributedString(string: String.Settings.Browsing.BackgroundAudio),
            attributedStatusText: nil,
            settingDidChange: { isEnabled in
                Task { @MainActor in
                    BackgroundAudioHelper.shared.toggle(isEnabled: isEnabled, prefs: prefs)
                }
            }
        )
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Browsing.backgroundAudio
    }
}
