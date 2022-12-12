// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class RemoteTabsErrorCell: UITableViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let verticalPadding: CGFloat = 60
        static let horizontalPadding: CGFloat = 24
        static let paddingInBetweenItems: CGFloat = 15
        static let titleSizeFont: CGFloat = 22
        static let descriptionSizeFont: CGFloat = 17
        static let buttonSizeFont: CGFloat = 15
        static let imageSize: CGSize = CGSize(width: 90, height: 60)
    }

    var theme: Theme
    var error: RemoteTabsErrorDataSource.ErrorType
    weak var delegate: RemotePanelDelegate?

    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = UX.paddingInBetweenItems
    }

    private let emptyStateImageView: UIImageView = build { imageView in
        imageView.contentMode = .scaleAspectFit
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
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let signInButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
        button.isHidden = true
    }

    init(error: RemoteTabsErrorDataSource.ErrorType,
         theme: Theme) {
        self.error = error
        self.theme = theme
        super.init(style: .default, reuseIdentifier: RemoteTabsErrorCell.cellIdentifier)
        selectionStyle = .none

        setupLayout()
        applyTheme(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(delegate: RemotePanelDelegate?) {
        self.delegate = delegate
        emptyStateImageView.image = UIImage.templateImageNamed(ImageIdentifiers.emptySyncImageName)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        instructionsLabel.text = error.localizedString()

        // Show signIn button only for notLoggedIn case
        if error == .notLoggedIn {
            signInButton.setTitle(.Settings.Sync.ButtonTitle, for: [])
            signInButton.isHidden = false
            signInButton.addTarget(self, action: #selector(presentSignIn), for: .touchUpInside)
        }
    }

    private func setupLayout() {
        stackView.addArrangedSubview(emptyStateImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(instructionsLabel)
        stackView.addArrangedSubview(signInButton)
        scrollView.addSubview(stackView)
        contentView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.verticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                               constant: -UX.verticalPadding),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: stackView.widthAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            emptyStateImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),
        ])
    }

    func applyTheme(theme: Theme) {
        emptyStateImageView.tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        instructionsLabel.textColor = theme.colors.textPrimary
        signInButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        backgroundColor = theme.colors.layer3
    }

    @objc private func presentSignIn() {
        if let delegate = self.delegate {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncSignIn)
            delegate.remotePanelDidRequestToSignIn()
        }
    }
}
