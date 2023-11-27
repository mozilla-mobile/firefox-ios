// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum TabGroupTimerState: String, Codable {
    case navSearchLoaded
    case tabNavigatedToDifferentUrl
    case tabSwitched
    case tabSelected
    case newTab
    case openInNewTab
    case openURLOnly
    case none
}

public struct TabGroupData: Codable {
    public var searchTerm: String?
    public var searchUrl: String?
    public var nextUrl: String?
    public var tabHistoryCurrentState: TabGroupTimerState?

    public init(searchTerm: String? = nil,
                searchUrl: String? = nil,
                nextUrl: String? = nil,
                tabHistoryCurrentState: TabGroupTimerState? = nil) {
        self.searchTerm = searchTerm
        self.searchUrl = searchUrl
        self.nextUrl = nextUrl
        self.tabHistoryCurrentState = tabHistoryCurrentState
    }
}
