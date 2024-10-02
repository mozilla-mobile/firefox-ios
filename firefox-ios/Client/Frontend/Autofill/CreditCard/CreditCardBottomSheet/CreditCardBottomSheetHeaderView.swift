// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Account
import Common
import Shared

// MARK: Header View
class CreditCardBottomSheetHeaderView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    // MARK: UX
    struct UX {
        static let headerElementsSpacing: CGFloat = 7.0
        static let mainContainerElementsSpacing: CGFloat = 7.0
        static let bottomSpacing: CGFloat = 24.0
        static let logoSize: CGFloat = 36.0
        static let closeButtonMarginAndWidth: CGFloat = 46.0
    }
    public var titleLabelTrailingConstraint: NSLayoutConstraint!

    // MARK: Views
    public var viewModel: CreditCardBottomSheetViewModel? {
        didSet {
            setupContent()
        }
    }

    private var logoContainerView = UIView()
    private var firefoxLogoImage: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    private var titleLabel: UILabel = .build { label in
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = .CreditCard.RememberCreditCard.MainTitle
        label.font = FXFontStyles.Bold.headline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
    }

    private var headerLabel: UILabel = .build { label in
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.text = String(format: String.CreditCard.RememberCreditCard.Header, AppName.shortName.rawValue)
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .staticText
    }

    let mainContainerStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = UX.mainContainerElementsSpacing
    }

    let firstRowContainerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        accessibilityIdentifier = AccessibilityIdentifiers.RememberCreditCard.rememberCreditCardHeader
        setupView()
        setupContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        firstRowContainerView.addSubview(firefoxLogoImage)
        firstRowContainerView.addSubview(titleLabel)

        mainContainerStackView.addArrangedSubview(firstRowContainerView)
        mainContainerStackView.addArrangedSubview(headerLabel)

        addSubview(mainContainerStackView)
        let isCloseButtonOverlapping = traitCollection.horizontalSizeClass != .regular
        titleLabelTrailingConstraint = titleLabel.trailingAnchor.constraint(
            equalTo: firstRowContainerView.trailingAnchor,
            constant: isCloseButtonOverlapping ? -UX.closeButtonMarginAndWidth : 0
        )

        NSLayoutConstraint.activate(
            [
                firstRowContainerView.heightAnchor.constraint(equalToConstant: UX.logoSize),
                firefoxLogoImage.widthAnchor.constraint(equalToConstant: UX.logoSize),
                firefoxLogoImage.heightAnchor.constraint(equalToConstant: UX.logoSize),
                firefoxLogoImage.centerYAnchor.constraint(equalTo: firstRowContainerView.centerYAnchor),
                firefoxLogoImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),

                titleLabel.leadingAnchor.constraint(
                    equalTo: firefoxLogoImage.trailingAnchor,
                    constant: UX.headerElementsSpacing
                ),
                titleLabelTrailingConstraint,
                titleLabel.topAnchor.constraint(equalTo: firstRowContainerView.topAnchor, constant: 0),
                titleLabel.bottomAnchor.constraint(equalTo: firstRowContainerView.bottomAnchor, constant: 0),

                mainContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
                mainContainerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
                mainContainerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
                mainContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpacing),
            ]
        )
    }

    private func setupContent() {
        guard let viewModel = viewModel else { return }
        titleLabel.text = viewModel.state.title
        headerLabel.text = viewModel.state.header
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        headerLabel.textColor = theme.colors.textPrimary
    }
}
