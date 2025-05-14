// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ZoomTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func zoomIn(zoomLevel: ZoomLevel) {
        let extra = GleanMetrics.ZoomBar.ZoomInButtonTappedExtra(level: zoomLevel.telemetryQuantity)
        gleanWrapper.recordEvent(for: GleanMetrics.ZoomBar.zoomInButtonTapped, extras: extra)
    }

    func zoomOut(zoomLevel: ZoomLevel) {
        let extra = GleanMetrics.ZoomBar.ZoomOutButtonTappedExtra(level: zoomLevel.telemetryQuantity)
        gleanWrapper.recordEvent(for: GleanMetrics.ZoomBar.zoomOutButtonTapped, extras: extra)
    }

    func resetZoomLevel() {
        gleanWrapper.recordEvent(for: GleanMetrics.ZoomBar.resetButtonTapped)
    }

    func closeZoomBar() {
        gleanWrapper.recordEvent(for: GleanMetrics.ZoomBar.closeButtonTapped)
    }
}
