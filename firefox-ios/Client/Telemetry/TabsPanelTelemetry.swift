// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Common

struct TabsPanelTelemetry {
    enum Mode: String {
        case normal
        case `private`
        case sync

        var hasNewTabButton: Bool {
            switch self {
            case .normal, .private:
                return true
            default:
                return false
            }
        }
    }

    private let gleanWrapper: GleanWrapper
    private let logger: Logger

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(), logger: Logger = DefaultLogger.shared) {
        self.gleanWrapper = gleanWrapper
        self.logger = logger
    }

    func newTabButtonTapped(mode: Mode) {
        guard mode.hasNewTabButton else {
            logger.log("Mode is not of expected mode types for new button", level: .debug, category: .tabs)
            return
        }

        let extras = GleanMetrics.TabsPanel.NewTabButtonTappedExtra(mode: mode.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.newTabButtonTapped, extras: extras)
    }

    func tabModeSelected(mode: Mode) {
        let extras = GleanMetrics.TabsPanel.TabModeSelectedExtra(mode: mode.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.tabModeSelected, extras: extras)
    }
}
