// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

protocol RemoteTabsEmptyViewDelegate: AnyObject {
    func remotePanelDidRequestToSignIn()
    func presentFxAccountSettings()
    func remotePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool)
}

class RemoteTabsEmptyView: UIView, ThemeApplicable {
    struct UX {
        static let verticalPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 24
        static let paddingInBetweenItems: CGFloat = 15
        static let imageSize = CGSize(width: 90, height: 90)
    }

    weak var delegate: RemoteTabsEmptyViewDelegate?

    // MARK: - UI

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = UX.paddingInBetweenItems
        stackView.alignment = .center
    }

    private let emptyStateImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.title2.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let instructionsLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let signInButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .Settings.Sync.ButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.syncDataButton
        )
        button.configure(viewModel: viewModel)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(state: RemoteTabsPanelEmptyStateReason,
                   delegate: RemoteTabsEmptyViewDelegate?) {
        self.delegate = delegate

        emptyStateImageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cloud)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        instructionsLabel.text = state.localizedString()

        if state == .notLoggedIn || state == .failedToSync {
            signInButton.addTarget(self, action: #selector(presentSignIn), for: .touchUpInside)
        } else if state == .syncDisabledByUser {
            signInButton.addTarget(self, action: #selector(openAccountSettings), for: .touchUpInside)
        }

        signInButton.isHidden = shouldHideButton(state)
    }

    private func shouldHideButton(_ state: RemoteTabsPanelEmptyStateReason) -> Bool {
        return state == .noClients && state == .noTabs
    }

    private func setupLayout() {
        stackView.addArrangedSubview(emptyStateImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(instructionsLabel)
        stackView.addArrangedSubview(signInButton)
        stackView.setCustomSpacing(0, after: emptyStateImageView)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                               constant: UX.horizontalPadding),
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor,
                                           constant: UX.verticalPadding),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                constant: -UX.horizontalPadding),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                              constant: -UX.verticalPadding).priority(.defaultLow),
            signInButton.leadingAnchor.constraint(equalTo: instructionsLabel.leadingAnchor),
            signInButton.trailingAnchor.constraint(equalTo: instructionsLabel.trailingAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),
        ])
    }

    func applyTheme(theme: Theme) {
        emptyStateImageView.tintColor = theme.colors.iconDisabled
        titleLabel.textColor = theme.colors.textPrimary
        instructionsLabel.textColor = theme.colors.textPrimary
        signInButton.applyTheme(theme: theme)
        backgroundColor = theme.colors.layer3
    }

    @objc
    private func presentSignIn() {
        if let delegate = self.delegate {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .syncSignIn)
            delegate.remotePanelDidRequestToSignIn()
        }
    }

    @objc
    private func openAccountSettings() {
        delegate?.presentFxAccountSettings()
    }
}
