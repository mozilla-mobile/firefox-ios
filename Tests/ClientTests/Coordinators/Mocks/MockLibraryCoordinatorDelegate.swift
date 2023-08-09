// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
@testable import Client

class MockLibraryCoordinatorDelegate: LibraryCoordinatorDelegate, LibraryPanelDelegate {
    var didFinishSettingsCalled = 0
    var didRequestToOpenInNewTabCalled = false
    var didSelectURLCalled = false
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
}
