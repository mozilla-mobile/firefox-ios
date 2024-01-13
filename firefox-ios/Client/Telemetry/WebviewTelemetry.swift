// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Measure with a time distribution https://mozilla.github.io/glean/book/reference/metrics/timing_distribution.html
/// how long it takes to load a webpage
final class WebViewLoadMeasurementTelemetry {
    private var loadTimerId: GleanTimerId?

    func start() {
        loadTimerId = GleanMetrics.Webview.pageLoad.start()
    }

    func stop() {
        guard let timerId = loadTimerId else { return }
        GleanMetrics.Webview.pageLoad.stopAndAccumulate(timerId)
    }

    func cancel() {
        if let loadTimerId {
            GleanMetrics.Webview.pageLoad.cancel(loadTimerId)
        }
    }
}
