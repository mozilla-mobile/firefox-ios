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

    // MARK: - Pocket
    func sendTapOnPocketStoryCounter(position: Int, isZeroSearch: Bool = false) {
        let originExtra: TelemetryWrapper.EventValue = isZeroSearch ? .fxHomepageOriginZeroSearch : .fxHomepageOriginOther
        gleanWrapper.recordLabel(for: GleanMetrics.Pocket.openStoryOrigin, label: originExtra.rawValue)
        gleanWrapper.recordLabel(for: GleanMetrics.Pocket.openStoryPosition, label: "position-\(position)")
    }

    func sendPocketSectionCounter() {
        gleanWrapper.incrementCounter(for: GleanMetrics.Pocket.sectionImpressions)
    }

    func sendOpenInPrivateTabEvent() {
        gleanWrapper.recordEvent(for: GleanMetrics.Pocket.openInPrivateTab)
    }

    // MARK: - Customize Homepage
    func sendTapOnCustomizeHomepageTelemetry() {
        gleanWrapper.incrementCounter(for: GleanMetrics.FirefoxHomePage.customizeHomepageButton)
    }
}
