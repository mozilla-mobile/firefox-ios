// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import VPNKit

struct DefaultVPNTelemetry: VPNTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func record(_ event: VPNTelemetryEvent) {
        switch event {
        case .attestationSucceeded:
            gleanWrapper.recordEvent(for: GleanMetrics.VpnAttestation.succeeded)
        case .attestationFailed(let reason):
            let extras = GleanMetrics.VpnAttestation.FailedExtra(failureReason: reason.rawValue)
            gleanWrapper.recordEvent(for: GleanMetrics.VpnAttestation.failed, extras: extras)
        }
    }
}
