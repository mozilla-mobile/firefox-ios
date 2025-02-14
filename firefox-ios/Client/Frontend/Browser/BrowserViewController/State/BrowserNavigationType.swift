// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import enum MozillaAppServices.VisitType

/// View types that the browser coordinator can navigate to
enum BrowserNavigationDestination: Equatable {
    // Native views
    case contextMenu
    case settings(Route.SettingsSection)
    case trackingProtectionSettings
    case tabTray(TabTrayPanelType)
    case bookmarksPanel

    // Webpage views
    case link
    case newTab

    // System views
    case shareSheet(ShareSheetConfiguration)
}

struct ShareSheetConfiguration: Equatable {
    let shareType: ShareType
    let shareMessage: ShareMessage?
    let sourceView: UIView
    let sourceRect: CGRect?
    let toastContainer: UIView
    let popoverArrowDirection: UIPopoverArrowDirection
}

/// This type exists as a field on the BrowserViewControllerState
struct NavigationDestination: Equatable {
    let destination: BrowserNavigationDestination
    let url: URL?
    let isPrivate: Bool?
    let selectNewTab: Bool?
    let isGoogleTopSite: Bool?
    let visitType: VisitType?
    let contextMenuConfiguration: ContextMenuConfiguration?

    init(
        _ destination: BrowserNavigationDestination,
        url: URL? = nil,
        isPrivate: Bool? = nil,
        selectNewTab: Bool? = nil,
        isGoogleTopSite: Bool? = nil,
        visitType: VisitType? = nil,
        contextMenuConfiguration: ContextMenuConfiguration? = nil
    ) {
        self.destination = destination
        self.url = url
        self.isPrivate = isPrivate
        self.selectNewTab = selectNewTab
        self.isGoogleTopSite = isGoogleTopSite
        self.visitType = visitType
        self.contextMenuConfiguration = contextMenuConfiguration
    }
}
