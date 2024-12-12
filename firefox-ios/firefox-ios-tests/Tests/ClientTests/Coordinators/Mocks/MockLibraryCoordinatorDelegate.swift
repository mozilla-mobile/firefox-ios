// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

@testable import Client

import enum MozillaAppServices.VisitType

class MockLibraryCoordinatorDelegate: LibraryCoordinatorDelegate, LibraryPanelDelegate {
    var libraryPanelWindowUUID: WindowUUID { return WindowUUID.XCTestDefaultUUID }
    var didFinishSettingsCalled = 0
    var didRequestToOpenInNewTabCalled = false
    var didSelectURLCalled = false
    var didOpenRecentlyClosedSiteInNewTab = 0
    var lastOpenedURL: URL?
    var lastVisitType: VisitType?
    var isPrivate = false

    func didFinishLibrary(from coordinator: LibraryCoordinator) {
        didFinishSettingsCalled += 1
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        didRequestToOpenInNewTabCalled = true
        lastOpenedURL = url
        self.isPrivate = isPrivate
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        didSelectURLCalled = true
        lastOpenedURL = url
        lastVisitType = visitType
    }

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        didOpenRecentlyClosedSiteInNewTab += 1
    }
}
