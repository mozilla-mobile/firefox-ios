// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public final class ContextualHintView: UIView, ThemeApplicable, Notifiable {
    private var viewModel: ContextualHintViewModel?
    private var closeButtonHeightConstraint: NSLayoutConstraint?
    private var closeButtonWidthConstraint: NSLayoutConstraint?

    struct UX {
        static let closeButtonSize = CGSize(width: 35, height: 35)
        static let maxCloseButtonSize = CGSize(width: closeButtonSize.width * 2.0, height: closeButtonSize.height * 2.0)
        static let closeButtonTrailing: CGFloat = 5
        static let closeButtonTop: CGFloat = 23
        static let closeButtonBottom: CGFloat = 12
        static let closeButtonInsets = NSDirectionalEdgeInsets(top: 0, leading: 7.5, bottom: 15, trailing: 7.5)
        static let stackViewLeading: CGFloat = 16
        static let stackViewTopArrowTopConstraint: CGFloat = 16
        static let stackViewBottomArrowTopConstraint: CGFloat = 5
        static let stackViewTrailing: CGFloat = 3
        static let heightSpacing: CGFloat = UX.stackViewTopArrowTopConstraint + UX.stackViewBottomArrowTopConstraint
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI Elements
    private lazy var contentContainer: UIView = .build { _ in }

    private lazy var closeButton: UIButton = .build { button in
        button.configuration = nil
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross)?.withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.addTarget(self, action: #selector(self.didTapCloseButton), for: .touchUpInside)
        button.configuration?.contentInsets = UX.closeButtonInsets
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.textAlignment = .left
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
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

        if !viewModel.title.isEmpty {
            titleLabel.text = viewModel.title
            stackView.addArrangedSubview(titleLabel)
        }
        stackView.addArrangedSubview(descriptionLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        guard let viewModel else { return }

        let isArrowUp = viewModel.arrowDirection == .up
        let topPadding = isArrowUp ? UX.stackViewTopArrowTopConstraint : UX.stackViewBottomArrowTopConstraint
        let closeButtonPadding = isArrowUp ? UX.closeButtonTop : UX.closeButtonBottom

        let heightConstraint = closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height)
        closeButtonHeightConstraint = heightConstraint
        let widthConstraint = closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width)
        closeButtonWidthConstraint = widthConstraint
        updateButtonSizeForDynamicFont()

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
            heightConstraint,
            widthConstraint,

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

    @objc
    private func didTapCloseButton(sender: UIButton) {
        viewModel?.closeButtonAction?(sender)
    }

    public func applyTheme(theme: Theme) {
        closeButton.tintColor = theme.colors.textOnDark
        titleLabel.textColor = theme.colors.textOnDark
        descriptionLabel.textColor = theme.colors.textOnDark
        gradient.colors = theme.colors.layerGradient.cgColors
    }

    private func updateButtonSizeForDynamicFont() {
        let scaledWidth = UIFontMetrics.default.scaledValue(for: UX.closeButtonSize.width)
        let scaledHeight = UIFontMetrics.default.scaledValue(for: UX.closeButtonSize.height)
        let dynamicWidth = min(max(scaledWidth, UX.closeButtonSize.width), UX.maxCloseButtonSize.width)
        let dynamicHeight = min(max(scaledHeight, UX.closeButtonSize.height), UX.maxCloseButtonSize.height)
        closeButtonHeightConstraint?.constant = dynamicHeight
        closeButtonWidthConstraint?.constant = dynamicWidth
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.updateButtonSizeForDynamicFont()
            }
        default:
            break
        }
    }
}
