// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared

// Header for the homepage in both normal and private mode
// Contains the firefox logo, and optionally the Quick Answers button
class HomepageHeaderCell: UICollectionViewCell, ReusableCell, ThemeApplicable, FeatureFlaggable {
    enum UX {
        static let firefoxLogoImageSize = CGSize(width: 40, height: 40)
        static let firefoxTextImageSize = CGSize(width: 90, height: 40)
        static let interImageSpacing: CGFloat = 10
        static let quickAnswersButtonSize: CGFloat = 44

        static func contentWidth() -> CGFloat {
            return UX.firefoxLogoImageSize.width + UX.interImageSpacing + UX.firefoxTextImageSize.width
        }
    }

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private var onQuickAnswersTapped: (() -> Void)?
    private var headerState: HeaderState?
    private var hasConfiguredView = false
    private var headerConstraints = [NSLayoutConstraint]()
    private var logoConstraints = [NSLayoutConstraint]()

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoContainerView: UIView = .build()

    private lazy var logoStackView: UIStackView = .build { view in
        view.backgroundColor = .clear
        view.alignment = .center
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var quickAnswersButton: UIButton = .build { button in
        button.configuration = .filled()
        // TODO: - FXIOS-15477 Add correct acorn icon
        button.configuration?.image = UIImage(systemName: "waveform")
        button.configuration?.cornerStyle = .capsule
        // TODO: - FXIOS-14720 Add Strings for accessibility label
        button.accessibilityIdentifier = a11y.quickAnswersButton
        button.adjustsImageSizeForAccessibilityContentSizeCategory = false
        button.addAction(
            UIAction(handler: { [weak self] _ in
                self?.onQuickAnswersTapped?()
            }),
            for: .touchUpInside
        )
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupView(headerState: HeaderState) {
        if !hasConfiguredView {
            contentView.backgroundColor = .clear
            logoStackView.addArrangedSubview(logoImage)
            logoStackView.addArrangedSubview(logoTextImage)

            logoContainerView.addSubview(logoStackView)
            stackContainer.addArrangedSubview(logoContainerView)
            if featureFlagsProvider.isEnabled(.quickAnswers), !headerState.isPrivate {
                if headerState.showiPadSetup {
                    // On iPad, add button directly to contentView so logo remains centered
                    contentView.addSubview(quickAnswersButton)
                } else {
                    // On iPhone, add spacer view to stretch the logo and the button to leading and trailing
                    stackContainer.addArrangedSubview(UIView())
                    stackContainer.addArrangedSubview(quickAnswersButton)
                }
            }
            contentView.addSubview(stackContainer)
            logoStackView.pinToSuperview()

            hasConfiguredView = true
        }

        logoStackView.spacing = UX.interImageSpacing

        setupConstraints()
        setupLogoConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.deactivate(headerConstraints)

        headerConstraints = [
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),
            stackContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).priority(.defaultLow),
            stackContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).priority(.defaultLow),

            quickAnswersButton.widthAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize),
            quickAnswersButton.heightAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize),
        ]
        // Instead of checking on the state check if the quickAnswer button was added to the superview in order to avoid
        // potential crashes.
        // When the button is added to the contentView it is the iPad layout.
        if quickAnswersButton.superview == contentView {
            headerConstraints.append(contentsOf: [
                quickAnswersButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                quickAnswersButton.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate(headerConstraints)
    }

    private func setupLogoConstraints() {
        NSLayoutConstraint.deactivate(logoConstraints)
        logoConstraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.width),
            logoImage.heightAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.height),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.width),
            logoTextImage.heightAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.height),
            logoContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.firefoxLogoImageSize.height)
        ]

        NSLayoutConstraint.activate(logoConstraints)
    }

    func configure(headerState: HeaderState, onQuickAnswersTapped: (() -> Void)? = nil) {
        self.headerState = headerState
        self.onQuickAnswersTapped = onQuickAnswersTapped
        setupView(headerState: headerState)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        // TODO: FXIOS-10851 This can be moved to the new homescreen wallpaper fetching redux
        let wallpaperManager = WallpaperManager()
        let browserViewType = store.state.componentState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: currentWindowUUID
        )?.browserViewType

        if let logoTextColor = wallpaperManager.currentWallpaper.logoTextColor, browserViewType != .privateHomepage {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = logoTextColor
        } else {
            logoTextImage.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
                .withRenderingMode(.alwaysTemplate)
            logoTextImage.tintColor = theme.colors.textPrimary
        }

        quickAnswersButton.configuration?.baseBackgroundColor = theme.colors.layer4
        quickAnswersButton.configuration?.baseForegroundColor = theme.colors.actionPrimary
    }
}
