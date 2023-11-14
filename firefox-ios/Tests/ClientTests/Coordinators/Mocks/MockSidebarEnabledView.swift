// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockSidebarEnabledView: UIView, SidebarEnabledViewProtocol {
    var showSidebarCalled = 0
    var hideSidebarCalled = 0
    var updateSidebarCalled = 0

    func showSidebar(_ viewController: UIViewController, parentViewController: UIViewController) {
        showSidebarCalled += 1
    }

    func hideSidebar(_ parentViewController: UIViewController) {
        hideSidebarCalled += 1
    }

    func updateSidebar(_ viewModel: Client.FakespotViewModel, parentViewController: UIViewController) {
        updateSidebarCalled += 1
    }
}
