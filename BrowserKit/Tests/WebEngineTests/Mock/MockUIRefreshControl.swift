// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class MockUIRefreshControl: UIRefreshControl {
    var beginRefreshingCalled = 0
    var endRefreshingCalled = 0

    override func beginRefreshing() {
        beginRefreshingCalled += 1
    }

    override func endRefreshing() {
        endRefreshingCalled += 1
    }
}
