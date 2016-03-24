/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation


enum AppLocation {
    case Browser
    case HomePanels
    case TabTray
    case Settings
}

struct AppState {
    var isBookmarked: Bool = false
    var currentLocation: AppLocation = .Browser
    var isDesktopSite: Bool = false
    var hasAccount: Bool = false
    var homePanelIndex: Int = 0
    var currentURL: NSURL? = nil
}
