// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct SimpleToast: ThemeApplicable {
    struct UX {
        static let labelPadding: CGFloat = 16
    }

    private let containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let shadowView: UIView = .build { view in
        view.layer.cornerRadius = Toast.UX.toastCornerRadius
    }

    private let toastLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.backgroundColor = .clear
    }

    private let heightConstraint: NSLayoutConstraint

    init() {
        heightConstraint = containerView.heightAnchor
            .constraint(equalToConstant: Toast.UX.toastHeightWithShadow)
    }

    func showAlertWithText(_ text: String,
                           bottomContainer: UIView,
                           theme: Theme,
                           bottomConstraintPadding: CGFloat = 0) {
        toastLabel.text = text
        bottomContainer.addSubview(containerView)
        containerView.addSubview(shadowView)
        shadowView.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            heightConstraint,
            containerView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor,
                                                   constant: Toast.UX.toastSidePadding),
            containerView.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor,
                                                    constant: -Toast.UX.toastSidePadding),
            containerView.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor,
                                                  constant: bottomConstraintPadding),

            shadowView.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: Toast.UX.shadowHorizontalSpacing / 2),
            shadowView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: Toast.UX.shadowVerticalSpacing),
            shadowView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -Toast.UX.shadowVerticalSpacing),
            shadowView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -Toast.UX.shadowHorizontalSpacing / 2),
            shadowView.heightAnchor.constraint(equalToConstant: Toast.UX.toastHeightWithoutShadow),

            toastLabel.topAnchor.constraint(equalTo: shadowView.topAnchor),
            toastLabel.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor,
                                                constant: UX.labelPadding),
            toastLabel.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor,
                                                 constant: -UX.labelPadding),
            toastLabel.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),
        ])
        applyTheme(theme: theme)
        animate(containerView)

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }

    func applyTheme(theme: Theme) {
        toastLabel.textColor = theme.colors.textInverted
        shadowView.backgroundColor = theme.colors.actionPrimary
        setupShadow(theme: theme)
    }

    private func setupShadow(theme: Theme) {
        shadowView.layoutIfNeeded()

        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds,
                                                   cornerRadius: Toast.UX.toastCornerRadius).cgPath
        shadowView.layer.shadowRadius = Toast.UX.shadowRadius
        shadowView.layer.shadowOffset = Toast.UX.shadowOffset
        shadowView.layer.shadowColor =  theme.colors.shadowDefault.cgColor
        shadowView.layer.shadowOpacity = Toast.UX.shadowOpacity
    }

    private func animate(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - Toast.UX.toastHeightWithShadow
                frame.size.height = Toast.UX.toastHeightWithShadow
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
}
