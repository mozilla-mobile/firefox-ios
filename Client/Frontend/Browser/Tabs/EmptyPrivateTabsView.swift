// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Foundation
import Shared

// View we display when there are no private tabs created
class EmptyPrivateTabsView: UIView {
    struct UX {
        static let titleSizeFont: CGFloat = 22
        static let descriptionSizeFont: CGFloat = 17
        static let buttonSizeFont: CGFloat = 15
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 90, height: 90)
    }

    // MARK: - Properties

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .title2,
                                                            size: UX.titleSizeFont)
        label.numberOfLines = 0
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.descriptionSizeFont)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = .TabTrayPrivateBrowsingDescription
    }

    let learnMoreButton: UIButton = .build { button in
        button.setTitle( .PrivateBrowsingLearnMore, for: [])
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline,
                                                                         size: UX.buttonSizeFont)
    }

    private let iconImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.largePrivateTabsMask)
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        containerView.addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                constant: UX.horizontalPadding),
            scrollView.topAnchor.constraint(equalTo: topAnchor,
                                            constant: UX.verticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                               constant: -UX.verticalPadding),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor,
                                               constant: UX.paddingInBetweenItems),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                            constant: UX.paddingInBetweenItems),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: UX.paddingInBetweenItems),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                 constant: UX.paddingInBetweenItems),
            learnMoreButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            learnMoreButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            learnMoreButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                    constant: -UX.paddingInBetweenItems),
        ])
    }

    func applyTheme(_ theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        learnMoreButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        iconImageView.tintColor = theme.colors.indicatorActive
    }
}
