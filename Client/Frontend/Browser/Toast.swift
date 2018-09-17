/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

class Toast: UIView {
    var animationConstraint: Constraint?
    var completionHandler: ((Bool) -> Void)?

    weak var viewController: UIViewController?

    var dismissed = false

    lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()

    lazy var toastView: UIView = {
        let toastView = UIView()
        toastView.backgroundColor = SimpleToastUX.ToastDefaultColor
        return toastView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addGestureRecognizer(gestureRecognizer)
    }

    func showToast(viewController: UIViewController? = nil, delay: DispatchTimeInterval, duration: DispatchTimeInterval?, makeConstraints: @escaping (SnapKit.ConstraintMaker) -> Swift.Void) {
        self.viewController = viewController

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            viewController?.view.addSubview(self)
            guard let _ = viewController else { return }

            self.snp.makeConstraints(makeConstraints)
            self.layoutIfNeeded()

            UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration, animations: {
                self.animationConstraint?.update(offset: 0)
                self.layoutIfNeeded()
            }) { finished in
                if let duration = duration {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
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
            self.animationConstraint?.update(offset: SimpleToastUX.ToastHeight)
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
