// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import Common
import Shared

// MARK: Header View
class SaveCardTableHeaderView: UITableViewHeaderFooterView, ReusableCell, NotificationThemeable {
    // MARK: UX
    struct SaveCardHeaderUX {
        static let titleLabelFontSize: CGFloat = 17
        static let headerLabelFontSize: CGFloat = 15
        static let headerElementsSpacing: CGFloat = 7.0
        static let mainContainerElementsSpacing: CGFloat = 7.0
        static let bottomSpacing: CGFloat = 24.0
        static let logoSize: CGFloat = 36.0
    }

    // MARK: Views
    private var logoContainerView = UIView()
    private var firefoxLogoImage: UIImageView = .build { image in
        image.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
        //        image.backgroundColor = .yellow
    }
    private var titleLabel: UILabel = .build { label in
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = .CreditCard.RememberCard.MainTitle
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .headline,
                                                                       size: SaveCardHeaderUX.titleLabelFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
    }
    private var headerLabel: UILabel = .build { label in
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.text = .CreditCard.RememberCard.Header
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: SaveCardHeaderUX.headerLabelFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
    }

    let mainContainerStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .fill
        stack.axis = .vertical
        stack.spacing = SaveCardHeaderUX.mainContainerElementsSpacing
    }

    let firstRowContainerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        //        applyTheme()
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        accessibilityIdentifier = AccessibilityIdentifiers.RememberCard.rememberCreditCardHeader
        setupView()
        //        applyTheme()
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

        NSLayoutConstraint.activate([
            firstRowContainerView.heightAnchor.constraint(equalToConstant: SaveCardHeaderUX.logoSize),
            firefoxLogoImage.widthAnchor.constraint(equalToConstant: SaveCardHeaderUX.logoSize),
            firefoxLogoImage.heightAnchor.constraint(equalToConstant: SaveCardHeaderUX.logoSize),
            firefoxLogoImage.centerYAnchor.constraint(equalTo: firstRowContainerView.centerYAnchor),
            firefoxLogoImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),

            titleLabel.leadingAnchor.constraint(equalTo: firefoxLogoImage.trailingAnchor, constant: SaveCardHeaderUX.headerElementsSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: firstRowContainerView.trailingAnchor, constant: 0),
            titleLabel.topAnchor.constraint(equalTo: firstRowContainerView.topAnchor, constant: 0),
            titleLabel.bottomAnchor.constraint(equalTo: firstRowContainerView.bottomAnchor, constant: 0),

            mainContainerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            mainContainerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            mainContainerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            mainContainerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SaveCardHeaderUX.bottomSpacing),
        ])
    }

    func applyTheme() {
    }
}

extension SaveCardTableHeaderView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        headerLabel.textColor = theme.colors.textPrimary
    }
}
