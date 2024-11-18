// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// View types that the browser coordinator can navigate to
enum BrowserNavigationDestination: Equatable {
    // Native views
    case customizeHomepage

    // Webpage views
    case link

    // Context menu views
    case contextMenu
}

/// This type exists as a field on the BrowserViewControllerState
struct NavigationDestination: Equatable {
    let destination: BrowserNavigationDestination
    let url: URL?
    let isGoogleTopSite: Bool?

    init(
        _ destination: BrowserNavigationDestination,
        url: URL? = nil,
        isGoogleTopSite: Bool? = nil
    ) {
        self.destination = destination
        self.url = url
        self.isGoogleTopSite = isGoogleTopSite
    }
}
