// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct ShortcutsLibraryTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sendShortcutsLibraryViewedEvent() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShortcutsLibrary.viewed)
    }

    func sendShortcutTappedEvent() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShortcutsLibrary.shortcutTapped)
    }

    func sendShortcutsLibraryClosedEvent() {
        gleanWrapper.recordEvent(for: GleanMetrics.ShortcutsLibrary.closed)
    }
}
