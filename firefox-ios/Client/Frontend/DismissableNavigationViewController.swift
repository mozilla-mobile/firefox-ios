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

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        transitionCoordinator?.animate(alongsideTransition: nil) { [weak self] _ in
            self?.announceNavigationBarTitle()
        }
    }

    private func announceNavigationBarTitle() {
        for index in 0..<navigationBar.accessibilityElementCount() {
            guard let element = navigationBar.accessibilityElement(at: index) as? NSObject,
                  element.accessibilityTraits.contains(.header) else { continue }

            UIAccessibility.post(notification: .layoutChanged, argument: element)
            return
        }
    }
}
