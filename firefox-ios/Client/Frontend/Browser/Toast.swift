// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared

class Toast: UIView, ThemeApplicable {
    struct UX {
        static let toastHeightWithoutShadow: CGFloat = 56
        static let toastHeightWithShadow: CGFloat = 68
        static let toastDismissAfter = DispatchTimeInterval.milliseconds(4500) // 4.5 seconds.
        static let toastDelayBefore = DispatchTimeInterval.milliseconds(0) // 0 seconds
        static let toastPrivateModeDelayBefore = DispatchTimeInterval.milliseconds(750)
        static let toastAnimationDuration = 0.5
        static let toastCornerRadius: CGFloat = 8
        static let toastSidePadding: CGFloat = 16

        // Shadow
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1
        static let shadowHorizontalSpacing: CGFloat = 16 // Accounts for top and bottom shadow
        static let shadowVerticalSpacing: CGFloat = 8
    }

    var animationConstraint: NSLayoutConstraint?
    var completionHandler: ((Bool) -> Void)?

    weak var viewController: UIViewController?

    var dismissed = false

    lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()

    lazy var toastView: UIView = .build { _ in }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addGestureRecognizer(gestureRecognizer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: self.toastView.bounds,
            cornerRadius: UX.toastCornerRadius
        ).cgPath
    }

    func showToast(viewController: UIViewController? = nil,
                   delay: DispatchTimeInterval,
                   duration: DispatchTimeInterval?,
                   updateConstraintsOn: @escaping (Toast) -> [NSLayoutConstraint]) {
        self.viewController = viewController

        translatesAutoresizingMaskIntoConstraints = false

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            viewController?.view.addSubview(self)
            guard viewController != nil else { return }

            NSLayoutConstraint.activate(updateConstraintsOn(self))
            self.layoutIfNeeded()

            UIView.animate(
                withDuration: UX.toastAnimationDuration,
                animations: {
                    self.animationConstraint?.constant = UX.shadowRadius
                    self.layoutIfNeeded()
                }
            ) { finished in
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

        UIView.animate(
            withDuration: UX.toastAnimationDuration,
            animations: {
                self.animationConstraint?.constant = UX.toastHeightWithShadow
                self.layoutIfNeeded()
            }
        ) { finished in
            self.removeFromSuperview()
            if !buttonPressed {
                self.completionHandler?(false)
            }
        }
    }

    @objc
    func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        dismiss(false)
    }

    func applyTheme(theme: Theme) {
        toastView.backgroundColor = theme.colors.actionPrimary
        setupShadow(theme: theme)
    }

    private func setupShadow(theme: Theme) {
        toastView.layer.cornerRadius = UX.toastCornerRadius
        toastView.layer.shadowRadius = UX.shadowRadius
        toastView.layer.shadowOffset = UX.shadowOffset
        toastView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        toastView.layer.shadowOpacity = UX.shadowOpacity
    }
}
