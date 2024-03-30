// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

class OnboardingMultipleChoiceButtonView: UIView, ThemeApplicable {
    // MARK: - UX/UI
    struct UX {
        struct Measurements {
            static let imageWidth: CGFloat = 60
            static let imageHeight: CGFloat = 97
            static let checkboxDimensions: CGFloat = 24
        }

        struct Images {
            static let selected = ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.checkmarkFilled
            static let notSelected = ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.checkmarkEmpty
        }
    }

    private lazy var containerView: UIView = .build { _ in }

    private lazy var button: UIButton = .build { button in
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: self.viewModel.info.imageID)
//        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: 13)
        label.text = self.viewModel.info.title
//        label.accessibilityIdentifier = "\(self.viewModel.info.title)TitleLabel"
    }

    private lazy var checkboxView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: UX.Images.notSelected)
//        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

    // MARK: - Properties
    var viewModel: OnboardingMultipleChoiceButtonViewModel
    weak var buttonActionDelegate: OnboardingCardDelegate?
    weak var stateUpdateDelegate: OnboardingMultipleChoiceSelectionDelegate?

    // MARK: - View configuration
    init(
        frame: CGRect = .zero,
        viewModel: OnboardingMultipleChoiceButtonViewModel,
        buttonActionDelegate: OnboardingCardDelegate?,
        stateUpdateDelegate: OnboardingMultipleChoiceSelectionDelegate?
    ) {
        self.viewModel = viewModel
        self.buttonActionDelegate = buttonActionDelegate
        self.stateUpdateDelegate = stateUpdateDelegate
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addViews()

        NSLayoutConstraint.activate(
            [
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                imageView.widthAnchor.constraint(equalToConstant: UX.Measurements.imageWidth),
                imageView.heightAnchor.constraint(equalToConstant: UX.Measurements.imageHeight),

                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
                titleLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),

                checkboxView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                checkboxView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
                checkboxView.widthAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),
                checkboxView.heightAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),
                checkboxView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

                button.topAnchor.constraint(equalTo: containerView.topAnchor),
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

                containerView.topAnchor.constraint(equalTo: self.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            ]
        )
    }

    private func addViews() {
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(checkboxView)
        containerView.addSubview(button)
        addSubview(containerView)
    }

    func updateUIForState() {
        if viewModel.isSelected {
            applySelectedUI()
        } else {
            applyDeselectedUI()
        }
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
        buttonActionDelegate?.handleMultipleChoiceButtonActions(for: viewModel.info.action)
//        viewModel.isSelected.toggle()
//        updateStateTo(selected: viewModel.isSelected)
        stateUpdateDelegate?.updateSelectedButton(to: viewModel.info.title)
    }

    // MARK: - Theme
    public func applyTheme(theme: Theme) {
        backgroundColor = .clear
    }
}
