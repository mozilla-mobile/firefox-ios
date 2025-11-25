// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct RelayMaskTelemetry {
    private let gleanWrapper: GleanWrapper
    static let defaultZoomExtraKey = "autofill.email_mask"

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func showPrompt() {
        gleanWrapper.recordEvent(for: GleanMetrics.EmailMask.promptShown)
    }
}
