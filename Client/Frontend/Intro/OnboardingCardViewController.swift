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
}

struct OnboardingCardViewModel: OnboardingCardProtocol {
    var cardType: IntroViewModel.OnboardingCards
    var image: UIImage?
    var title: String
    var description: String?
    var primaryAction: String
    var secondaryAction: String?
    var a11yIdRoot: String
    var welcomeCardBoldText: String = .Onboarding.IntroDescriptionPart1

    init(cardType: IntroViewModel.OnboardingCards,
         image: UIImage?,
         title: String,
         description: String?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String) {

        self.cardType = cardType
        self.image = image
        self.title = title
        self.description = description
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.a11yIdRoot = a11yIdRoot
    }
}

protocol OnboardingCardDelegate: AnyObject {
    func showNextPage(_ cardType: IntroViewModel.OnboardingCards)
    func primaryAction(_ cardType: IntroViewModel.OnboardingCards)
}

class OnboardingCardViewController: UIViewController, CardTheme {

    struct UX {
        static let stackViewSpacing: CGFloat = 16
        static let stackViewSpacingButtons: CGFloat = 102
        static let buttonHeight: CGFloat = 45
        static let stackViewHorizontalPadding: CGFloat = 20
    }

    var viewModel: OnboardingCardProtocol
    weak var delegate: OnboardingCardDelegate?

    var nextClosure: ((IntroViewModel.OnboardingCards) -> Void)?
    var primaryActionClosure: ((IntroViewModel.OnboardingCards) -> Void)?

    private var fxTextThemeColor: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var containerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.spacing = UX.stackViewSpacing
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

    // Onlu available for Welcome card and default cases
    private lazy var descriptionBoldLabel: UILabel = .build { label in
        label.textColor = UIColor.green
        label.numberOfLines = 0
        label.textColor = self.fxTextThemeColor
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .body,
            maxSize: 53)
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionBoldLabel"
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

    init(viewModel: OnboardingCardProtocol, delegate: OnboardingCardDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        updateLayout()
    }

    func setupView() {
        contentStackView.addArrangedSubview(imageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionBoldLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.setCustomSpacing(UX.stackViewSpacingButtons, after: descriptionLabel)
        contentStackView.addArrangedSubview(primaryButton)
        contentStackView.addArrangedSubview(secondaryButton)

        containerView.addSubviews(contentStackView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor, constant: 100),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackViewHorizontalPadding),
            contentStackView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor, constant: -100),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.stackViewHorizontalPadding),
            contentStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            primaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            secondaryButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
        ])

        contentStackView.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    func updateLayout() {
        titleLabel.text = viewModel.title
        descriptionBoldLabel.isHidden = viewModel.cardType != .welcome
        descriptionBoldLabel.text = .Onboarding.IntroDescriptionPart1
        descriptionLabel.isHidden = viewModel.description?.isEmpty ?? true
        descriptionLabel.text = viewModel.description
        secondaryButton.isHidden = viewModel.secondaryAction?.isEmpty ?? true

        imageView.image = viewModel.image
        imageView.isHidden = viewModel.image == nil
        primaryButton.setTitle(viewModel.primaryAction, for: .normal)
        secondaryButton.setTitle(viewModel.secondaryAction, for: .normal)
    }

    @objc func primaryAction() {
        delegate?.primaryAction(viewModel.cardType)
    }

    @objc func secondaryAction() {
        delegate?.showNextPage(viewModel.cardType)
    }
}
