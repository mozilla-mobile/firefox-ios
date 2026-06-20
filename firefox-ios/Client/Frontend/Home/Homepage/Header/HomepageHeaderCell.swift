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

        // Quick Answers button wave (pulse) animation
        static let waveAnimationKey = "quickAnswersWave"
        static let waveAnimationKeyPath = "opacity"
        static let waveAnimationDuration: CFTimeInterval = 1.2
        static let waveAnimationFromOpacity: Float = 0.6
        static let waveAnimationToOpacity: Float = 1.0

        static func contentWidth() -> CGFloat {
            return UX.firefoxLogoImageSize.width + UX.interImageSpacing + UX.firefoxTextImageSize.width
        }
    }

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private var headerState: HeaderState?
    private var logoTextColor: UIColor?
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

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Remove the wave animation so it doesn't leak into a reused cell that hides the button.
        stopWaveAnimation()
    }

    // MARK: - UI Setup

    private func setupView(headerState: HeaderState) {
        let showsQuickAnswersButton = headerState.showQuickAnswersButton && !headerState.isPrivate

        if !hasConfiguredView {
            contentView.backgroundColor = .clear
            logoStackView.addArrangedSubview(logoImage)
            logoStackView.addArrangedSubview(logoTextImage)

            logoContainerView.addSubview(logoStackView)
            stackContainer.addArrangedSubview(logoContainerView)
            if showsQuickAnswersButton {
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

            // Build the header layout once. Re-running this on every configure deactivated and
            // reactivated the required centerX constraint alongside the low-priority leading/trailing
            // ones, producing a one-frame layout pass where the logo rendered centered before jumping
            // to the side. Performing the initial layout without animation avoids that visible flicker.
            setupConstraints()
            setupLogoConstraints()
            UIView.performWithoutAnimation {
                contentView.layoutIfNeeded()
            }

            hasConfiguredView = true
        }

        logoStackView.spacing = UX.interImageSpacing

        let logoAsset = headerState.isWorldCupSectionEnabled
            ? ImageIdentifiers.firefoxLogoSoccer
            : ImageIdentifiers.homeHeaderLogoBall
        logoImage.image = UIImage(imageLiteralResourceName: logoAsset)

        if showsQuickAnswersButton {
            startWaveAnimation()
        } else {
            stopWaveAnimation()
        }
    }

    private func setupConstraints() {
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
        logoConstraints = [
            logoImage.widthAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.width),
            logoImage.heightAnchor.constraint(equalToConstant: UX.firefoxLogoImageSize.height),
            logoTextImage.widthAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.width),
            logoTextImage.heightAnchor.constraint(equalToConstant: UX.firefoxTextImageSize.height),
            logoContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.firefoxLogoImageSize.height)
        ]

        NSLayoutConstraint.activate(logoConstraints)
    }

    // MARK: - Wave animation

    /// Start a subtle, repeating opacity pulse on the Quick Answers button to draw attention to it.
    private func startWaveAnimation() {
        guard quickAnswersButton.layer.animation(forKey: UX.waveAnimationKey) == nil else { return }
        let pulse = CABasicAnimation(keyPath: UX.waveAnimationKeyPath)
        pulse.fromValue = UX.waveAnimationFromOpacity
        pulse.toValue = UX.waveAnimationToOpacity
        pulse.duration = UX.waveAnimationDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        quickAnswersButton.layer.add(pulse, forKey: UX.waveAnimationKey)
    }

    private func stopWaveAnimation() {
        quickAnswersButton.layer.removeAnimation(forKey: UX.waveAnimationKey)
    }

    func configure(headerState: HeaderState,
                   logoTextColor: UIColor? = nil) {
        self.headerState = headerState
        self.logoTextColor = logoTextColor
        setupView(headerState: headerState)
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
