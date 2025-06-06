// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Note: We will be slowly migrating our existing settings (i.e. "preferences") telemetry probes over to a "settings"
/// namespace.
struct SettingsTelemetry {
    private let gleanWrapper: GleanWrapper

    /// Uniquely identifies a row on the settings screen (or one of its subscreens), which the user can tap to drill down
    /// deeper into settings.
    ///
    /// If the row moves somewhere else due to a refactor or an experiment, the key should stay the same. The most important
    /// feature of the key is that it identifies the tapped row irrespective of its location in the settings hierarchy.
    ///
    /// Note that the `option` identifies the __row tapped__, not necessarily the screen shown.
    enum OptionIdentifiers: String {
        case AppIconSelection = "app_icon_selection" // Tapping "App Icon >" to show the App Icon Selection screen
    }

    /// Uniquely identifies a setting in the Settings screen hierarchy irrespective of its placement.
    enum SettingKey: String {
        // TODO
        case etpStrength = "ETP-strength"
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func changedSetting(_ setting: SettingKey, to changedTo: String, from changedFrom: String) {
        if changedTo.isEmpty || changedFrom.isEmpty {
            assertionFailure("changedTo and changedFrom should be valid string extras")
        }

        let extras = GleanMetrics.Settings.ChangedExtra(
            changedFrom: changedFrom.isEmpty ? "unavailable" : changedFrom,
            changedTo: changedTo.isEmpty ? "unavailable" : changedTo,
            setting: setting.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Settings.changed, extras: extras)
    }

    /// Recorded when a user taps a row on the settings screen (or one of its subscreens) to drill deeper into the settings.
    /// - Parameter option: A unique identifier for the selected row. Identifies the row tapped, not the screen shown.
    func optionSelected(option: OptionIdentifiers) {
        let extra = GleanMetrics.Settings.OptionSelectedExtra(option: option.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Settings.optionSelected, extras: extra)
    }
    
    func tappedAppIconSetting() {
        let extra = GleanMetrics.SettingsMainMenu.OptionSelectedExtra(option: MainMenuOption.AppIcon.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.SettingsMainMenu.optionSelected, extras: extra)
    }
}
