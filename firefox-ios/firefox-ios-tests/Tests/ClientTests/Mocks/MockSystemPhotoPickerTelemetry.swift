// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockSystemPhotoPickerTelemetry: SystemPhotoPickerTelemetryProtocol {
    private(set) var shownCalled = 0
    private(set) var closedCalled = 0
    private(set) var photoSelectedCalled = 0
    private(set) var savedShownReason: PhotoPickerReason?
    private(set) var savedClosedReason: PhotoPickerReason?
    private(set) var savedPhotoSelectedReason: PhotoPickerReason?

    func shown(reason: PhotoPickerReason) {
        shownCalled += 1
        savedShownReason = reason
    }

    func closed(reason: PhotoPickerReason) {
        closedCalled += 1
        savedClosedReason = reason
    }

    func photoSelected(reason: PhotoPickerReason) {
        photoSelectedCalled += 1
        savedPhotoSelectedReason = reason
    }
}
