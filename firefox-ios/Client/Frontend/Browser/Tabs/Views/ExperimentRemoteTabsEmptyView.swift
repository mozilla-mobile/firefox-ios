// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

protocol RemoteTabsEmptyViewProtocol: UIView, ThemeApplicable {
    func configure(config: RemoteTabsPanelEmptyStateReason,
                   delegate: RemoteTabsEmptyViewDelegate?)
}

class ExperimentRemoteTabsEmptyView: UIView, RemoteTabsEmptyViewProtocol {
    struct UX {
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 72, height: 72)
    }

    weak var delegate: RemoteTabsEmptyViewDelegate?

    // MARK: - UI

    private lazy var containerView: UIView = .build { _ in }

    private let iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let signInButton: SecondaryRoundedButton = .build { button in
        let viewModel = SecondaryRoundedButtonViewModel(
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

    func configure(config: RemoteTabsPanelEmptyStateReason,
                   delegate: RemoteTabsEmptyViewDelegate?) {
        self.delegate = delegate

        iconImageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cloud)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        descriptionLabel.text = config.localizedString()

        if config == .notLoggedIn || config == .failedToSync {
            signInButton.addTarget(self, action: #selector(presentSignIn), for: .touchUpInside)
        } else if config == .syncDisabledByUser {
            signInButton.addTarget(self, action: #selector(openAccountSettings), for: .touchUpInside)
        }

        signInButton.isHidden = shouldHideButton(config)
    }

    private func shouldHideButton(_ state: RemoteTabsPanelEmptyStateReason) -> Bool {
        return state == .noClients && state == .noTabs
    }

    private func setupLayout() {
        containerView.addSubviews(iconImageView, titleLabel, descriptionLabel, signInButton)
        addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: UX.horizontalPadding),
            containerView.topAnchor.constraint(equalTo: topAnchor,
                                               constant: UX.verticalPadding),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                    constant: -UX.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                  constant: -UX.verticalPadding),

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
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                      constant: UX.horizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                       constant: -UX.horizontalPadding),

            signInButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                              constant: UX.paddingInBetweenItems),
            signInButton.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor),
            signInButton.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor),
            signInButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            signInButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                 constant: -UX.paddingInBetweenItems),
        ])
    }

    func applyTheme(theme: Theme) {
        iconImageView.tintColor = theme.colors.iconDisabled
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
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
