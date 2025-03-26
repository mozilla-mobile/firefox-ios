// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

/// Note: We will be slowly migrating our existing tabs telemetry probes
/// over to a "tab_tray" namespace.
struct TabTrayTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func undoSelectedOnToastForClosingAllTabs() {
        gleanWrapper.recordEvent(for: GleanMetrics.ToastsCloseAllTabs.undoSelected)
    }

    func undoSelectedOnToastForClosingOneTab() {
        gleanWrapper.recordEvent(for: GleanMetrics.ToastsCloseSingleTab.undoSelected)
    }
}
