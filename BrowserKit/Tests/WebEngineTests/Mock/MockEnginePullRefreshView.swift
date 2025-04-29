// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine
import UIKit

class MockEnginePullRefreshView: UIView, EnginePullRefreshView {
    var configureCalled = 0
    var onRefresh: (() -> Void)?

    func configure(with scrollView: UIScrollView, onRefresh: @escaping () -> Void) {
        configureCalled += 1
        self.onRefresh = onRefresh
    }
}
