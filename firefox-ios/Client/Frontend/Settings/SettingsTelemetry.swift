// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Note: We will be slowly migrating our existing settings (i.e. "preferences") telemetry probes over to a "settings"
/// namespace.
struct SettingsTelemetry {
    private let gleanWrapper: GleanWrapper

    enum MainMenuOption: String {
        case AppIcon = "app_icon"
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func tappedAppIconSetting() {
        let extra = GleanMetrics.SettingsMainMenu.OptionSelectedExtra(option: MainMenuOption.AppIcon.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.SettingsMainMenu.optionSelected, extras: extra)
    }
}
