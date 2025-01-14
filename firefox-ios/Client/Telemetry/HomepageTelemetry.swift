// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol GleanWrapperProtocol {
    func recordPrivateModeToggle(isPrivateMode: Bool)
}

class CustomGleanWrapper: GleanWrapperProtocol {
    func recordPrivateModeToggle(isPrivateMode: Bool) {
        let isPrivateModeExtra = GleanMetrics.Homepage.PrivateModeToggleExtra(isPrivateMode: isPrivateMode)
        GleanMetrics.Homepage.privateModeToggle.record(isPrivateModeExtra)
    }
}

struct HomepageTelemetry {
    private let gleanWrapper: GleanWrapperProtocol

    init(gleanWrapper: GleanWrapperProtocol = CustomGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sendHomepageTappedTelemetry(enteringPrivateMode: Bool) {
        gleanWrapper.recordPrivateModeToggle(isPrivateMode: enteringPrivateMode)
    }
}
