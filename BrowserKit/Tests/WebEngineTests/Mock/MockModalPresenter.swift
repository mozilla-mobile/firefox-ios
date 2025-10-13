// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebEngine

class MockModalPresenter: ModalPresenter {
    var presentCalled = 0
    var canPresentCalled = 0
    var stubCanPresent = true

    func present(_ controller: UIViewController, animated: Bool) {
        presentCalled += 1
    }

    func canPresent() -> Bool {
        canPresentCalled += 1
        return stubCanPresent
    }
}
