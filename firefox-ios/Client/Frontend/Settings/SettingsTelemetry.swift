// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct SettingsTelemetry {
    private let gleanWrapper: GleanWrapper

    /// Standard fallback values to use in telemetry when needed (e.g. missing data).
    struct Placeholders {
        /// Used when a value is not available to send (e.g. settings.changed changedFrom value missing)
        static let missingValue = "unavailable"
    }

    /// Uniquely identifies a row on the settings screen (or one of its subscreens), which the user can tap to drill down
    /// deeper into settings. The identifier is irrespective of the row's location in the settings hierarchy.
    ///
    /// Note that the `option` identifies the __row tapped__, not necessarily the screen shown.
    enum OptionIdentifiers: String {
        case AppIconSelection = "app_icon_selection" // Tapping "App Icon >" to show the App Icon Selection screen
    }

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Records the event of a user changing a setting in one of the Settings screens.
    /// - Parameters:
    ///   - setting: A key uniquely identifying a setting in the Settings screen hierarchy irrespective of its placement.
    ///              This key should not change even if the setting is moved to another screen later.
    ///              Most often these are `PrefKeys`, `AppConstants`, or feature flag names, but any unique identifier may be
    ///              used.
    ///   - changedTo: The new value of the setting, recorded as a string.
    ///   - changedFrom: The previous value of the setting, recorded as a string.
    func changedSetting(_ setting: String, to changedTo: String, from changedFrom: String) {
        if changedTo.isEmpty || changedFrom.isEmpty {
            assertionFailure("changedTo and changedFrom should be valid string extras")
        }

        let extras = GleanMetrics.Settings.ChangedExtra(
            changedFrom: changedFrom.isEmpty ? "unavailable" : changedFrom,
            changedTo: changedTo.isEmpty ? "unavailable" : changedTo,
            setting: setting
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Settings.changed, extras: extras)

        // Continue to record the `preferences.changed` until it's expired and we deprecate it in favor of `settings.changed`
        let deprecatedExtras = GleanMetrics.Preferences.ChangedExtra(
            changedTo: changedTo,
            preference: setting
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Preferences.changed, extras: deprecatedExtras)
    }

    /// Recorded when a user taps a row on the settings screen (or one of its subscreens) to drill deeper into the settings.
    /// - Parameter option: A unique identifier for the selected row. Identifies the row tapped, not the screen shown.
    func optionSelected(option: OptionIdentifiers) {
        let extra = GleanMetrics.Settings.OptionSelectedExtra(option: option.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Settings.optionSelected, extras: extra)
    }
}
