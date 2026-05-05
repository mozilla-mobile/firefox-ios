// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class MockPresenter: UIViewController {
    var presentCallCount = 0
    var lastPresentedViewController: UIViewController?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentCallCount += 1
        lastPresentedViewController = viewControllerToPresent
        completion?()
    }
}
