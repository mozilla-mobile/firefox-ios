// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Common

struct TabsPanelTelemetry {
    struct Mode: OptionSet {
        let rawValue: Int

        static let `private` = Mode(rawValue: 1 << 0)
        static let normal = Mode(rawValue: 1 << 1)
        static let sync = Mode(rawValue: 1 << 2)

        static let newButtonModes: Mode = [.private, .normal]
        static let allModes: Mode = [.private, .normal, .sync]

        static func mode(isPrivate: Bool) -> Mode {
            return isPrivate ? .private : .normal
        }
    }

    private let gleanWrapper: GleanWrapper
    private let logger: Logger

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(), logger: Logger = DefaultLogger.shared) {
        self.gleanWrapper = gleanWrapper
        self.logger = logger
    }

    func newTabButtonTapped(mode: Mode) {
        guard Mode.newButtonModes.contains(mode) else {
            logger.log("Mode is not of expected mode types for new button", level: .fatal, category: .tabs)
            return
        }

        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.newTabButtonTapped)
    }

    func tabModeSelected(fromMode: Mode, toMode: Mode) {
        gleanWrapper.recordEvent(for: GleanMetrics.TabsPanel.tabModeSelected)
    }
}
