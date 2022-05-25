// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol OnboardingCardProtocol {
    var cardType: IntroViewModel.OnboardingCards { get set }
    var image: UIImage? { get set }
    var title: String { get set }
    var description: String? { get set }
    var primaryAction: String { get set }
    var secondaryAction: String? { get set }
    var a11yIdRoot: String { get set }

    init(cardType: IntroViewModel.OnboardingCards,
         image: UIImage?,
         title: String,
         description: String?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String)
}

extension OnboardingCardProtocol {
    init(cardType: IntroViewModel.OnboardingCards,
         image: UIImage?,
         title: String,
         description: String?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String) {

        self.init(cardType: cardType,
                  image: image,
                  title: title,
                  description: description,
                  primaryAction: primaryAction,
                  secondaryAction: secondaryAction,
                  a11yIdRoot: a11yIdRoot)
    }
}

struct OnboardingCardViewModel: OnboardingCardProtocol {
    var cardType: IntroViewModel.OnboardingCards
    var image: UIImage?
    var title: String
    var description: String?
    var primaryAction: String
    var secondaryAction: String?
    var a11yIdRoot: String
}

class OnboardingCardView: UIView, CardTheme {
    var viewModel: OnboardingCardProtocol

    var nextClosure: (() -> Void)?
    var primaryActionClosure: (() -> Void)?

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
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
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
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)TitleLabel"
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
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionLabel"
    }

    private lazy var primaryButton: UIButton = .build { button in
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 13
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.LightGrey05, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)PrimaryButton"
    }

    private lazy var secondaryButton: UIButton = .build { button in
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 13
        button.backgroundColor = UIColor.Photon.LightGrey30
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.DarkGrey90, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.secondaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)SecondaryButton"
    }

    init(viewModel: OnboardingCardProtocol) {
        self.viewModel = viewModel

        super.init(frame: .zero)
        self.setupView()
        self.updateLayout(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentStackView.addArrangedSubview(imageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.setCustomSpacing(40, after: descriptionLabel)

        contentStackView.addArrangedSubview(primaryButton)
        contentStackView.addArrangedSubview(secondaryButton)

        addSubviews(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 24),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -24),

            primaryButton.heightAnchor.constraint(equalToConstant: 45),
            secondaryButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }

    func updateLayout(viewModel: OnboardingCardProtocol) {
        self.viewModel = viewModel
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description

        secondaryButton.isHidden = viewModel.secondaryAction?.isEmpty ?? true

        imageView.image = viewModel.image
        primaryButton.setTitle(viewModel.primaryAction, for: .normal)
        secondaryButton.setTitle(viewModel.secondaryAction, for: .normal)
    }

    @objc func primaryAction() {
        primaryActionClosure?()
    }

    @objc func secondaryAction() {
        nextClosure?()
    }
}
