// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockBrowserViewController: BrowserViewController {
    var switchToPrivacyModeCalled: (Bool) -> Void = { _ in }
    var switchToTabForURLOrOpenCalled: (Bool) -> Void = { _ in }
    var openBlankNewTabCalled: (Bool) -> Void = { _ in }
    var handleQueryCalled: (String) -> Void = { _ in }

    override func switchToPrivacyMode(isPrivate: Bool) {
        switchToPrivacyModeCalled(true)
    }

    override func switchToTabForURLOrOpen(_ url: URL, uuid: String? = nil, isPrivate: Bool = false) {
        switchToTabForURLOrOpenCalled(true)
    }

    override func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false, searchFor searchText: String? = nil) {
        openBlankNewTabCalled(true)
    }

    override func handle(query: String) {
        handleQueryCalled(query)
    }
}
