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

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Recorded when a user taps a row on the settings screen (or one of its subscreens) to drill deeper into the settings.
    /// - Parameter option: A unique identifier for the selected row. Identifies the row tapped, not the screen shown.
    func optionSelected(option: OptionIdentifiers) {
        let extra = GleanMetrics.Settings.OptionSelectedExtra(option: option.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Settings.optionSelected, extras: extra)
    }
}
