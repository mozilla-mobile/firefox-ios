// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class ActionToast: ThemeApplicable {
    private let text: String
    private let theme: Theme
    private let buttonTitle: String
    private let buttonAction: () -> Void
    private var bottomConstraintPadding: CGFloat
    private var bottomContainer: UIView

    struct UX {
        static let stackViewLayoutMargins = UIEdgeInsets(
            top: 0,
            left: 16,
            bottom: 0,
            right: 16
        )
        static let buttonStrokeWidth: CGFloat = 1
        static let buttonCornerRadius: CGFloat = 8
        static let buttonContentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        static let buttonHeight: CGFloat = 36
    }

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UX.stackViewLayoutMargins
        return stack
    }()

    private lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.text = text
        label.textAlignment  = .center
        label.numberOfLines = 1
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                self.buttonAction()
                self.dismiss(stackView)
            }, for: .touchUpInside)
        var config = UIButton.Configuration.plain()
        config.title = buttonTitle
        config.background.backgroundColor = .clear
        config.background.strokeWidth = UX.buttonStrokeWidth
        config.background.cornerRadius = UX.buttonCornerRadius
        config.contentInsets = UX.buttonContentInsets
        button.configuration = config
        return button
    }()

    private lazy var heightConstraint: NSLayoutConstraint = {
        self.toastLabel.heightAnchor.constraint(equalToConstant: Toast.UX.toastHeight)
    }()

    init(
        text: String,
        bottomContainer: UIView,
        theme: Theme,
        bottomConstraintPadding: CGFloat = 0,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) {
        self.text = text
        self.bottomContainer = bottomContainer
        self.theme = theme
        self.bottomConstraintPadding = bottomConstraintPadding
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    func show() {
        stackView.addArrangedSubview(toastLabel)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(actionButton)

        bottomContainer.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            [
                heightConstraint,
                stackView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
                stackView.bottomAnchor.constraint(
                    equalTo: bottomContainer.safeAreaLayoutGuide.bottomAnchor,
                    constant: bottomConstraintPadding
                ),
                actionButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
            ]
        )
        applyTheme(theme: theme)
        animate(stackView)

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }

    private func dismiss(_ toast: UIView) {
        UIView.animate(
            withDuration: Toast.UX.toastAnimationDuration,
            animations: {
                self.heightConstraint.constant = 0
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

    func applyTheme(theme: Theme) {
        stackView.backgroundColor = theme.colors.actionPrimary
        toastLabel.textColor = theme.colors.textInverted
        actionButton.configuration?.background.strokeColor = theme.colors.textInverted
        actionButton.configuration?.baseForegroundColor = theme.colors.textInverted
    }
}
