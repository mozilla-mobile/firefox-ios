// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class ContextualHintView: UIView, ThemeApplicable {
    private var viewModel: ContextualHintViewModel!

    struct UX {
        static let actionButtonTextSize: CGFloat = 17
        static let closeButtonSize = CGSize(width: 35, height: 35)
        static let closeButtonTrailing: CGFloat = 5
        static let closeButtonTop: CGFloat = 23
        static let closeButtonBottom: CGFloat = 12
        static let closeButtonInset = UIEdgeInsets(top: 0, left: 7.5, bottom: 15, right: 7.5)
        static let descriptionTextSize: CGFloat = 17
        static let stackViewLeading: CGFloat = 16
        static let stackViewTopArrowTopConstraint: CGFloat = 16
        static let stackViewBottomArrowTopConstraint: CGFloat = 5
        static let stackViewTrailing: CGFloat = 3
        static let heightSpacing: CGFloat = UX.stackViewTopArrowTopConstraint + UX.stackViewBottomArrowTopConstraint
    }

    // MARK: - UI Elements
    private lazy var contentContainer: UIView = .build { _ in }

    private lazy var closeButton: ActionButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross)?.withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.contentEdgeInsets = UX.closeButtonInset
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.descriptionTextSize)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var actionButton: ActionButton = .build { button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.buttonEdgeSpacing = 0
    }

    private lazy var stackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = 7.0
    }

    private lazy var scrollView: FadeScrollView = .build { view in
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
    }

    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0, 0.63]
        return gradient
    }()

    override public func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    public func configure(viewModel: ContextualHintViewModel) {
        self.viewModel = viewModel

        closeButton.accessibilityLabel = viewModel.closeButtonA11yLabel
        descriptionLabel.text = viewModel.description

        layer.addSublayer(gradient)

        addSubview(scrollView)
        addSubview(closeButton)

        scrollView.addSubview(contentContainer)
        contentContainer.addSubview(stackView)

        stackView.addArrangedSubview(descriptionLabel)
        if viewModel.isActionType { stackView.addArrangedSubview(actionButton) }

        setupConstraints()

        closeButton.touchUpAction = viewModel.closeButtonAction
        actionButton.touchUpAction = viewModel.actionButtonAction
    }

    private func setupConstraints() {
        let isArrowUp = viewModel.arrowDirection == .up
        let topPadding = isArrowUp ? UX.stackViewTopArrowTopConstraint : UX.stackViewBottomArrowTopConstraint
        let closeButtonPadding = isArrowUp ? UX.closeButtonTop : UX.closeButtonBottom

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: UX.heightSpacing),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: contentContainer.widthAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: closeButtonPadding),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.closeButtonTrailing),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            stackView.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: topPadding),
            stackView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor,
                                               constant: UX.stackViewLeading),
            stackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor,
                                                constant: -UX.closeButtonSize.width - UX.stackViewTrailing),
            stackView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        setNeedsLayout()
        layoutIfNeeded()
    }

    public func applyTheme(theme: Theme) {
        closeButton.tintColor = theme.colors.textOnDark
        descriptionLabel.textColor = theme.colors.textOnDark
        gradient.colors = theme.colors.layerGradient.cgColors

        if viewModel.isActionType {
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.actionButtonTextSize),
                .foregroundColor: theme.colors.textOnDark,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]

            let attributeString = NSMutableAttributedString(
                string: viewModel.actionButtonTitle,
                attributes: textAttributes
            )

            actionButton.setAttributedTitle(attributeString, for: .normal)
        }
    }
}
