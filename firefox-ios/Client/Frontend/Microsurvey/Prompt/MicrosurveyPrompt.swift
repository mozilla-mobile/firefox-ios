// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ComponentLibrary
import Redux

/*
 |----------------|
 | [Logo] Title X |
 |----------------|
 |    [Button]    |
 |----------------|
 */

class MicrosurveyPromptView: UIView, ThemeApplicable {
    struct UX {
        static let headerStackSpacing: CGFloat = 8
        static let stackSpacing: CGFloat = 17
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let logoSize = CGSize(width: 24, height: 24)
        static let padding = NSDirectionalEdgeInsets(
            top: 14,
            leading: 16,
            bottom: -12,
            trailing: -16
        )
    }

    private let windowUUID: WindowUUID

    private lazy var logoImage: UIImageView = .build { imageView in
            imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
            imageView.contentMode = .scaleAspectFit
    }

    private var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
    }

    private lazy var closeButton: UIButton = .build { button in
        button.accessibilityLabel = .Microsurvey.Prompt.CloseButtonAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeMicroSurvey), for: .touchUpInside)
    }

    private lazy var headerView: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = UX.headerStackSpacing
    }

    private lazy var surveyButton: SecondaryRoundedButton = .build { button in
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

    init(state: MicrosurveyPromptState, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        configure(with: state)
        setupView()
    }

    private func configure(with state: MicrosurveyPromptState) {
        titleLabel.text = state.model?.promptTitle
        let roundedButtonViewModel = SecondaryRoundedButtonViewModel(
            title: state.model?.promptButtonLabel,
            a11yIdentifier: AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton
        )
        surveyButton.configure(viewModel: roundedButtonViewModel)
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

        addSubview(toastView)

        NSLayoutConstraint.activate([
            toastView.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding.top),
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding.leading),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: UX.padding.trailing),
            toastView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.padding.bottom),

            logoImage.widthAnchor.constraint(equalToConstant: UX.logoSize.width),
            logoImage.heightAnchor.constraint(equalToConstant: UX.logoSize.height),

            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
        ])
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        surveyButton.applyTheme(theme: theme)
    }
}
