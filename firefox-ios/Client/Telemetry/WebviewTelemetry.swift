// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Measure with a time distribution https://mozilla.github.io/glean/book/reference/metrics/timing_distribution.html
/// how long it takes to load a webpage
final class WebViewLoadMeasurementTelemetry {
    private let gleanWrapper: GleanWrapper
    private var loadTimerId: GleanTimerId?

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func start() {
        loadTimerId = gleanWrapper.startTiming(for: GleanMetrics.Webview.pageLoad)
    }

    func stop() {
        guard let timerId = loadTimerId else { return }
        gleanWrapper.stopAndAccumulateTiming(for: GleanMetrics.Webview.pageLoad, timerId: timerId)
        loadTimerId = nil
    }

    func cancel() {
        if let timerId = loadTimerId {
            gleanWrapper.cancelTiming(for: GleanMetrics.Webview.pageLoad, timerId: timerId)
        }
    }
}
