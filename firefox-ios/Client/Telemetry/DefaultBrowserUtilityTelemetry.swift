// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct DefaultBrowserUtilityTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func recordAppIsDefaultBrowser(_ isDefaultBrowser: Bool) {
//        GleanMetrics.App.defaultBrowser.set(isDefaultBrowser)
        gleanWrapper.setBoolean(for: GleanMetrics.App.defaultBrowser, value: isDefaultBrowser)
    }

    func recordIsUserChoiceScreenAcquisition(_ isChoiceScreenAcquisition: Bool) {
        gleanWrapper.setBoolean(for: GleanMetrics.App.choiceScreenAcquisition, value: isChoiceScreenAcquisition)
//        GleanMetrics.App.choiceScreenAcquisition.set(isChoiceScreenAcquisition)
    }
}
