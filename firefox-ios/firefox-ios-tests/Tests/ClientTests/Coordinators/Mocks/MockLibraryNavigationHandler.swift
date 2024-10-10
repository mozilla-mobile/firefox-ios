// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockLibraryNavigationHandler: LibraryNavigationHandler {
    var didStartCalled = 0
    var didSetNavigationBarHiddenValue = false
    var didSetNavigationBarHiddenCalled = 0
    var didShareLibraryItemCalled = 0

    func start(panelType: LibraryPanelType, navigationController: UINavigationController) {
        didStartCalled += 1
    }

    func shareLibraryItem(url: URL, sourceView: UIView) {
        didShareLibraryItemCalled += 1
    }

    func setNavigationBarHidden(_ value: Bool) {
        didSetNavigationBarHiddenValue = value
        didSetNavigationBarHiddenCalled += 1
    }
}
