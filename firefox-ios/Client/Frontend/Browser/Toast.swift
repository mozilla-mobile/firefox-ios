// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared

class Toast: UIView, ThemeApplicable {
    struct UX {
        static let toastHeight: CGFloat = 56
        static let toastDismissAfter = DispatchTimeInterval.milliseconds(4500) // 4.5 seconds.
        static let toastDelayBefore = DispatchTimeInterval.milliseconds(0) // 0 seconds
        static let toastPrivateModeDelayBefore = DispatchTimeInterval.milliseconds(750)
        static let toastAnimationDuration = 0.5
        static let toastCornerRadius: CGFloat = 8
        static let toastBottomSpacing: CGFloat = 12
        static let toastSidePadding: CGFloat = 16
    }

    var completionHandler: ((Bool) -> Void)?

    weak var viewController: UIViewController?

    var dismissed = false

    lazy var gestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.cancelsTouchesInView = false
        return gestureRecognizer
    }()

    lazy var toastView: UIView = .build { view in
        view.layer.cornerRadius = UX.toastCornerRadius
        view.layer.masksToBounds = true

        // Add shadow to create the "hovering" effect
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
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
            guard viewController != nil else { return }

            NSLayoutConstraint.activate(updateConstraintsOn(self))
            self.alpha = 0 // Start invisible
            self.layoutIfNeeded()

            UIView.animate(
                withDuration: UX.toastAnimationDuration,
                animations: {
                    self.alpha = 1 // Fade in
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
                self.alpha = 0 // Fade out
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
    }
}
