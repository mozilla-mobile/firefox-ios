// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ComponentLibrary

/*
 |----------------|
 | [Logo] Title X |
 |----------------|
 |    [Button]    |
 |----------------|
 */

class MicroSurveyPromptView: UIView, ThemeApplicable {
    private var viewModel: MicroSurveyViewModel
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
        // TODO: FXIOS-8987 - Add accessibility labels
        button.accessibilityIdentifier = AccessibilityIdentifiers.MicroSurvey.Prompt.closeButton
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
        viewModel.closeAction()
    }

    @objc
    func openMicroSurvey() {
        viewModel.openAction()
    }

    init(viewModel: MicroSurveyViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
        configure()
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

    private func configure() {
        titleLabel.text = viewModel.title
        let roundedButtonViewModel = SecondaryRoundedButtonViewModel(
            title: viewModel.buttonText,
            a11yIdentifier: AccessibilityIdentifiers.MicroSurvey.Prompt.takeSurveyButton
        )
        surveyButton.configure(viewModel: roundedButtonViewModel)
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
        surveyButton.applyTheme(theme: theme)
    }
}
