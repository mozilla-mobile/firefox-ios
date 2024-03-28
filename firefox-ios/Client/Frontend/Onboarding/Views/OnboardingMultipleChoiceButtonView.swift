// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class OnboardingMultipleChoiceButtonView: UIView, ThemeApplicable {
    // MARK: - UX/UI
    struct UX {
        struct Measurements {
            static let padding: CGFloat = 8
            static let imageWidth: CGFloat = 60
            static let imageHeight: CGFloat = 97
            static let checkboxDimensions: CGFloat = 24
        }

        struct Images {
            static let selected = "test"
            static let notSelected = "test"
        }
    }

    private lazy var containerView: UIView = .build { _ in }

    lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: self.viewModel.info.imageID)
//        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

//    private var descriptionLabel: UILabel = .build { label in
//        label.numberOfLines = 0
//        label.textAlignment = .center
//        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
//                                                            size: UX.descriptionFontSize)
//        label.adjustsFontForContentSizeCategory = true
////        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionLabel"
//    }

    lazy var checkboxView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.checkmarkEmpty)
//        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

    lazy var stackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.axis = .vertical
    }

    // MARK: - Properties
    private var viewModel: OnboardingMultipleChoiceButtonViewModel

    // MARK: - View configuration
    init(
        frame: CGRect = .zero,
        viewModel: OnboardingMultipleChoiceButtonViewModel
    ) {
        self.viewModel = viewModel
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addViews()

        stackView.spacing = 4

        NSLayoutConstraint.activate(
            [
                imageView.widthAnchor.constraint(equalToConstant: UX.Measurements.imageWidth),
                imageView.heightAnchor.constraint(equalToConstant: UX.Measurements.imageHeight),

                checkboxView.widthAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),
                checkboxView.heightAnchor.constraint(equalToConstant: UX.Measurements.checkboxDimensions),

                stackView.topAnchor.constraint(equalTo: self.topAnchor),
                stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
                stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                stackView.rightAnchor.constraint(equalTo: self.rightAnchor),
            ]
        )
    }

    private func addViews() {
        stackView.addArrangedSubview(imageView)
//        stackView.addArrangedSubview(descriptionLabel)
//        stackView.addArrangedSubview(checkboxView)
        containerView.addSubview(stackView)
        addSubview(containerView)
    }

    func updateButtonState() {
    }

    // MARK: - Actions
    @objc
    func selected() {
    }

    // MARK: - Theme
    public func applyTheme(theme: Theme) {}
}
