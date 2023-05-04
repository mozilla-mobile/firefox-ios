// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

class OnboardingDefaultSettingsViewController: UIViewController, Themeable {
    private struct UX {
        static let contentStackViewSpacing: CGFloat = 40
    }

    lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.contentStackViewSpacing
        stack.axis = .vertical
    }

    var viewModel: OnboardingCardProtocol
    weak var delegate: OnboardingCardDelegate?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    init(viewModel: OnboardingCardProtocol,
         delegate: OnboardingCardDelegate?,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.delegate = delegate
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

    func setupView() {
    }

    private func updateLayout() {
//        titleLabel.text = viewModel.infoModel.title
//        descriptionBoldLabel.isHidden = !viewModel.shouldShowDescriptionBold
//        descriptionBoldLabel.text = .Onboarding.IntroDescriptionPart1
//        descriptionLabel.isHidden = viewModel.infoModel.description?.isEmpty ?? true
//        descriptionLabel.text = viewModel.infoModel.description
//
//        imageView.image = viewModel.infoModel.image
//        primaryButton.setTitle(viewModel.infoModel.primaryAction, for: .normal)
//        handleSecondaryButton()
    }

    func applyTheme() {
    }
}
