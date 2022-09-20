// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import SnapKit

class Toast: UIView {
    var animationConstraint: Constraint?
    var completionHandler: ((Bool) -> Void)?
    var didDismissWithoutTapHandler: (() -> Void)?

    weak var viewController: UIViewController?

    var dismissed = false

    lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        return gestureRecognizer
    }()

    lazy var toastView: UIView = .build { view in
        view.backgroundColor = SimpleToastUX.ToastDefaultColor
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addGestureRecognizer(gestureRecognizer)
    }

    func showToast(viewController: UIViewController? = nil,
                   delay: DispatchTimeInterval,
                   duration: DispatchTimeInterval?,
                   updateConstraintsOn: @escaping (Toast) -> [NSLayoutConstraint]) {
        self.viewController = viewController

        translatesAutoresizingMaskIntoConstraints = false

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            viewController?.view.addSubview(self)
            guard let _ = viewController else { return }

            NSLayoutConstraint.activate(updateConstraintsOn(self))
            self.layoutIfNeeded()

            UIView.animate(
                withDuration: SimpleToastUX.ToastAnimationDuration,
                animations: {
                    self.animationConstraint?.update(offset: 0) // TODO Ecosia: verify
                    self.layoutIfNeeded()
                }) { finished in
                    if let duration = duration {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            self.didDismissWithoutTapHandler?()
                            self.dismiss(false)
                        }
                    }
                }
        }
    }

    func dismiss(_ buttonPressed: Bool) {
        guard !dismissed else { return }
        dismissed = true
        superview?.removeGestureRecognizer(gestureRecognizer)

        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
            self.animationConstraint?.update(offset: SimpleToastUX.ToastHeight + SimpleToastUX.Offset)
            self.layoutIfNeeded()
        }) { finished in
            self.removeFromSuperview()
            if !buttonPressed {
                self.completionHandler?(false)
            }
        }
    }

    @objc func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        dismiss(false)
    }
}
