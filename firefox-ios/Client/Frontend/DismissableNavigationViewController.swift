// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
protocol OnViewDismissable: AnyObject {
    var onViewDismissed: (() -> Void)? { get set }
}

class DismissableNavigationViewController: UINavigationController, OnViewDismissable {
    @MainActor
    var onViewDismissed: (() -> Void)?
    var onViewWillDisappear: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onViewWillDisappear?()
        onViewWillDisappear = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }
}
