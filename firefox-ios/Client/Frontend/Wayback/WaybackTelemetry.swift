// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

struct WaybackTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func searchForArchiveTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WaybackErrorPage.checkButton)
    }

    func foundArchive() {
        gleanWrapper.recordEvent(for: GleanMetrics.WaybackErrorPage.archiveFound)
    }

    func searchTheWebTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.WaybackErrorPage.searchTheWeb)
    }
}
