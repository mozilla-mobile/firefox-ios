// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ComponentLibrary
import Redux
import Shared

/*
 |----------------|
 | [Logo] Title X |
 |----------------|
 |    [Button]    |
 |----------------|
 */

final class MicrosurveyPromptView: UIView, ThemeApplicable, Notifiable {
    private struct UX {
        static let headerStackSpacing: CGFloat = 8
        static let stackSpacing: CGFloat = 17
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let borderThickness = 1.0
        static let logoSize: CGFloat = 24
        static let padding = NSDirectionalEdgeInsets(
            top: 14,
            leading: 16,
            bottom: -12,
            trailing: -16
        )
        static let mediumPadding = NSDirectionalEdgeInsets(
            top: 16,
            leading: 66,
            bottom: -16,
            trailing: -66
        )
        static let largePadding = NSDirectionalEdgeInsets(
            top: 22,
            leading: 258,
            bottom: -22,
            trailing: -258
        )
    }

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var logoWidthConstraint: NSLayoutConstraint?
    private var logoHeightConstraint: NSLayoutConstraint?

    private var logoSizeScaled: CGFloat {
        return UIFontMetrics.default.scaledValue(for: UX.logoSize)
    }

    private let windowUUID: WindowUUID
    var notificationCenter: NotificationProtocol

    private var topBorderView: UIView = .build()

    private lazy var logoImage: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = String(
            format: .Microsurvey.Prompt.LogoImageA11yLabel,
            AppName.shortName.rawValue
        )
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo
    }

    private var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeMicroSurvey), for: .touchUpInside)
    }

    private lazy var headerView: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = UX.headerStackSpacing
    }

    private lazy var surveyButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.openMicroSurvey), for: .touchUpInside)
    }

    private lazy var toastView: UIStackView = .build { stack in
        stack.spacing = UX.stackSpacing
        stack.distribution = .fillProportionally
        stack.axis = .vertical
    }

    @objc
    func closeMicroSurvey() {
        store.dispatch(
            MicrosurveyPromptAction(windowUUID: windowUUID, actionType: MicrosurveyPromptActionType.closePrompt)
        )
    }

    @objc
    func openMicroSurvey() {
        store.dispatch(
            MicrosurveyPromptAction(windowUUID: windowUUID, actionType: MicrosurveyPromptActionType.continueToSurvey)
        )
    }

    init(
        state: MicrosurveyPromptState,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        inOverlayMode: Bool = false
    ) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(frame: .zero)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        configure(with: state)
        setupView()
        guard !inOverlayMode else { return }
        UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
    }

    private func configure(with state: MicrosurveyPromptState) {
        titleLabel.text = state.model?.promptTitle
        // TODO: FXIOS-8990 - Mobile Messaging Structure - Should use MicrosurveyModel instead of State
        let roundedButtonViewModel = PrimaryRoundedButtonViewModel(
            title: state.model?.promptButtonLabel ?? "",
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton
        )
        let closeButtonViewModel = CloseButtonViewModel(
            a11yLabel: .Microsurvey.Prompt.CloseButtonAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
        )
        surveyButton.configure(viewModel: roundedButtonViewModel)
        closeButton.configure(viewModel: closeButtonViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        headerView.addArrangedSubview(logoImage)
        headerView.addArrangedSubview(titleLabel)
        headerView.addArrangedSubview(closeButton)

        toastView.addArrangedSubview(headerView)
        toastView.addArrangedSubview(surveyButton)

        addSubview(topBorderView)
        addSubview(toastView)
        leadingConstraint = toastView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = toastView.trailingAnchor.constraint(equalTo: trailingAnchor)
        logoWidthConstraint = logoImage.widthAnchor.constraint(equalToConstant: logoSizeScaled)
        logoHeightConstraint = logoImage.heightAnchor.constraint(equalToConstant: logoSizeScaled)

        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
        logoWidthConstraint?.isActive = true
        logoHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            topBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorderView.topAnchor.constraint(equalTo: topAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: UX.borderThickness),

            toastView.topAnchor.constraint(equalTo: topBorderView.bottomAnchor, constant: UX.padding.top),
            toastView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.padding.bottom),

            headerView.widthAnchor.constraint(equalTo: toastView.widthAnchor),
            titleLabel.heightAnchor.constraint(equalTo: headerView.heightAnchor),
        ])
    }

    override func updateConstraints() {
        super.updateConstraints()
        updatePadding()
    }

    private func updatePadding() {
        var paddingConstant: NSDirectionalEdgeInsets = UX.padding

        if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
            paddingConstant = UIWindow.isLandscape ? UX.largePadding : UX.mediumPadding
        } else if UIDevice.current.userInterfaceIdiom == .phone && UIWindow.isLandscape {
            paddingConstant = UX.mediumPadding
        }

        leadingConstraint?.constant = paddingConstant.leading
        trailingConstraint?.constant = paddingConstant.trailing
    }

    private func adjustIconSize() {
        logoWidthConstraint?.constant = logoSizeScaled
        logoHeightConstraint?.constant = logoSizeScaled
    }

    // MARK: ThemeApplicable
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        topBorderView.backgroundColor = theme.colors.borderPrimary
        surveyButton.applyTheme(theme: theme)
    }

    // MARK: Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustIconSize()
        default: break
        }
    }
}
