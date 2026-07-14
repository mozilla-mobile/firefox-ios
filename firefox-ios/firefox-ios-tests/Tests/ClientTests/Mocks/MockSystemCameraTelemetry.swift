// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockSystemCameraTelemetry: SystemCameraTelemetryProtocol {
    private(set) var permissionRespondedCalled = 0
    private(set) var savedReason: CameraReason?
    private(set) var savedGranted: Bool?

    func permissionResponded(reason: CameraReason, granted: Bool) {
        permissionRespondedCalled += 1
        savedReason = reason
        savedGranted = granted
    }
}
