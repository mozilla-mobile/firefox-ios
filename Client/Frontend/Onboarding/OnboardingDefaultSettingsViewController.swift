// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

class OnboardingDefaultSettingsViewController: UIViewController, Themeable {
    private enum UX {
        static let contentStackViewSpacing: CGFloat = 40
        static let titleFontSize: CGFloat = 20
        static let buttonFontSize: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.contentStackViewSpacing
        stack.axis = .vertical
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.titleFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)TitleLabel"
    }

    private lazy var numaratedLabels: [UILabel] = []

    private lazy var textStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.distribution = .fill
        stack.axis = .vertical
        stack.spacing = UX.contentStackViewSpacing
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)PrimaryButton"
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
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
        view.backgroundColor = .clear

        contentStackView.addArrangedSubview(titleLabel)
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

    @objc
    func primaryAction() {
    }

    func applyTheme() {
    }
}
