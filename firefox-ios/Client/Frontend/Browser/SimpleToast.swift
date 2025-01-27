// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct SimpleToast: ThemeApplicable {
    private let toastLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.layer.cornerRadius = Toast.UX.toastCornerRadius
        label.clipsToBounds = true
    }

    private let heightConstraint: NSLayoutConstraint

    init() {
        heightConstraint = toastLabel.heightAnchor
            .constraint(equalToConstant: Toast.UX.toastHeight)
    }

    func showAlertWithText(_ text: String,
                           bottomContainer: UIView,
                           theme: Theme,
                           bottomConstraintPadding: CGFloat = -Toast.UX.toastBottomSpacing) {
        toastLabel.text = text
        bottomContainer.addSubview(toastLabel)
        NSLayoutConstraint.activate([
            heightConstraint,
            toastLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor,
                                                constant: Toast.UX.toastSidePadding),
            toastLabel.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor,
                                                 constant: -Toast.UX.toastSidePadding),
            toastLabel.bottomAnchor.constraint(equalTo: bottomContainer.safeAreaLayoutGuide.bottomAnchor,
                                               constant: bottomConstraintPadding)
        ])
        applyTheme(theme: theme)
        animate(toastLabel)

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }

    func applyTheme(theme: Theme) {
        toastLabel.textColor = theme.colors.textInverted
        toastLabel.backgroundColor = theme.colors.actionPrimary
    }

    private func dismiss(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                heightConstraint.constant = 0
                toast.superview?.layoutIfNeeded()
            },
            completion: { finished in
                toast.removeFromSuperview()
            }
        )
    }

    private func animate(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - Toast.UX.toastHeight
                frame.size.height = Toast.UX.toastHeight
                toast.frame = frame
            },
            completion: { finished in
                let thousandMilliseconds = DispatchTimeInterval.milliseconds(1000)
                let zeroMilliseconds = DispatchTimeInterval.milliseconds(0)
                let voiceOverDelay = UIAccessibility.isVoiceOverRunning ? thousandMilliseconds : zeroMilliseconds
                let dispatchTime = DispatchTime.now() + Toast.UX.toastDismissAfter + voiceOverDelay

                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.dismiss(toast)
                })
            }
        )
    }
}
