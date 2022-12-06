// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class RemoteTabsErrorCell: UITableViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let topPaddingInBetweenItems: CGFloat = 15
        static let titleSizeFont: CGFloat = 22
        static let descriptionSizeFont: CGFloat = 17
        static let buttonSizeFont: CGFloat = 15
    }

    var theme: Theme
    private var error: RemoteTabsError

    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = UX.topPaddingInBetweenItems
    }

    private let emptyStateImageView: UIImageView = build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.emptySyncImageName)
    }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .title2,
                                                                   size: UX.titleSizeFont)
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let instructionsLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.descriptionSizeFont)
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    let actionButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
    }

    init(error: RemoteTabsError,
         theme: Theme) {
        self.theme = theme
        self.error = error
        super.init(style: .default, reuseIdentifier: RemoteTabsErrorCell.cellIdentifier)
        selectionStyle = .none

        setupLayout()
        applyTheme(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {

        stackView.addArrangedSubview(emptyStateImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(instructionsLabel)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            emptyStateImageView.widthAnchor.constraint(equalToConstant: 90),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 60),
        ])

        setupView()
    }

    private func setupView() {
        emptyStateImageView.image = UIImage.templateImageNamed(ImageIdentifiers.emptySyncImageName)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        instructionsLabel.text = error.localizedString()
//        .setTitle( .PrivateBrowsingLearnMore, for: [])
    }

    func applyTheme(theme: Theme) {
        emptyStateImageView.tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        instructionsLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer3
    }
}
