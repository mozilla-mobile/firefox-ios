// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

protocol SystemCameraTelemetryProtocol {
    func shown(reason: CameraReason)
    func closed(reason: CameraReason)
    func permissionResponded(reason: CameraReason, granted: Bool)
}

struct SystemCameraTelemetry: SystemCameraTelemetryProtocol {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func shown(reason: CameraReason) {
        let extra = GleanMetrics.SystemCamera.ShownExtra(reason: reason.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.SystemCamera.shown, extras: extra)
    }

    func closed(reason: CameraReason) {
        let extra = GleanMetrics.SystemCamera.ClosedExtra(reason: reason.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.SystemCamera.closed, extras: extra)
    }

    func permissionResponded(reason: CameraReason, granted: Bool) {
        let extra = GleanMetrics.SystemCamera.PermissionRespondedExtra(
            granted: granted,
            reason: reason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.SystemCamera.permissionResponded, extras: extra)
    }
}
