// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Foundation
import Shared
import ComponentLibrary

@MainActor
protocol EmptyPrivateTabView: UIView, ThemeApplicable, InsetUpdatable {
    var needsSafeArea: Bool { get }
    var delegate: EmptyPrivateTabsViewDelegate? { get set }
}

// View we display when there are no private tabs created
class ExperimentEmptyPrivateTabsView: UIView,
                                      EmptyPrivateTabView {
    struct UX {
        static let paddingInBetweenItems: CGFloat = 15
        static let buttonTopPadding: CGFloat = 24
        static let topPadding: CGFloat = 55
        static let bottomPadding: CGFloat = 35
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 72, height: 72)
    }

    // MARK: - Properties

    var needsSafeArea: Bool { true }
    weak var delegate: EmptyPrivateTabsViewDelegate?

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
        label.numberOfLines = 0
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
        containerView.addSubviews(iconImageView, titleLabel, descriptionLabel, learnMoreButton)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),

            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor,
                                               constant: UX.topPadding),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor,
                                            constant: UX.paddingInBetweenItems),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: UX.paddingInBetweenItems),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                      constant: UX.horizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                       constant: -UX.horizontalPadding),

            learnMoreButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                 constant: UX.buttonTopPadding),
            learnMoreButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                     constant: UX.horizontalPadding),
            learnMoreButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                      constant: -UX.horizontalPadding),
            learnMoreButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                    constant: -UX.bottomPadding),
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

    // MARK: - InsetUpdatable

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        scrollView.contentInset.top = top
        scrollView.contentInset.bottom = bottom
    }
}
