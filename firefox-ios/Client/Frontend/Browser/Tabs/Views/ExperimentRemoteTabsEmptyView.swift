// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

@MainActor
protocol RemoteTabsEmptyViewProtocol: UIView, ThemeApplicable, InsetUpdatable {
    @MainActor
    var needsSafeArea: Bool { get }
    func configure(config: RemoteTabsPanelEmptyStateReason,
                   delegate: RemoteTabsEmptyViewDelegate?,
                   isSyncing: Bool)
}

class ExperimentRemoteTabsEmptyView: UIView,
                                     RemoteTabsEmptyViewProtocol {
    struct UX {
        static let topPadding: CGFloat = 55
        static let bottomPadding: CGFloat = 35
        static let paddingInBetweenItems: CGFloat = 15
        static let buttonTopPadding: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 72, height: 72)
    }

    var needsSafeArea: Bool { true }
    weak var delegate: RemoteTabsEmptyViewDelegate?

    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { _ in }

    private let iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .center
    }

    private let signInButton: RoundedButtonWithImage = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(config: RemoteTabsPanelEmptyStateReason,
                   delegate: RemoteTabsEmptyViewDelegate?,
                   isSyncing: Bool) {
        self.delegate = delegate

        iconImageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cloud)
        titleLabel.text =  .EmptySyncedTabsPanelStateTitle
        descriptionLabel.text = config.localizedString()

        let viewModel = RoundedButtonWithImageViewModel(
            title: isSyncing ? .SyncingMessageWithEllipsis : .Settings.Sync.ButtonTitle,
            image: isSyncing ? StandardImageIdentifiers.Large.sync : nil,
            isAnimating: isSyncing,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.syncDataButton
        )
        signInButton.configure(viewModel: viewModel)

        if config == .notLoggedIn || config == .failedToSync {
            signInButton.addTarget(self, action: #selector(presentSignIn), for: .touchUpInside)
        } else if config == .syncDisabledByUser {
            signInButton.addTarget(self, action: #selector(openAccountSettings), for: .touchUpInside)
        }

        signInButton.isHidden = shouldHideButton(config)

        // Recalculate layout after setting text. Labels initialize empty, causing button to clip
        // multi-line text at large Dynamic Type sizes if intrinsic size isn't updated.
        signInButton.invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    private func shouldHideButton(_ state: RemoteTabsPanelEmptyStateReason) -> Bool {
        return state == .noClients && state == .noTabs
    }

    private func setupLayout() {
        containerView.addSubviews(iconImageView, titleLabel, descriptionLabel, signInButton)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

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

            signInButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                              constant: UX.buttonTopPadding),
            signInButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                  constant: UX.horizontalPadding),
            signInButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                   constant: -UX.horizontalPadding),
            signInButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                                 constant: -UX.bottomPadding),
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

    // MARK: - InsetUpdatable

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        scrollView.contentInset.top = top
        scrollView.contentInset.bottom = bottom
    }
}
