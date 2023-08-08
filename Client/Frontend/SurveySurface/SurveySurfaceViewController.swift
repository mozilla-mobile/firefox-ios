// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import Shared
import UIKit

protocol SurveySurfaceViewControllerDelegate: AnyObject {
    func didFinish()
}

class SurveySurfaceViewController: UIViewController, Themeable {
    struct UX {
        static let buttonCornerRadius: CGFloat = 13
        static let buttonFontSize: CGFloat  = 16
        static let buttonMaxWidth: CGFloat  = 400
        static let buttonHeight: CGFloat = 45
        static let buttonSeparation: CGFloat = 8
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonBottomMarginMultiplier: CGFloat  = 0.1

        static let sideMarginMultiplier: CGFloat  = 0.05

        static let titleFontSize: CGFloat = 20
        static let titleDistanceFromImage: CGFloat = 16
        static let titleWidth: CGFloat = 343

        static let imageViewSize = CGSize(width: 130, height: 130)
        static let imageViewCenterYOffset: CGFloat = 0.1
    }

    // MARK: - Variables
    weak var delegate: SurveySurfaceViewControllerDelegate?
    var viewModel: SurveySurfaceViewModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var imageViewYConstraint: NSLayoutConstraint!

    // MARK: - UI Elements
    // Other than the imageView, all elements begin with an alpha of 0.0 as,
    // they are meant to be invisible, and appear during the animation.
    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.imageView
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .title3,
                                                                size: UX.titleFontSize)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.SurveySurface.textLabel
        label.alpha = 0.0
    }

    private lazy var takeSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
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
        button.alpha = 0.0
    }

    private lazy var dismissSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
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
        button.alpha = 0.0
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
        updateContent()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.setOrientationLockTo(on: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.didDisplayMessage()
        animateElements()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.setOrientationLockTo(on: false)
    }

    // MARK: - View setup
    private func setupView() {
        addViews()
        constrainViews()
    }

    private func addViews() {
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(dismissSurveyButton)
        view.addSubview(takeSurveyButton)
    }

    private func constrainViews() {
        imageViewYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)

        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: UX.imageViewSize.height),
            imageView.widthAnchor.constraint(equalToConstant: UX.imageViewSize.width),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageViewYConstraint,

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor,
                                            constant: UX.titleDistanceFromImage),
            titleLabel.widthAnchor.constraint(equalToConstant: calculateElementWidthWith(max: UX.titleWidth)),
            titleLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),

            takeSurveyButton.widthAnchor.constraint(equalToConstant: calculateElementWidthWith(max: UX.buttonMaxWidth)),
            takeSurveyButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            takeSurveyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            takeSurveyButton.bottomAnchor.constraint(equalTo: dismissSurveyButton.topAnchor,
                                                     constant: -UX.buttonSeparation),

            dismissSurveyButton.widthAnchor.constraint(equalTo: takeSurveyButton.widthAnchor),
            dismissSurveyButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            dismissSurveyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissSurveyButton.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                        constant: -(view.frame.height * UX.buttonBottomMarginMultiplier))
        ])
    }

    private func calculateElementWidthWith(max maxWidth: CGFloat) -> CGFloat {
        // The side margins are at a certain percentage, thus the button width would have
        // to be the inverse of 2*that or the max width determined  by design.
        let viewBasedWidth = view.frame.width * (1.0 - (2 * UX.sideMarginMultiplier))
        guard let elementWidth = [maxWidth, viewBasedWidth].min() else { return maxWidth }

        return elementWidth
    }

    private func updateContent() {
        let titleString = String(format: viewModel.info.text, AppName.shortName.rawValue)
        titleLabel.text = titleString
        imageView.image = viewModel.info.image
        takeSurveyButton.setTitle(viewModel.info.takeSurveyButtonLabel, for: .normal)
        dismissSurveyButton.setTitle(viewModel.info.dismissActionLabel, for: .normal)
    }

    /// Animates the elements of the view from their initial position and alpha settings,
    /// to their final positions & alpha settings. This animation exists to make the
    /// transition from the splash screen to the survey surface very smooth.
    private func animateElements() {
        changeImageViewConstraint()
        UIView.animate(
            withDuration: 0.3,
            animations: ({
                self.view.layoutIfNeeded()
            })
        ) { _ in
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.titleLabel.alpha = 1
                self.takeSurveyButton.alpha = 1
                self.dismissSurveyButton.alpha = 1
            }
        }
    }

    /// Changes the constraint of the imageView. This needs to be done separately
    /// if we want to do it in an animation.
    private func changeImageViewConstraint() {
        NSLayoutConstraint.deactivate([imageViewYConstraint])
        imageViewYConstraint = imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor,
                                                                  constant: -(view.frame.height * UX.imageViewCenterYOffset))
        NSLayoutConstraint.activate([imageViewYConstraint])
    }

    // MARK: - Button Actions
    @objc
    func takeSurveyAction() {
        viewModel.didTapTakeSurvey()
        delegate?.didFinish()
    }

    @objc
    func dismissAction() {
        viewModel.didTapDismissSurvey()
        delegate?.didFinish()
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
    }
}
