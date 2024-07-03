// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Foundation
import Shared
import ComponentLibrary

protocol EmptyPrivateTabsViewDelegate: AnyObject {
    func didTapLearnMore(urlRequest: URLRequest)
}

// View we display when there are no private tabs created
class EmptyPrivateTabsView: UIView {
    struct UX {
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 90, height: 90)
    }

    // MARK: - Properties

    weak var delegate: EmptyPrivateTabsViewDelegate?

    // UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.title2.scaledFont()
        label.text =  .PrivateBrowsingTitle
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = .TabTrayPrivateBrowsingDescription
    }

    private lazy var learnMoreButton: LinkButton = .build { button in
        button.titleLabel?.adjustsFontForContentSizeCategory = true
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
        let viewModel = LinkButtonViewModel(title: .PrivateBrowsingLearnMore,
                                            a11yIdentifier: AccessibilityIdentifiers.TabTray.learnMoreButton,
                                            font: FXFontStyles.Regular.subheadline.scaledFont(),
                                            contentHorizontalAlignment: .center)
        learnMoreButton.configure(viewModel: viewModel)
    }

    private func setupLayout() {
        configureLearnMoreButton()
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
        learnMoreButton.applyTheme(theme: theme)
        iconImageView.tintColor = theme.colors.iconDisabled
    }

    @objc
    private func didTapLearnMore() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let langID = Locale.preferredLanguages.first {
            let learnMoreRequest = URLRequest(url: "https://support.mozilla.org/1/mobile/\(appVersion ?? "0.0")/iOS/\(langID)/private-browsing-ios".asURL!)
            delegate?.didTapLearnMore(urlRequest: learnMoreRequest)
        }
    }
}
