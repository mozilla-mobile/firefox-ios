// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Foundation

// View we display when there are no private tabs created
class EmptyPrivateTabsView: UIView {

    struct UX {
        static let titleSizeFont: CGFloat = 22
        static let descriptionSizeFont: CGFloat = 17
        static let buttonSizeFont: CGFloat = 15
        static let textMargin: CGFloat = 18
        static let learnMoreMargin: CGFloat = 8
        static let minBottomMargin: CGFloat = 10
    }

    // MARK: - Properties

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .title2,
                                                                   size: UX.titleSizeFont)
        label.numberOfLines = 0
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.descriptionSizeFont)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = .TabTrayPrivateBrowsingDescription
    }

    // TODO: Add completion to set to private
    let learnMoreButton: UIButton = .build { button in
        button.setTitle( .PrivateBrowsingLearnMore, for: [])
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
    }

    private let iconImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed("largePrivateMask")
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
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 80),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 120),
            iconImageView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: UX.textMargin),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                 constant: UX.learnMoreMargin),
            learnMoreButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            learnMoreButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            learnMoreButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                    constant: UX.learnMoreMargin),
        ])
    }

    func applyTheme(_ theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        learnMoreButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        iconImageView.tintColor = theme.colors.indicatorActive
    }
}
