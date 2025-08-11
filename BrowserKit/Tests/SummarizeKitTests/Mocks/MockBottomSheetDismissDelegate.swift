// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import ComponentLibrary

class MockBottomSheetDismissDelegate: BottomSheetDelegate {
    var didCallDismissSheetViewController = 0

    func dismissSheetViewController(completion: (() -> Void)?) {
        didCallDismissSheetViewController += 1
        completion?()
    }

    func getBottomSheetHeaderHeight() -> CGFloat {
        return 0.0
    }
}
