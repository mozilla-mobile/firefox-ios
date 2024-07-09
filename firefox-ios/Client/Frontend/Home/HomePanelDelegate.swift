// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

import enum MozillaAppServices.VisitType

protocol HomePanelDelegate: AnyObject {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool)
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?, focusedSegment: TabTrayPanelType?)
    func homePanelDidRequestToOpenSettings(at settingsPage: Route.SettingsSection)
    func homePanelDidRequestBookmarkToast(url: URL?, action: BookmarkAction)
}

extension HomePanelDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab? = nil,
                                          focusedSegment: TabTrayPanelType? = nil) {
        homePanelDidRequestToOpenTabTray(withFocusedTab: tabToFocus, focusedSegment: focusedSegment)
    }
}
