// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ActionExtensionTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Records when a user shares a URL from the Action Extension
    func shareURL() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.urlShared)
    }

    /// Records when a user shares text from the Action Extension
    func shareText() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShareOpenInFirefoxExtension.textShared)
    }
}
