// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class MenuSiteBadge: UIView, ThemeApplicable {
    private struct UX {
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 6
        static let contentSpacing: CGFloat = 4
        static let iconSize: CGFloat = 16
        static let chevronSize: CGFloat = 20
    }

    var tapHandler: (() -> Void)?
    private let mainMenuHelper: MainMenuInterface

    private lazy var stack: UIStackView = .build { [weak self] stack in
        guard let self else { return }
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: UX.verticalPadding,
                                           left: UX.horizontalPadding,
                                           bottom: UX.verticalPadding,
                                           right: UX.horizontalPadding)
        stack.distribution = .fill
        stack.axis = .horizontal
        stack.clipsToBounds = true
        stack.spacing = UX.contentSpacing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        stack.isUserInteractionEnabled = true
        stack.addGestureRecognizer(tapGesture)
    }

    private var label: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .button
    }

    private var icon: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private var chevron: UIImageView = .build { imageView in
        let imageName = StandardImageIdentifiers.Large.chevronRight
        let image = UIImage(named: imageName)?
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection() ?? UIImage()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
    }

    init(mainMenuHelper: MainMenuInterface) {
        self.mainMenuHelper = mainMenuHelper
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 26.0, *) {
            stack.layer.cornerRadius = stack.frame.height / 2
        } else {
            stack.layer.cornerRadius = UX.cornerRadius
            stack.layer.borderWidth = UX.borderWidth
        }
    }

    private func setupViews() {
        addSubview(stack)
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(chevron)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),

            icon.widthAnchor.constraint(equalToConstant: UX.iconSize),
            chevron.widthAnchor.constraint(equalToConstant: UX.chevronSize)
        ])
    }

    func configure(text: String, iconName: String, useTemplate: Bool) {
        label.text = text
        let image: UIImage = useTemplate
            ? UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
            : UIImage(named: iconName) ?? UIImage()
        icon.image = image
    }

    func applyTheme(theme: Theme) {
        label.textColor = theme.colors.textSecondary
        stack.layer.borderColor = theme.colors.actionSecondaryHover.cgColor
        if #available(iOS 26.0, *) {
            stack.backgroundColor = theme.colors.layerSurfaceMedium
                .withAlphaComponent(mainMenuHelper.backgroundAlpha())
        } else {
            stack.backgroundColor = .clear
        }
        icon.tintColor = theme.colors.iconSecondary
        chevron.tintColor = theme.colors.iconSecondary
    }

    @objc
    private func tapped() {
        tapHandler?()
    }
}
