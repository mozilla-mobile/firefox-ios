// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

class OnboardingInstructionPopupViewController: UIViewController, Themeable {
    private enum UX {
        static let contentStackViewSpacing: CGFloat = 40
        static let textStackViewSpacing: CGFloat = 24

        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13

        static let cardShadowHeight: CGFloat = 14

        static let scrollViewVerticalPadding: CGFloat = 30
        static let topPaddingPhone: CGFloat = 30
        static let topPaddingPad: CGFloat = 60
        static let leadingPaddingPhone: CGFloat = 40
        static let leadingPaddingPad: CGFloat = 200
        static let trailingPaddingPhone: CGFloat = 40
        static let trailingPaddingPad: CGFloat = 200
        static let bottomPaddingPhone: CGFloat = 20
        static let bottomPaddingPad: CGFloat = 60
    }

    // MARK: - Properties
    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
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
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.TitleLabel"
    }

    private lazy var numeratedLabels = [UILabel]()

    private lazy var textStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.distribution = .fill
        stack.axis = .vertical
        stack.spacing = UX.textStackViewSpacing
    }

    private lazy var primaryButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
    }

    var viewModel: OnboardingDefaultBrowserModelProtocol
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var didTapButton = false
    var buttonTappedFinishFlow: (() -> Void)?
    var dismissDelegate: BottomSheetDismissProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: - Initializers
    init(viewModel: OnboardingDefaultBrowserModelProtocol,
         windowUUID: WindowUUID,
         buttonTappedFinishFlow: (() -> Void)?,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.buttonTappedFinishFlow = buttonTappedFinishFlow
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupNotifications()
        setupView()
        updateLayout()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func setupView() {
        addViewsToView()

        var topPadding = UX.topPaddingPhone
        var leadingPadding = UX.leadingPaddingPhone
        var trailingPadding = UX.trailingPaddingPhone
        var bottomPadding = UX.bottomPaddingPhone

        if UIDevice.current.userInterfaceIdiom == .pad {
            if traitCollection.horizontalSizeClass == .regular {
                topPadding = UX.topPaddingPad
                leadingPadding = UX.leadingPaddingPad
                trailingPadding = UX.leadingPaddingPad
                bottomPadding = UX.bottomPaddingPad
            } else {
                topPadding = UX.topPaddingPhone
                leadingPadding = UX.leadingPaddingPhone
                trailingPadding = UX.leadingPaddingPhone
                bottomPadding = UX.bottomPaddingPhone
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            topPadding = UX.topPaddingPhone
            leadingPadding = UX.leadingPaddingPhone
            trailingPadding = UX.leadingPaddingPhone
            bottomPadding = UX.bottomPaddingPhone
        }

        NSLayoutConstraint.activate(
            [
                // Content view wrapper around text
                contentContainerView.topAnchor.constraint(
                    equalTo: view.topAnchor,
                    constant: UX.scrollViewVerticalPadding
                ),
                contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentContainerView.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: -UX.scrollViewVerticalPadding
                ),
                contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                contentStackView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: topPadding),
                contentStackView.leadingAnchor.constraint(
                    equalTo: contentContainerView.leadingAnchor,
                    constant: leadingPadding
                ),
                contentStackView.trailingAnchor.constraint(
                    equalTo: contentContainerView.trailingAnchor,
                    constant: -trailingPadding
                ),
                contentStackView.bottomAnchor.constraint(
                    equalTo: contentContainerView.bottomAnchor,
                    constant: -bottomPadding
                ),
                textStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                primaryButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                primaryButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            ]
        )
    }

    private func setupNotifications() {
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    private func updateLayout() {
        titleLabel.text = viewModel.title
        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: viewModel.buttonTitle,
            a11yIdentifier: "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.PrimaryButton"
        )
        primaryButton.configure(viewModel: buttonViewModel)
    }
    private func addViewsToView() {
        createLabels(from: viewModel.instructionSteps)

        contentStackView.addArrangedSubview(titleLabel)
        numeratedLabels.forEach { textStackView.addArrangedSubview($0) }
        contentStackView.addArrangedSubview(textStackView)
        contentStackView.addArrangedSubview(primaryButton)

        contentContainerView.addSubview(contentStackView)
        view.addSubview(contentContainerView)

        view.backgroundColor = .white
    }

    // MARK: - Helper methods
    private func createLabels(from descriptionTexts: [String]) {
        numeratedLabels.removeAll()
        let attributedStrings = viewModel.getAttributedStrings(
            with: FXFontStyles.Regular.subheadline.scaledFont())
        attributedStrings.forEach { attributedText in
            let index = attributedStrings.firstIndex(of: attributedText)! as Int
            let label: UILabel = .build { label in
                label.textAlignment = .left
                label.font = FXFontStyles.Regular.subheadline.scaledFont()
                label.adjustsFontForContentSizeCategory = true
                label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.NumeratedLabel\(index)"
                label.attributedText = attributedText
                label.numberOfLines = 0
            }
            numeratedLabels.append(label)
        }
    }

    @objc
    func appDidEnterBackgroundNotification() {
        if didTapButton {
            dismiss(animated: false)
            buttonTappedFinishFlow?()
        }
    }

    // MARK: - Button actions
    @objc
    func primaryAction() {
        switch viewModel.buttonAction {
        case .openIosFxSettings:
            didTapButton = true
            DefaultApplicationHelper().openSettings()
        case .dismissAndNextCard:
            dismissDelegate?.dismissSheetViewController { self.buttonTappedFinishFlow?() }
        case .dismiss:
            dismissDelegate?.dismissSheetViewController(completion: nil)
        }
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        titleLabel.textColor = theme.colors.textPrimary
        numeratedLabels.forEach { $0.textColor = theme.colors.textPrimary }

        // Call applyTheme() on primaryButton to let it handle theme-specific styling
        primaryButton.applyTheme(theme: theme)

        view.backgroundColor = theme.colors.layer1
    }
}

extension OnboardingInstructionPopupViewController: BottomSheetChild {
    func willDismiss() { }
}
