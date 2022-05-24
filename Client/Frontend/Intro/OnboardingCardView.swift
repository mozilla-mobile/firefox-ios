// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct OnboardingCardViewModel {
    let image: UIImage?
    let title: String
    let description: String?
    let primaryAction: String
    let secondaryAction: String?
    let a11yRoot: String

    init() {
        image = UIImage(named: "tour-Welcome")
        title = "Really long title to check if it goes into multiple lines"
        description = "Same test as above but for Really long description to check if it goes into multiple lines and more important if the card height adjust "
        primaryAction = "Primary"
        secondaryAction = "Secondary"
        a11yRoot = "test"
    }
}

class OnboardingCardView: UIView, CardTheme {
    let viewModel: OnboardingCardViewModel

    private var fxTextThemeColor: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 16
        stack.axis = .vertical
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yRoot)ImageView"
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textColor = UIColor.red
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = self.fxTextThemeColor
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .title1,
            maxSize: 58)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yRoot)TitleLabel"
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.textColor = UIColor.green
        label.numberOfLines = 0
        label.textColor = self.fxTextThemeColor
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            maxSize: 53)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yRoot)DescriptionLabel"
    }

    private lazy var primaryButton: UIButton = .build { button in
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 13
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.LightGrey05, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.accessibilityIdentifier = "\(self.viewModel.a11yRoot)PrimaryButton"
    }

    private lazy var secondaryButton: UIButton = .build { button in
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 13
        button.backgroundColor = UIColor.Photon.LightGrey30
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.DarkGrey90, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.accessibilityIdentifier = "\(self.viewModel.a11yRoot)SecondaryButton"
    }

    init(viewModel: OnboardingCardViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)
        self.setupView()
        self.updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        contentStackView.addArrangedSubview(imageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.setCustomSpacing(40, after: descriptionLabel)

        contentStackView.addArrangedSubview(primaryButton)
        contentStackView.addArrangedSubview(secondaryButton)

        addSubviews(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leftAnchor.constraint(equalTo: leftAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.rightAnchor.constraint(equalTo: rightAnchor),

            primaryButton.heightAnchor.constraint(equalToConstant: 45),
            secondaryButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }

    func updateLayout() {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description

        secondaryButton.isHidden = viewModel.secondaryAction?.isEmpty ?? true

        imageView.image = viewModel.image
        primaryButton.setTitle(viewModel.primaryAction, for: .normal)
        secondaryButton.setTitle(viewModel.secondaryAction, for: .normal)
    }
}
