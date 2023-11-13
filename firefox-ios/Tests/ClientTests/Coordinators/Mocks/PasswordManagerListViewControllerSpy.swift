// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
@testable import Client

class PasswordManagerListViewControllerSpy: PasswordManagerListViewController {
    var presentCalled = 0
    var viewControllerToPresent: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        presentCalled += 1
        self.viewControllerToPresent = viewControllerToPresent
    }
}
