// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

enum TabGroupTimerState: Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case openURLOnly
    case none
}

struct TabGroupData: Codable {
    var tabAssociatedSearchTerm: String?
    var tabAssociatedSearchUrl: String?
    var tabAssociatedNextUrl: String?
    var tabHistoryCurrentState: TabGroupTimerState?
}
