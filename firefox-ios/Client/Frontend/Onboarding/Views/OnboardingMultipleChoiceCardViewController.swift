// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

class OnboardingMultipleChoiceCardViewController: OnboardingCardViewController {
    struct UX {
        static let stackViewSpacingWithoutLink: CGFloat = 5
        static let stackViewSpacingButtons: CGFloat = 16
        static let topStackViewPaddingPad: CGFloat = 70
        static let topStackViewSpacingBetweenImageAndTitle: CGFloat = 15
        static let topStackViewSpacingBetweenDescriptionAndButtons: CGFloat = 20
        static let topStackViewPaddingPhone: CGFloat = 90
        static let choiceButtonStackViewSpacing: CGFloat = 26
        static let bottomStackViewPaddingPad: CGFloat = 32
        static let bottomStackViewPaddingPhone: CGFloat = 0
        static let horizontalTopStackViewPaddingPad: CGFloat = 100
        static let horizontalTopStackViewPaddingPhone: CGFloat = 24
        static let scrollViewVerticalPadding: CGFloat = 62

        static let smallTopStackViewPadding: CGFloat = 40

        static let baseImageHeight: CGFloat = 200
    }

    // MARK: - Properties
    weak var delegate: OnboardingCardDelegate?
    private var multipleChoiceButtons: [OnboardingMultipleChoiceButtonView]

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
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
                topPadding = UX.topStackViewPaddingPad
                horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPad
                bottomStackViewPadding = -UX.bottomStackViewPaddingPad
            } else {
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
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
                topStackView.spacing = SharedUX.smallStackViewSpacing
                topStackView.setCustomSpacing(UX.topStackViewSpacingBetweenDescriptionAndButtons,
                                              after: descriptionLabel)
                choiceButtonStackView.spacing = UX.stackViewSpacingWithoutLink
                bottomButtonStackView.spacing = SharedUX.smallStackViewSpacing
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
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

    /// Determines whether a given button is the selected button based on the toolbar layout, button properties,
    /// and the `version1` experiment.
    ///
    /// - Description: For the `version1` experiment, the bottom toolbar button is set as the default selected button.
    ///   For other layouts, the first button in the multiple choice buttons list is used as the default.
    private func isSelectedButton<T: OnboardingCardInfoModelProtocol>(
        buttonModel: OnboardingMultipleChoiceButtonModel,
        viewModel: T) -> Bool {
        let toolbarLayout = FxNimbus.shared.features
            .toolbarRefactorFeature
            .value()
            .layout

        switch toolbarLayout {
        case .version1:
            let isToolbarBottomAction = buttonModel.action == .toolbarBottom
            let isToolbarTopAction = buttonModel.action == .toolbarTop
            if isToolbarBottomAction {
                return true
            } else {
                return !isToolbarTopAction && buttonModel == viewModel.multipleChoiceButtons.first
            }
        default: return buttonModel == viewModel.multipleChoiceButtons.first
        }
    }

    private func buildButtonViews() {
        multipleChoiceButtons.removeAll()
        multipleChoiceButtons = viewModel.multipleChoiceButtons.map({ buttonModel in
            let isSelectedButton = isSelectedButton(buttonModel: buttonModel, viewModel: viewModel)
            return OnboardingMultipleChoiceButtonView(
                windowUUID: windowUUID,
                viewModel: OnboardingMultipleChoiceButtonViewModel(
                    isSelected: isSelectedButton,
                    info: buttonModel,
                    presentingCardName: viewModel.name,
                    a11yIDRoot: viewModel.a11yIdRoot
                ),
                buttonActionDelegate: delegate,
                stateUpdateDelegate: self
            )
        })
    }
    // MARK: - Button Actions
    @objc
    override func primaryAction() {
        delegate?.handleBottomButtonActions(
            for: viewModel.buttons.primary.action,
            from: viewModel.name,
            isPrimaryButton: true)
    }

    @objc
    override func secondaryAction() {
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

        primaryButton.applyTheme(theme: theme)
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
