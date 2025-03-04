// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct AppIconSelectionTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func selectedIcon(_ selectedIcon: AppIcon, previousIcon: AppIcon?) {
        // We log app icon names by their English enum value rather than localized display names
        let extra = GleanMetrics.SettingsAppIcon.SelectedExtra(
            newName: selectedIcon.telemetryName,
            oldName: previousIcon?.telemetryName ?? "unknown"
        )
        gleanWrapper.recordEvent(for: GleanMetrics.SettingsAppIcon.selected, extras: extra)
    }
}
