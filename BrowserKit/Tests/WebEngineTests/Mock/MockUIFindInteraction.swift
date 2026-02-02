// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

@available(iOS 16, *)
class MockUIFindInteraction: UIFindInteraction {
    let findDelegate = MockUIFindInteractionDelegate()
    var presentFindNavigatorCalled = 0

    override func presentFindNavigator(showingReplace: Bool) {
        presentFindNavigatorCalled += 1
    }

    init() {
        super.init(sessionDelegate: findDelegate)
    }
}

@available(iOS 16, *)
class MockUIFindInteractionDelegate: NSObject, UIFindInteractionDelegate {
    var findInteractionCalled = 0
    func findInteraction(_ interaction: UIFindInteraction, sessionFor view: UIView) -> UIFindSession? {
        findInteractionCalled += 1
        return nil
    }
}
