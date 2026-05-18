// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class FeatureFlagsBoolSetting: BoolSetting, FeatureFlaggable {
    override func displayBool(_ control: UISwitch) {
        if let featureFlagName = getFeatureFlagName() {
            control.isOn = featureFlagsProvider.isEnabled(featureFlagName)
        } else {
            guard let key = prefKey, let defaultValue = getDefaultValue(), let prefs else { return }
            control.isOn = prefs.boolForKey(key) ?? defaultValue
        }
    }

    override func writeBool(_ control: UISwitch) {
        if let featureFlagName = getFeatureFlagName() {
            featureFlagsProvider.setDebugOverride(featureFlagName, to: control.isOn)
        } else {
            guard let key = prefKey, let prefs else { return }
            prefs.setBool(control.isOn, forKey: key)
        }
    }
}
