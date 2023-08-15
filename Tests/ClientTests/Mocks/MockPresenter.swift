// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockPresenter: Presenter {
    var savedViewControllerToPresent: UIViewController?
    var savedAnimated: Bool?
    var savedCompletion: (() -> Void)?

    func present(_ viewControllerToPresent: UIViewController,
                 animated flag: Bool,
                 completion: (() -> Void)?) {
        savedViewControllerToPresent = viewControllerToPresent
        savedAnimated = flag
        savedCompletion = completion
    }
}
