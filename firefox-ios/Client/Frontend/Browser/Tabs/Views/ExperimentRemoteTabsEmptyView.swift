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
        static let paddingInBetweenItems: CGFloat = 15
        static let verticalPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let imageSize = CGSize(width: 72, height: 72)
        static let containerWidthConstant = horizontalPadding * 2
    }

    var needsSafeArea: Bool { true }
    weak var delegate: RemoteTabsEmptyViewDelegate?

    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollview in
        scrollview.backgroundColor = .clear
        scrollview.contentInset = UIEdgeInsets(top: UX.verticalPadding,
                                               left: UX.horizontalPadding,
                                               bottom: UX.verticalPadding,
                                               right: UX.horizontalPadding)
    }

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

    private let signInButton: RoundedButtonWithImage = .build()

    // Animation used to rotate the Sync icon 360 degrees while syncing is in progress.
    private let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    private let syncIcon = UIImage(named: StandardImageIdentifiers.Large.sync)

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

        if isSyncing {
            let viewModel = RoundedButtonWithImageViewModel(
                title: .SyncingMessageWithEllipsis,
                image: StandardImageIdentifiers.Large.sync,
                a11yIdentifier: AccessibilityIdentifiers.TabTray.syncDataButton
            )
            signInButton.configure(viewModel: viewModel)

            // Animation that loops continuously until stopped
            continuousRotateAnimation.fromValue = 0.0
            continuousRotateAnimation.toValue = CGFloat(Double.pi)
            continuousRotateAnimation.isRemovedOnCompletion = true
            continuousRotateAnimation.duration = 0.5
            continuousRotateAnimation.repeatCount = .infinity
            self.signInButton.isUserInteractionEnabled = false

            self.signInButton.imageView?.layer.add(self.continuousRotateAnimation, forKey: "rotateKey")
        } else {
            let viewModel = RoundedButtonWithImageViewModel(
                title: .Settings.Sync.ButtonTitle,
                image: nil,
                a11yIdentifier: AccessibilityIdentifiers.TabTray.syncDataButton
            )
            signInButton.configure(viewModel: viewModel)
        }

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
            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                                 constant: -UX.containerWidthConstant),

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

    // MARK: - InsetUpdatable

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        scrollView.contentInset.top = top
        scrollView.contentInset.bottom = bottom + UX.verticalPadding
    }
}
