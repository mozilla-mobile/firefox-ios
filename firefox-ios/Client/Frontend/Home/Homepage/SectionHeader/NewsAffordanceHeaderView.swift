// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

final class NewsAffordanceHeaderView: UIView, ThemeApplicable {
    struct UX {
        static let stackTopInset: CGFloat = 4
        static let stackBottomInset: CGFloat = 8
        static let stackHorizontalInset: CGFloat = 20
        static let iconSpacing: CGFloat = 4
        static let chevronSize: CGFloat = 20
        static let newsIconSize: CGFloat = 24
    }

    // MARK: - UI Elements
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
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap)))
    }

    private lazy var newsIconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.newsfeed)
    }

    private lazy var newsLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = .FirefoxHomepage.Pocket.NewsAffordanceLabel
    }

    private var onTap: (@MainActor () -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = .FirefoxHomepage.Pocket.NewsAffordanceLabel
        accessibilityTraits = .button
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors.actionPrimary
        chevronImageView.tintColor = color
        newsIconImageView.tintColor = color
        newsLabel.textColor = color
    }

    func configure(onTap: (@MainActor () -> Void)?) {
        self.onTap = onTap
    }

    @objc
    private func handleTap() {
        onTap?()
    }

    private func setupLayout() {
        iconLabelStackView.addArrangedSubview(newsIconImageView)
        iconLabelStackView.addArrangedSubview(newsLabel)

        stackView.addArrangedSubview(chevronImageView)
        stackView.addArrangedSubview(iconLabelStackView)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.stackTopInset),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UX.stackHorizontalInset),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.stackHorizontalInset),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -UX.stackBottomInset),

            chevronImageView.widthAnchor.constraint(equalToConstant: UX.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: UX.chevronSize),
            newsIconImageView.widthAnchor.constraint(equalToConstant: UX.newsIconSize),
            newsIconImageView.heightAnchor.constraint(equalToConstant: UX.newsIconSize),
        ])
    }
}
