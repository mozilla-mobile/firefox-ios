// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import enum MozillaAppServices.VisitType

protocol HomePanelDelegate: AnyObject {
    @MainActor
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    @MainActor
    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool)
    @MainActor
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType)
    @MainActor
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?, focusedSegment: TabTrayPanelType?)
    @MainActor
    func homePanelDidRequestToOpenSettings(at settingsPage: Route.SettingsSection)
    @MainActor
    func homePanelDidRequestBookmarkToast(urlString: String?, action: BookmarkAction)
}

extension HomePanelDelegate {
    @MainActor
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    @MainActor
    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab? = nil,
                                          focusedSegment: TabTrayPanelType? = nil) {
        homePanelDidRequestToOpenTabTray(withFocusedTab: tabToFocus, focusedSegment: focusedSegment)
    }
}
