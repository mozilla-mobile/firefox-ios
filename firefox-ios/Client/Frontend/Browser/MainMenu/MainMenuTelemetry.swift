// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct MainMenuTelemetry {
    func mainMenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.MainMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        GleanMetrics.AppMenu.mainMenuOptionSelected.record(extra)
    }

    func saveSubmenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.SaveMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        GleanMetrics.AppMenu.saveMenuOptionSelected.record(extra)
    }

    func toolsSubmenuOptionTapped(with isHomepage: Bool, and option: String) {
        let extra = GleanMetrics.AppMenu.ToolsMenuOptionSelectedExtra(isHomepage: isHomepage, option: option)
        GleanMetrics.AppMenu.toolsMenuOptionSelected.record(extra)
    }

    func closeButtonTapped(isHomepage: Bool) {
        let extra = GleanMetrics.AppMenu.CloseButtonExtra(isHomepage: isHomepage)
        GleanMetrics.AppMenu.closeButton.record(extra)
    }

    func menuDismissed(isHomepage: Bool) {
        let extra = GleanMetrics.AppMenu.MenuDismissedExtra(isHomepage: isHomepage)
        GleanMetrics.AppMenu.menuDismissed.record(extra)
    }
}
