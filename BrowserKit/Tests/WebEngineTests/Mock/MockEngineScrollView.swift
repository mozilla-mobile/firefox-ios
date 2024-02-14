// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockEngineScrollView: WKScrollView {
    var setContentOffsetCalled = 0
    var savedContentOffset: CGPoint?

    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        setContentOffsetCalled += 1
        savedContentOffset = contentOffset
    }
}
