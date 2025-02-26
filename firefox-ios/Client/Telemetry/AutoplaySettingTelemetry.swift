// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

class AutoplaySettingTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    enum EventExtraKey: String {
        case mediaType
    }

    func settingChanged(mediaType: AutoplayAction) {
        let extras = GleanMetrics.Preferences.AutoplaySettingChangedExtra(mediaType: mediaType.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.Preferences.autoplaySettingChanged,
                                 extras: extras)
    }
}
