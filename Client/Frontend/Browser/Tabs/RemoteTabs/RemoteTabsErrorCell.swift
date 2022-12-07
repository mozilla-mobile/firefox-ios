// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct RemoteTabsErrorCellViewModel {
    var error: RemoteTabsError
    var performAction: (() -> Void)?
}

class RemoteTabsErrorCell: UITableViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let verticalPadding: CGFloat = 100
        static let horizontalPadding: CGFloat = 24
        static let paddingInBetweenItems: CGFloat = 15
        static let titleSizeFont: CGFloat = 22
        static let descriptionSizeFont: CGFloat = 17
        static let buttonSizeFont: CGFloat = 15
    }

    var theme: Theme
    var viewModel: RemoteTabsErrorCellViewModel
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
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private let instructionsLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.descriptionSizeFont)
        label.numberOfLines = 0
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private let signInButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
        button.isHidden = true
    }

    private let createAccountButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
        button.isHidden = true
    }

    init(viewModel: RemoteTabsErrorCellViewModel,
         theme: Theme) {
        self.theme = theme
        self.viewModel = viewModel
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
        instructionsLabel.text = viewModel.error.localizedString()

        if viewModel.error == .notLoggedIn {
            signInButton.setTitle(.Settings.Sync.ButtonTitle, for: [])
            signInButton.isHidden = false
            signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)

            createAccountButton.setTitle(.RemoteTabCreateAccount, for: [])
            createAccountButton.isHidden = false
            createAccountButton.addTarget(self, action: #selector(createAnAccount), for: .touchUpInside)
        }
    }

    private func setupLayout() {
        stackView.addArrangedSubview(emptyStateImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(instructionsLabel)
        stackView.addArrangedSubview(signInButton)
        stackView.addArrangedSubview(createAccountButton)

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

            emptyStateImageView.widthAnchor.constraint(equalToConstant: 90),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    func applyTheme(theme: Theme) {
        emptyStateImageView.tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        instructionsLabel.textColor = theme.colors.textPrimary
        signInButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        createAccountButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        backgroundColor = theme.colors.layer3
    }

    @objc private func signIn() {
        if let delegate = self.delegate {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncSignIn)
            delegate.remotePanelDidRequestToSignIn()
        }
    }

    @objc private func createAnAccount() {
        if let delegate = self.delegate {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncCreateAccount)
            delegate.remotePanelDidRequestToCreateAccount()
        }
    }
}
