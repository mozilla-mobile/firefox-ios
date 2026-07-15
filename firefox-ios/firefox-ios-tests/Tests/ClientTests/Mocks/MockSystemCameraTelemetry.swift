// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockSystemCameraTelemetry: SystemCameraTelemetryProtocol {
    private(set) var shownCalled = 0
    private(set) var closedCalled = 0
    private(set) var permissionRespondedCalled = 0
    private(set) var photoSelectedCalled = 0
    private(set) var savedShownReason: CameraReason?
    private(set) var savedClosedReason: CameraReason?
    private(set) var savedReason: CameraReason?
    private(set) var savedPhotoSelectedReason: CameraReason?
    private(set) var savedGranted: Bool?

    func shown(reason: CameraReason) {
        shownCalled += 1
        savedShownReason = reason
    }

    func closed(reason: CameraReason) {
        closedCalled += 1
        savedClosedReason = reason
    }

    func permissionResponded(reason: CameraReason, granted: Bool) {
        permissionRespondedCalled += 1
        savedReason = reason
        savedGranted = granted
    }

    func photoSelected(reason: CameraReason) {
        photoSelectedCalled += 1
        savedPhotoSelectedReason = reason
    }
}
