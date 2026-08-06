// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

protocol SystemPhotoPickerTelemetryProtocol {
    func shown(reason: PhotoPickerReason)
    func closed(reason: PhotoPickerReason, photoSelected: Bool)
}

struct SystemPhotoPickerTelemetry: SystemPhotoPickerTelemetryProtocol {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func shown(reason: PhotoPickerReason) {
        let extra = GleanMetrics.SystemPhotoPicker.ShownExtra(reason: reason.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.SystemPhotoPicker.shown, extras: extra)
    }

    func closed(reason: PhotoPickerReason, photoSelected: Bool) {
        let extra = GleanMetrics.SystemPhotoPicker.ClosedExtra(
            photoSelected: photoSelected,
            reason: reason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.SystemPhotoPicker.closed, extras: extra)
    }
}
