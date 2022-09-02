// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol to present a view controller
protocol Presenter {
    func present(_ viewControllerToPresent: UIViewController,
                 animated flag: Bool,
                 completion: (() -> Void)?)
}

extension Presenter {
    func present(_ viewControllerToPresent: UIViewController,
                 animated flag: Bool,
                 completion: (() -> Void)? = nil) {
        present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension UIViewController: Presenter {}
