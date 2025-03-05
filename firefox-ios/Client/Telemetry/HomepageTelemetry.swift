// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HomepageTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sendMaskToggleTappedTelemetry(enteringPrivateMode: Bool) {
        let isPrivateModeExtra = GleanMetrics.Homepage.PrivateModeToggleExtra(isPrivateMode: enteringPrivateMode)
        gleanWrapper.recordEvent(for: GleanMetrics.Homepage.privateModeToggle, extras: isPrivateModeExtra)
    }

    // MARK: - Customize Homepage
    func sendTapOnCustomizeHomepageTelemetry() {
        gleanWrapper.incrementCounter(for: GleanMetrics.FirefoxHomePage.customizeHomepageButton)
    }
}
