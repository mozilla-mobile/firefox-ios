// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct PrivateBrowsingTelemetry {
    func sendDataClearanceTappedTelemetry(didConfirm: Bool) {
        let didConfirmExtra = GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra(didConfirm: didConfirm)
        GleanMetrics.PrivateBrowsing.dataClearanceIconTapped.record(didConfirmExtra)
    }
}
