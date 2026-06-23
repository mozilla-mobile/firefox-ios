// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import QuickAnswersKit

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

    private var headerState: HeaderState?
    private var logoTextColor: UIColor?

    private lazy var stackContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    private lazy var logoContainerView: UIView = .build()

    private lazy var logoStackView: UIStackView = .build { view in
        view.backgroundColor = .clear
        view.alignment = .center
        view.spacing = UX.interImageSpacing
        view.accessibilityIdentifier = a11y.logoID
        view.accessibilityLabel = AppName.shortName.rawValue
        view.isAccessibilityElement = true
        view.accessibilityTraits = .image
    }

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var logoTextImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoText)
            .withRenderingMode(.alwaysTemplate)
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
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.quickAnswerButtonTapped()
        }), for: .touchUpInside)
    }

    /// Centers the logo within the cell. Active when the Quick Answers button is hidden, or when
    /// it is shown on the iPad layout where the logo remains centered.
    private lazy var logoCenterXConstraint = stackContainer.centerXAnchor.constraint(
        equalTo: contentView.centerXAnchor
    )

    /// Pins the logo to the leading edge. Active on the iPhone layout when the Quick Answers button
    /// is shown, so the logo sits leading and the button trailing.
    private lazy var logoLeadingConstraint = stackContainer.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor
    )

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupLayout() {
        contentView.backgroundColor = .clear

        logoStackView.addArrangedSubview(logoImage)
        logoStackView.addArrangedSubview(logoTextImage)
        logoContainerView.addSubview(logoStackView)
        stackContainer.addArrangedSubview(logoContainerView)

        contentView.addSubview(stackContainer)
        contentView.addSubview(quickAnswersButton)

        logoStackView.pinToSuperview()

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultLow),

            logoImage.widthAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.width),
            logoImage.heightAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.height),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.width),
            logoTextImage.heightAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.height),
            logoContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.firefoxLogoImageSize.height),

            quickAnswersButton.widthAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize),
            quickAnswersButton.heightAnchor.constraint(equalToConstant: UX.quickAnswersButtonSize),
            quickAnswersButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            quickAnswersButton.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor),
        ])
    }

    func configure(headerState: HeaderState,
                   logoTextColor: UIColor? = nil) {
        self.headerState = headerState
        self.logoTextColor = logoTextColor

        let logoAsset = headerState.isWorldCupSectionEnabled
            ? ImageIdentifiers.firefoxLogoSoccer
            : ImageIdentifiers.homeHeaderLogoBall
        logoImage.image = UIImage(imageLiteralResourceName: logoAsset)

        quickAnswersButton.isHidden = !headerState.showQuickAnswersButton

        // if the quick answers button is visible and we are on iPhone setup, align the logo to the leading
        let alignLogoToLeading = headerState.showQuickAnswersButton && !headerState.showiPadSetup
        logoCenterXConstraint.isActive = !alignLogoToLeading
        logoLeadingConstraint.isActive = alignLogoToLeading
    }

    private func quickAnswerButtonTapped() {
        guard let headerState else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let transitionType: QuickAnswersTransitionType = if headerState.showiPadSetup {
            .formSheet
        } else {
            // convert the button frame to the parent window frame to have correct transition.
            .crossDissolve(sourceRect: quickAnswersButton.convert(quickAnswersButton.bounds, to: nil))
        }
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.quickAnswers(transitionType: transitionType)),
                windowUUID: headerState.windowUUID,
                actionType: NavigationBrowserActionType.tapOnQuickAnswersButton
            )
        )
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        logoTextImage.tintColor = logoTextColor ?? theme.colors.textPrimary

        quickAnswersButton.configuration?.baseBackgroundColor = theme.colors.layer4
        quickAnswersButton.configuration?.baseForegroundColor = theme.colors.actionPrimary
    }
}
