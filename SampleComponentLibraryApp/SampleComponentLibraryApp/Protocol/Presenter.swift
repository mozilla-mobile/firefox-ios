// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

protocol Presenter: AnyObject {
    func present(viewController: UIViewController)
}

extension Presenter where Self: UIViewController {
    func present(viewController: UIViewController) {
        present(viewController, animated: true)
    }
}

