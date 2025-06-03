// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct MainMenuTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func mainMenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.MainMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        gleanWrapper.recordEvent(for: GleanMetrics.AppMenu.mainMenuOptionSelected, extras: extra)
    }

    func saveSubmenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.SaveMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        gleanWrapper.recordEvent(for: GleanMetrics.AppMenu.saveMenuOptionSelected, extras: extra)
    }

    func toolsSubmenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.ToolsMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        gleanWrapper.recordEvent(for: GleanMetrics.AppMenu.toolsMenuOptionSelected, extras: extra)
    }

    func closeButtonTapped(isHomepage: Bool) {
        let extra = GleanMetrics.AppMenu.CloseButtonExtra(isHomepage: isHomepage)
        gleanWrapper.recordEvent(for: GleanMetrics.AppMenu.closeButton, extras: extra)
    }

    func menuDismissed(isHomepage: Bool) {
        let extra = GleanMetrics.AppMenu.MenuDismissedExtra(isHomepage: isHomepage)
        gleanWrapper.recordEvent(for: GleanMetrics.AppMenu.menuDismissed, extras: extra)
    }
}
