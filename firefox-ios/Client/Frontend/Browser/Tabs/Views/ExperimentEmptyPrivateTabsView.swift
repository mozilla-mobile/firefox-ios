// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Foundation
import Shared
import ComponentLibrary

protocol EmptyPrivateTabView: UIView, ThemeApplicable {
    var delegate: EmptyPrivateTabsViewDelegate? { get set }
}

// View we display when there are no private tabs created
class ExperimentEmptyPrivateTabsView: UIView, EmptyPrivateTabView {
    struct UX {
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 72, height: 72)
    }

    // MARK: - Properties

    weak var delegate: EmptyPrivateTabsViewDelegate?

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }
    private lazy var centeredView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = .TabsTray.TabTrayPrivateBrowsingDescription
    }

    private lazy var learnMoreButton: SecondaryRoundedButton = .build { button in
        let viewModel = SecondaryRoundedButtonViewModel(
            title: .PrivateBrowsingLearnMore,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.learnMoreButton
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
    }

    private let iconImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLearnMoreButton() {
        learnMoreButton.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
    }

    private func setupLayout() {
        configureLearnMoreButton()
        centeredView.addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        containerView.addSubview(centeredView)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                constant: UX.horizontalPadding),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
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

            centeredView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.verticalPadding),
            centeredView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            centeredView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            centeredView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            iconImageView.topAnchor.constraint(equalTo: centeredView.topAnchor,
                                               constant: UX.paddingInBetweenItems),
            iconImageView.centerXAnchor.constraint(equalTo: centeredView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                            constant: UX.paddingInBetweenItems),
            titleLabel.leadingAnchor.constraint(equalTo: centeredView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centeredView.trailingAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: UX.paddingInBetweenItems),
            descriptionLabel.leadingAnchor.constraint(equalTo: centeredView.leadingAnchor,
                                                      constant: UX.horizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: centeredView.trailingAnchor,
                                                       constant: -UX.horizontalPadding),

            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                 constant: UX.paddingInBetweenItems),
            learnMoreButton.leadingAnchor.constraint(greaterThanOrEqualTo: centeredView.leadingAnchor),
            learnMoreButton.trailingAnchor.constraint(lessThanOrEqualTo: centeredView.trailingAnchor),
            learnMoreButton.centerXAnchor.constraint(equalTo: centeredView.centerXAnchor),
            learnMoreButton.bottomAnchor.constraint(equalTo: centeredView.bottomAnchor,
                                                    constant: -UX.paddingInBetweenItems),
        ])
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        learnMoreButton.applyTheme(theme: theme)
        iconImageView.tintColor = theme.colors.iconDisabled
    }

    @objc
    private func didTapLearnMore() {
        guard let url = SupportUtils.URLForTopic("private-browsing-ios") else { return }
        let request = URLRequest(url: url)
        delegate?.didTapLearnMore(urlRequest: request)
    }
}
