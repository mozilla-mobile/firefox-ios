// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary
import Shared

class OnboardingMultipleChoiceCardViewController: OnboardingCardViewController {
    struct UX {
        static let stackViewSpacingWithoutLink: CGFloat = 5
        static let stackViewSpacingButtons: CGFloat = 16
        static let topStackViewSpacing: CGFloat = 24
        static let topStackViewPaddingPad: CGFloat = 70
        static let topStackViewSpacingBetweenImageAndTitle: CGFloat = 10
        static let topStackViewSpacingBetweenDescriptionAndButtons: CGFloat = 20
        static let topStackViewPaddingPhone: CGFloat = 90
        static let choiceButtonStackViewSpacing: CGFloat = 26
        static let bottomStackViewPaddingPad: CGFloat = 32
        static let bottomStackViewPaddingPhone: CGFloat = 0
        static let horizontalTopStackViewPaddingPad: CGFloat = 100
        static let horizontalTopStackViewPaddingPhone: CGFloat = 24
        static let scrollViewVerticalPadding: CGFloat = 62
        static let titleFontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 28 : 22
        static let descriptionFontSize: CGFloat = 17

        // small device
        static let smallTitleFontSize: CGFloat = 20
        static let smallStackViewSpacing: CGFloat = 8
        static let smallScrollViewVerticalPadding: CGFloat = 20
        static let smallTopStackViewPadding: CGFloat = 40

        static let baseImageHeight: CGFloat = 200
    }

    // MARK: - Properties
    weak var delegate: OnboardingCardDelegate?
    private var multipleChoiceButtons: [OnboardingMultipleChoiceButtonView]

    // Adjusting layout for devices with height lower than 667
    // including now iPhone SE 2nd generation and iPad
    var shouldUseSmallDeviceLayout: Bool {
        return view.frame.height <= 667 || UIDevice.current.userInterfaceIdiom == .pad
    }

    // Adjusting layout for tiny devices (iPhone SE 1st generation)
    var shouldUseTinyDeviceLayout: Bool {
        return UIDevice().isTinyFormFactor
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var topStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.topStackViewSpacing
        stack.axis = .vertical
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.axis = .vertical
    }

    lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        let fontSize = self.shouldUseSmallDeviceLayout ? UX.smallTitleFontSize : UX.titleFontSize
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .largeTitle,
                                                                size: fontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)TitleLabel"
        label.accessibilityTraits.insert(.header)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.descriptionFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionLabel"
    }

    lazy var choiceButtonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .equalCentering
        stack.alignment = .center
        stack.axis = .horizontal
    }

    lazy var bottomButtonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .equalSpacing
        stack.axis = .vertical
    }

    private lazy var primaryButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
    }

    private lazy var secondaryButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.secondaryAction), for: .touchUpInside)
    }

    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-6816
    // This should not be calculated using scaling coefficients, but with some
    // version based on constrains of some kind. The ticket above ensures this work
    // should get addressed.
    private var imageViewHeight: CGFloat {
        return UX.baseImageHeight * scalingCoefficient()
    }

    private func scalingCoefficient() -> CGFloat {
        if shouldUseTinyDeviceLayout {
            return 1.0
        } else if shouldUseSmallDeviceLayout {
            return 0.85
        }

        return 1.0
    }

    // MARK: - Initializers
    init(
        viewModel: OnboardingCardInfoModelProtocol,
        delegate: OnboardingCardDelegate?,
        windowUUID: WindowUUID
    ) {
        self.delegate = delegate
        self.multipleChoiceButtons = []

        super.init(viewModel: viewModel, windowUUID: windowUUID)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        updateLayout()
        applyTheme()
        listenForThemeChange(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.pageChanged(from: viewModel.name)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.sendCardViewTelemetry(from: viewModel.name)
    }

    // MARK: - View setup
    func setupView() {
        view.backgroundColor = .clear
        contentStackView.spacing = UX.stackViewSpacingWithoutLink
        choiceButtonStackView.spacing = 0
        bottomButtonStackView.spacing = UX.stackViewSpacingWithoutLink
        addViewsToView()

        // Adapt layout for smaller screens
        var scrollViewVerticalPadding = UX.scrollViewVerticalPadding
        var topPadding = UX.topStackViewPaddingPhone
        var horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
        var bottomStackViewPadding = UX.bottomStackViewPaddingPhone

        if UIDevice.current.userInterfaceIdiom == .pad {
            topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenImageAndTitle,
                                          after: imageView)
            topStackView.spacing = UX.stackViewSpacingWithoutLink
            topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenDescriptionAndButtons,
                                          after: descriptionLabel)
            choiceButtonStackView.spacing = UX.stackViewSpacingWithoutLink
            bottomButtonStackView.spacing = UX.stackViewSpacingButtons
            if traitCollection.horizontalSizeClass == .regular {
                scrollViewVerticalPadding = UX.smallScrollViewVerticalPadding
                topPadding = UX.topStackViewPaddingPad
                horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPad
                bottomStackViewPadding = -UX.bottomStackViewPaddingPad
            } else {
                scrollViewVerticalPadding = UX.smallScrollViewVerticalPadding
                topPadding = UX.topStackViewPaddingPhone
                horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
                bottomStackViewPadding = -UX.bottomStackViewPaddingPhone
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
            bottomStackViewPadding = -UX.bottomStackViewPaddingPhone
            if shouldUseSmallDeviceLayout {
                topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenImageAndTitle,
                                              after: imageView)
                topStackView.spacing = UX.smallStackViewSpacing
                topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenDescriptionAndButtons,
                                              after: descriptionLabel)
                choiceButtonStackView.spacing = UX.stackViewSpacingWithoutLink
                bottomButtonStackView.spacing = UX.smallStackViewSpacing
                scrollViewVerticalPadding = UX.smallScrollViewVerticalPadding
                topPadding = UX.smallTopStackViewPadding
            } else {
                topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenImageAndTitle,
                                              after: imageView)
                topStackView.spacing = UX.stackViewSpacingWithoutLink
                topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenDescriptionAndButtons,
                                              after: descriptionLabel)
                choiceButtonStackView.spacing = UX.choiceButtonStackViewSpacing
                bottomButtonStackView.spacing = UX.stackViewSpacingButtons
                scrollViewVerticalPadding = UX.scrollViewVerticalPadding
                topPadding = view.frame.height * 0.1
            }
        }

        NSLayoutConstraint.activate(
            [
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),

                scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.frameLayoutGuide.topAnchor.constraint(
                    equalTo: view.topAnchor,
                    constant: scrollViewVerticalPadding
                ),
                scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.frameLayoutGuide.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: -scrollViewVerticalPadding
                ),
                scrollView.frameLayoutGuide.heightAnchor.constraint(
                    equalTo: containerView.heightAnchor
                ).priority(.defaultLow),

                scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
                scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

                // Content view wrapper around text
                contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
                contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                contentContainerView.bottomAnchor.constraint(
                    equalTo: containerView.bottomAnchor,
                    constant: bottomStackViewPadding
                ),
                contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

                contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor),
                contentStackView.leadingAnchor.constraint(
                    equalTo: contentContainerView.leadingAnchor,
                    constant: horizontalTopStackViewPadding
                ),
                contentStackView.bottomAnchor.constraint(
                    greaterThanOrEqualTo: contentContainerView.bottomAnchor,
                    constant: -10
                ),
                contentStackView.trailingAnchor.constraint(
                    equalTo: contentContainerView.trailingAnchor,
                    constant: -horizontalTopStackViewPadding
                ),
                contentStackView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),

                topStackView.topAnchor.constraint(equalTo: contentStackView.topAnchor),
                topStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                topStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

                bottomButtonStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                bottomButtonStackView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor),
                bottomButtonStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

                imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
            ]
        )
    }

    private func addViewsToView() {
        buildButtonViews()
        topStackView.addArrangedSubview(imageView)
        topStackView.addArrangedSubview(titleLabel)
        topStackView.addArrangedSubview(descriptionLabel)

        multipleChoiceButtons.forEach { buttonView in
            choiceButtonStackView.addArrangedSubview(buttonView)
        }
        topStackView.addArrangedSubview(choiceButtonStackView)
        contentStackView.addArrangedSubview(topStackView)

        bottomButtonStackView.addArrangedSubview(primaryButton)
        bottomButtonStackView.addArrangedSubview(secondaryButton)
        contentStackView.addArrangedSubview(bottomButtonStackView)

        contentContainerView.addSubview(contentStackView)
        containerView.addSubviews(contentContainerView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)
    }

    private func buildButtonViews() {
        multipleChoiceButtons.removeAll()
        multipleChoiceButtons = viewModel.multipleChoiceButtons.map({ buttonModel in
            return OnboardingMultipleChoiceButtonView(
                windowUUID: windowUUID,
                viewModel: OnboardingMultipleChoiceButtonViewModel(
                    isSelected: buttonModel == viewModel.multipleChoiceButtons.first,
                    info: buttonModel,
                    a11yIDRoot: viewModel.a11yIdRoot
                ),
                buttonActionDelegate: delegate,
                stateUpdateDelegate: self
            )
        })
    }

    private func currentTheme() -> Theme {
        return themeManager.currentTheme(for: windowUUID)
    }

    private func updateLayout() {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.body
        imageView.image = viewModel.image

        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: viewModel.buttons.primary.title,
            a11yIdentifier: "\(self.viewModel.a11yIdRoot)PrimaryButton"
        )
        primaryButton.configure(viewModel: buttonViewModel)
        primaryButton.applyTheme(theme: currentTheme())

        setupSecondaryButton()
    }

    private func setupSecondaryButton() {
        // To keep Title, Description aligned between cards we don't hide the button
        // we clear the background and make disabled
        guard let buttonTitle = viewModel.buttons.secondary?.title else {
            secondaryButton.isUserInteractionEnabled = false
            secondaryButton.backgroundColor = .clear
            return
        }

        let buttonViewModel = SecondaryRoundedButtonViewModel(
            title: buttonTitle,
            a11yIdentifier: "\(self.viewModel.a11yIdRoot)SecondaryButton"
        )
        secondaryButton.configure(viewModel: buttonViewModel)
        secondaryButton.applyTheme(theme: currentTheme())
    }

    // MARK: - Button Actions
    @objc
    func primaryAction() {
        delegate?.handleBottomButtonActions(
            for: viewModel.buttons.primary.action,
            from: viewModel.name,
            isPrimaryButton: true)
    }

    @objc
    func secondaryAction() {
        guard let buttonAction = viewModel.buttons.secondary?.action else { return }

        delegate?.handleBottomButtonActions(
            for: buttonAction,
            from: viewModel.name,
            isPrimaryButton: false)
    }

    // MARK: - Themeable
    override func applyTheme() {
        let theme = currentTheme()
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary

        setupSecondaryButton()

        multipleChoiceButtons.forEach { $0.applyTheme() }
    }
}

extension OnboardingMultipleChoiceCardViewController: OnboardingMultipleChoiceSelectionDelegate {
    func updateSelectedButton(to buttonName: String) {
        multipleChoiceButtons.forEach { button in
            button.viewModel.isSelected = button.viewModel.info.title == buttonName
            button.updateUIForState()
        }
    }
}
