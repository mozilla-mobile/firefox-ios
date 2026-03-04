// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Firefox homepage "News" affordance shown above vertical stories.
class NewsAffordanceHeaderView: UICollectionReusableView,
                                ReusableCell,
                                ThemeApplicable {
    struct UX {
        static let containerHeight: CGFloat = 56
        static let containerBottomInset: CGFloat = 16
        static let stackTopInset: CGFloat = 4
        static let stackBottomInset: CGFloat = 8
        static let stackHorizontalInset: CGFloat = 20
        static let iconSpacing: CGFloat = 4
        static let chevronSize: CGFloat = 20
        static let newsIconSize: CGFloat = 24
    }

    // MARK: - UIElements
    private lazy var containerView: UIView = .build { view in
        view.isAccessibilityElement = true
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
    }

    private lazy var chevronImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.chevronUp)
    }

    private lazy var iconLabelStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = UX.iconSpacing
    }

    private lazy var newsIconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.readingList)
    }

    private lazy var newsLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.text = .FirefoxHomepage.Pocket.NewsAffordanceLabel
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerView.accessibilityIdentifier = nil
    }

    // MARK: - Public methods
    func configure(theme: Theme) {
        containerView.accessibilityLabel = .FirefoxHomepage.Pocket.NewsAffordanceLabel
        applyTheme(theme: theme)
    }

    // MARK: - Private methods
    private func setupLayout() {
        iconLabelStackView.addArrangedSubview(newsIconImageView)
        iconLabelStackView.addArrangedSubview(newsLabel)

        stackView.addArrangedSubview(chevronImageView)
        stackView.addArrangedSubview(iconLabelStackView)

        containerView.addSubview(stackView)
        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.heightAnchor.constraint(equalToConstant: UX.containerHeight),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.containerBottomInset),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.stackTopInset),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackHorizontalInset),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                constant: -UX.stackHorizontalInset),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.stackBottomInset),

            chevronImageView.widthAnchor.constraint(equalToConstant: UX.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: UX.chevronSize),
            newsIconImageView.widthAnchor.constraint(equalToConstant: UX.newsIconSize),
            newsIconImageView.heightAnchor.constraint(equalToConstant: UX.newsIconSize),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let color = theme.colors.actionPrimary
        chevronImageView.tintColor = color
        newsIconImageView.tintColor = color
        newsLabel.textColor = color
    }
}
