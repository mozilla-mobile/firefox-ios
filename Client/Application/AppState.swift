/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class AppState {
    var tab: Tab?
    var homePanelIndex: Int?
    var profile: Profile?
    var location: AppLocation?
}

enum AppLocation {
    case Tab
    case HomePanels
    case TabsTray
}
