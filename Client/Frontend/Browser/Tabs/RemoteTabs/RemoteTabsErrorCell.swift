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
//    var delegate:

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

    private let actionButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.buttonSizeFont)
        button.addTarget(self, action: #selector(signIn), for: .touchUpInside)
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

    func configure() {
        emptyStateImageView.image = UIImage.templateImageNamed(ImageIdentifiers.emptySyncImageName)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        instructionsLabel.text = viewModel.error.localizedString()

        if viewModel.error == .notLoggedIn {
            actionButton.setTitle(.Settings.Sync.ButtonTitle, for: [])
            actionButton.isHidden = false
        }
    }

    private func setupLayout() {
        stackView.addArrangedSubview(emptyStateImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(instructionsLabel)
        stackView.addArrangedSubview(actionButton)

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
        actionButton.setTitleColor(theme.colors.borderAccentPrivate, for: [])
        backgroundColor = theme.colors.layer3
    }

    @objc private func signIn() {
        if let remoteTabsPanel = self.remoteTabsPanel {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncSignIn)
            remoteTabsPanel.remotePanelDelegate?.remotePanelDidRequestToSignIn()
        }
    }

    @objc private func createAnAccount() {
        if let remoteTabsPanel = self.remoteTabsPanel {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncCreateAccount)
            remoteTabsPanel.remotePanelDelegate?.remotePanelDidRequestToCreateAccount()
        }
    }
}
