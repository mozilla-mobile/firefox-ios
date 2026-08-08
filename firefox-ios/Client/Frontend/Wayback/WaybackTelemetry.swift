// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

struct WaybackTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func checkArchiveButtonTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WebviewErrorPageWaybackMachine.checkArchiveButtonTapped)
    }

    func foundArchive() {
        gleanWrapper.recordEvent(for: GleanMetrics.WebviewErrorPageWaybackMachine.archiveFound)
    }

    func searchTheWebButtonTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WebviewErrorPageWaybackMachine.searchTheWebButtonTapped)
    }
}
