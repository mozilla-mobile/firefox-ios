// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit

class SurveySurfaceViewController: UIViewController, Themeable {
    struct UX {
        static let buttonCornerRadius: CGFloat = 13
        static let buttonFontSize: CGFloat  = 16
        static let buttonMaxWidth: CGFloat  = 400
        static let buttonHeight: CGFloat = 45
        static let buttonSeparation: CGFloat = 8
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonSideMarginMultiplier: CGFloat  = 0.05
        static let buttonBottomMarginMultiplier: CGFloat  = 0.1

        static let titleFontSize: CGFloat = 20

        static let imageViewSize = CGSize(width: 128, height: 128)
    }

    // MARK: - Variables
    var viewModel: SurveySurfaceViewModel

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: - UI Elements
    lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.imageView
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.titleFontSize)
        label.isHidden = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.textLabel
    }

    private lazy var takeSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.takeSurveyAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.takeSurveyButton
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var dismissSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.dismissAction), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.dismissButton
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    // MARK: - View Lifecyle
    init(viewModel: SurveySurfaceViewModel,
         themeManager: ThemeManager,
         notificationCenter: NotificationProtocol
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupView()
        updateLayout()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        delegate?.pageChanged(viewModel.cardType)
//        viewModel.sendCardViewTelemetry()
    }

    func setupView() {
        view.addSubview(dismissSurveyButton)
        view.addSubview(takeSurveyButton)

        let buttonSideMargin = view.frame.width * UX.buttonSideMarginMultiplier

        NSLayoutConstraint.activate([
            takeSurveyButton.widthAnchor.constraint(lessThanOrEqualToConstant: UX.buttonMaxWidth),
            takeSurveyButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            takeSurveyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: buttonSideMargin),
            takeSurveyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -buttonSideMargin),
            dismissSurveyButton.bottomAnchor.constraint(equalTo: dismissSurveyButton.topAnchor,
                                                        constant: UX.buttonSeparation),

            dismissSurveyButton.widthAnchor.constraint(lessThanOrEqualToConstant: UX.buttonMaxWidth),
            dismissSurveyButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            dismissSurveyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: buttonSideMargin),
            dismissSurveyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -buttonSideMargin),
            dismissSurveyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                        constant: -(view.frame.height * UX.buttonBottomMarginMultiplier))
        ])
    }

    private func updateLayout() {
        titleLabel.text = viewModel.info.text
        imageView.image = viewModel.info.image
        takeSurveyButton.setTitle(viewModel.info.takeSurveyButtonLabel, for: .normal)
        dismissSurveyButton.setTitle(viewModel.info.dismissActionLabel, for: .normal)
//        handleSecondaryButton()
    }

    @objc func takeSurveyAction() {
        print("RGB - take the survey!")
//        viewModel.sendTelemetryButton(isPrimaryAction: true)
//        delegate?.primaryAction(viewModel.cardType)
    }

    @objc func dismissAction() {
        dismiss(animated: true)
        print("RGB - dismiss me!")
//        viewModel.sendTelemetryButton(isPrimaryAction: false)
//        delegate?.showNextPage(viewModel.cardType)
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.currentTheme

        view.backgroundColor = theme.colors.layer2

        titleLabel.textColor = theme.colors.textPrimary

        takeSurveyButton.setTitleColor(theme.colors.textInverted, for: .normal)
        takeSurveyButton.backgroundColor = theme.colors.actionPrimary

        dismissSurveyButton.setTitleColor(theme.colors.textSecondaryAction, for: .normal)
        dismissSurveyButton.backgroundColor = theme.colors.actionSecondary
//        handleSecondaryButton()
    }
}
