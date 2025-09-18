// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class MenuSquareView: UIView, ThemeApplicable {
    private struct UX {
        static let iconSize: CGFloat = 24
        static let backgroundViewCornerRadius: CGFloat = 12
        static let horizontalMargin: CGFloat = 6
        static let contentViewSpacing: CGFloat = 4
        static let contentViewTopMargin: CGFloat = 12
        static let contentViewBottomMargin: CGFloat = 8
        static let contentViewHorizontalMargin: CGFloat = 4
        static let cornerRadius: CGFloat = 16
        static let hyphenationFactor: Float = 1.0
        static let dividerWidth: CGFloat = 0.5
    }

    // MARK: - UI Elements
    private var backgroundContentView: UIView = .build()

    private var contentStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.contentViewSpacing
        stack.distribution = .fill
    }

    private var icon: UIImageView = .build { view in
        view.contentMode = .scaleAspectFit
    }

    private var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private var dividerView: UIView = .build()

    // MARK: - Properties
    var model: MenuElement?
    private var shouldShowDivider = true
    var cellTapCallback: (() -> Void)?

    private var mainMenuHelper: MainMenuInterface?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not yet supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #unavailable(iOS 26.0) {
            layer.cornerRadius = UX.cornerRadius
            self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner,
                                        .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            self.clipsToBounds = true
        }
    }

    func configureCellWith(
        model: MenuElement,
        shouldShowDivider: Bool = true,
        mainMenuHelper: MainMenuInterface = MainMenuHelper()
    ) {
        self.model = model
        self.mainMenuHelper = mainMenuHelper
        self.setTitle(with: model.title)
        self.icon.image = UIImage(named: model.iconName)?.withRenderingMode(.alwaysTemplate)
        self.backgroundContentView.layer.cornerRadius = UX.backgroundViewCornerRadius
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button

        self.shouldShowDivider = shouldShowDivider
    }

    private func setupView() {
        self.addSubview(backgroundContentView)
        backgroundContentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(icon)
        contentStackView.addArrangedSubview(titleLabel)

        if #available(iOS 26.0, *) {
            backgroundContentView.addSubview(dividerView)
            NSLayoutConstraint.activate([
                dividerView.widthAnchor.constraint(equalToConstant: UX.dividerWidth),
                dividerView.trailingAnchor.constraint(equalTo: backgroundContentView.trailingAnchor),
                dividerView.topAnchor.constraint(equalTo: backgroundContentView.topAnchor),
                dividerView.bottomAnchor.constraint(equalTo: backgroundContentView.bottomAnchor),

                contentStackView.trailingAnchor.constraint(
                    equalTo: dividerView.leadingAnchor,
                    constant: -UX.contentViewHorizontalMargin
                )
            ])
        } else {
            contentStackView.trailingAnchor.constraint(
                equalTo: backgroundContentView.trailingAnchor,
                constant: -UX.contentViewHorizontalMargin
            ).isActive = true
        }

        NSLayoutConstraint.activate([
            backgroundContentView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundContentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundContentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            backgroundContentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            contentStackView.topAnchor.constraint(
                equalTo: backgroundContentView.topAnchor,
                constant: UX.contentViewTopMargin
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: backgroundContentView.leadingAnchor,
                constant: UX.contentViewHorizontalMargin
            ),
            contentStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: backgroundContentView.bottomAnchor,
                constant: -UX.contentViewBottomMargin
            ),
            icon.heightAnchor.constraint(equalToConstant: UX.iconSize)
        ])
    }

    private func setTitle(with title: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = UX.hyphenationFactor
        paragraphStyle.alignment = .center

        let attributedText = NSAttributedString(
            string: title,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: FXFontStyles.Regular.caption2.scaledFont()
            ]
        )
        titleLabel.attributedText = attributedText
    }

    @objc
    private func handleTap() {
        cellTapCallback?()
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        backgroundColor = .clear
        contentStackView.backgroundColor = .clear
        if #available(iOS 26.0, *) {
            backgroundContentView.backgroundColor = .clear
            dividerView.backgroundColor = shouldShowDivider ? theme.colors.borderPrimary : .clear
        } else {
            let alpha: CGFloat = mainMenuHelper?.backgroundAlpha() ?? 1.0
            backgroundContentView.backgroundColor = theme.colors.layerSurfaceMedium.withAlphaComponent(alpha)
        }
        icon.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textSecondary
    }
}
