// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

class OnboardingMultipleChoiceButtonView: UIView, Themeable {
    // MARK: - UX/UI
    struct UX {
        struct Measurements {
            static let imageWidth: CGFloat = 60
            static let imageHeight: CGFloat = 97
            static let checkboxDimensions: CGFloat = 24
            static let imageCornerRadius: CGFloat = 10
            static let imageBorderWidth: CGFloat = 5
            static let stackViewSpacing: CGFloat = 7
            static let containerViewWidth: CGFloat = 80
        }

        struct Images {
            static let selected = ImageIdentifiers.radioButtonSelected
            static let notSelected = ImageIdentifiers.radioButtonNotSelected
        }
    }

    private lazy var containerView: UIView = .build { _ in }

    private lazy var button: UIButton = .build { button in
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.a11yIDRoot)MultipleChoiceButton"
        button.accessibilityTraits.insert(.button)
        button.isAccessibilityElement = true
        button.accessibilityLabel = self.viewModel.info.title
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: self.viewModel.info.imageID)
        imageView.layer.cornerRadius = UX.Measurements.imageCornerRadius
        imageView.layer.borderWidth = UX.Measurements.imageBorderWidth
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIDRoot)ImageView"
        imageView.isAccessibilityElement = false
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.text = self.viewModel.info.title
        label.numberOfLines = 0
        label.accessibilityIdentifier = "\(self.viewModel.info.title)TitleLabel"
        label.isAccessibilityElement = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var checkboxView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: UX.Images.notSelected)
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIDRoot)CheckboxView"
        imageView.isAccessibilityElement = false
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = UX.Measurements.stackViewSpacing
    }

    // MARK: - Properties
    let windowUUID: WindowUUID
    var viewModel: OnboardingMultipleChoiceButtonViewModel
    var themeManager: Common.ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: Common.NotificationProtocol
    weak var buttonActionDelegate: OnboardingCardDelegate?
    weak var stateUpdateDelegate: OnboardingMultipleChoiceSelectionDelegate?

    // MARK: - View configuration
    init(
        windowUUID: WindowUUID,
        frame: CGRect = .zero,
        viewModel: OnboardingMultipleChoiceButtonViewModel,
        buttonActionDelegate: OnboardingCardDelegate?,
        stateUpdateDelegate: OnboardingMultipleChoiceSelectionDelegate?,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.viewModel = viewModel
        self.buttonActionDelegate = buttonActionDelegate
        self.stateUpdateDelegate = stateUpdateDelegate
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(frame: frame)

        setupLayout()
        updateUIForState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addViews()

        NSLayoutConstraint.activate(
            [
                imageView.widthAnchor.constraint(equalToConstant: UX.Measurements.imageWidth),
                imageView.heightAnchor.constraint(equalToConstant: UX.Measurements.imageHeight),

                checkboxView.widthAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),
                checkboxView.heightAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),

                stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
                stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

                button.topAnchor.constraint(equalTo: containerView.topAnchor),
                button.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                button.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

                containerView.widthAnchor.constraint(equalToConstant: UX.Measurements.containerViewWidth),
                containerView.topAnchor.constraint(equalTo: self.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ]
        )
    }

    private func addViews() {
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(checkboxView)
        containerView.addSubview(stackView)
        containerView.addSubview(button)
        addSubview(containerView)
    }

    func updateUIForState() {
        if viewModel.isSelected {
            checkboxView.image = UIImage(named: UX.Images.selected)
        } else {
            checkboxView.image = UIImage(named: UX.Images.notSelected)
        }
        applyTheme()
    }

    private func applySelectedUI() {
        checkboxView.image = UIImage(named: UX.Images.selected)
    }

    private func applyDeselectedUI() {
        checkboxView.image = UIImage(named: UX.Images.notSelected)
    }

    // MARK: - Actions
    @objc
    func buttonTapped() {
        buttonActionDelegate?.handleMultipleChoiceButtonActions(
            for: viewModel.info.action,
            from: viewModel.presentingCardName
        )
        stateUpdateDelegate?.updateSelectedButton(to: viewModel.info.title)
    }

    // MARK: - Theme
    func applyTheme() {
        backgroundColor = .clear
        titleLabel.textColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
        imageView.layer.borderColor = if viewModel.isSelected {
            themeManager.getCurrentTheme(for: windowUUID).colors.actionPrimary.cgColor
        } else {
            UIColor.clear.cgColor
        }
    }
}
