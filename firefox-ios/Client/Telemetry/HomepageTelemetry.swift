// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct HomepageTelemetry {
    func sendHomepageTappedTelemetry(enteringPrivateMode: Bool) {
        let isPrivateModeExtra = GleanMetrics.Homepage.PrivateModeToggleExtra(isPrivateMode: enteringPrivateMode)
        GleanMetrics.Homepage.privateModeToggle.record(isPrivateModeExtra)
    }
}
