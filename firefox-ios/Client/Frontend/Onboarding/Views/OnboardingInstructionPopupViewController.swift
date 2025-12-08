// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import OnboardingKit

class OnboardingInstructionPopupViewController: UIViewController,
                                                Themeable,
                                                Notifiable {
    private enum UX {
        static let contentStackViewSpacing: CGFloat = 20.0
        static let textStackViewSpacing: CGFloat = 24
        static let verticalPadding: CGFloat = 30
        static let horizontalPadding: CGFloat = 40
        static let descriptionTextViewParagraphSpacing: CGFloat = 40.0
    }

    // MARK: - Properties
    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.TitleLabel"
    }

    private lazy var descriptionLabel: UITextView = .build { label in
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.NumeratedLabels"
        label.isScrollEnabled = false
        label.isEditable = false
        label.isSelectable = false
    }

    private lazy var primaryButton: PrimaryRoundedGlassButton = .build { button in
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
    }

    var viewModel: any OnboardingDefaultBrowserModelProtocol<OnboardingInstructionsPopupActions>
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var didTapButton = false
    var buttonTappedFinishFlow: (() -> Void)?
    weak var dismissDelegate: BottomSheetDelegate?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: - Initializers
    init(viewModel: any OnboardingDefaultBrowserModelProtocol<OnboardingInstructionsPopupActions>,
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

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIApplication.didEnterBackgroundNotification,
                        UIContentSizeCategory.didChangeNotification]
        )

        setupView()
        updateLayout()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    func setupView() {
        addViewsToView()

        NSLayoutConstraint.activate(
            [
                // Content view wrapper around text
                contentContainerView.topAnchor.constraint(
                    equalTo: view.topAnchor,
                    constant: UX.verticalPadding
                ),
                contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                              constant: UX.horizontalPadding),
                contentContainerView.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: -50.0
                ),
                contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                               constant: -UX.horizontalPadding),

                titleLabel.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
                titleLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                      constant: UX.contentStackViewSpacing),
                descriptionLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
                descriptionLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

                primaryButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor,
                                                   constant: UX.contentStackViewSpacing),
                primaryButton.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
                primaryButton.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
                primaryButton.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
            ]
        )
    }

    private func updateLayout() {
        titleLabel.text = viewModel.title
        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: viewModel.buttonTitle,
            a11yIdentifier: "\(self.viewModel.a11yIdRoot).DefaultBrowserSettings.PrimaryButton"
        )

        configureDescriptionLabel(from: viewModel.instructionSteps)

        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        primaryButton.configure(viewModel: buttonViewModel)
        primaryButton.setContentHuggingPriority(.required, for: .vertical)
        primaryButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func addViewsToView() {
        contentContainerView.addSubviews(titleLabel, descriptionLabel, primaryButton)
        view.addSubview(contentContainerView)
    }

    // MARK: - Helper methods
    private func configureDescriptionLabel(from descriptionTexts: [String]) {
        let font = FXFontStyles.Regular.subheadline.scaledFont()
        let attributedParagraphs = getAttributedStrings(with: font)

        let combinedString = NSMutableAttributedString()

        let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = UX.descriptionTextViewParagraphSpacing
        paragraphStyle.alignment = isRTL ? .right : .left

        for (index, attributedText) in attributedParagraphs.enumerated() {
            let paragraphString = NSMutableAttributedString(attributedString: attributedText)
            paragraphString.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: NSRange(location: 0, length: paragraphString.length)
            )
            combinedString.append(paragraphString)

            if index < attributedParagraphs.count - 1 {
                // Add paragragh separator charachter
                combinedString.append(NSAttributedString(string: "\u{2029}"))
            }
        }

        descriptionLabel.attributedText = combinedString
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            ensureMainThread {
                if self.didTapButton {
                    self.dismiss(animated: false)
                    self.buttonTappedFinishFlow?()
                }
            }
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread { [self] in
                configureDescriptionLabel(from: viewModel.instructionSteps)
                applyTheme()
            }
        default:
            break
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
        descriptionLabel.textColor = theme.colors.textPrimary
        descriptionLabel.backgroundColor = .clear

        // Call applyTheme() on primaryButton to let it handle theme-specific styling
        primaryButton.applyTheme(theme: theme)
        view.backgroundColor = .clear
    }

    func getAttributedStrings(with font: UIFont) -> [NSAttributedString] {
        let markupUtility = MarkupAttributeUtility(baseFont: font)
        return viewModel.instructionSteps.map { markupUtility.addAttributesTo(text: $0) }
    }
}

extension OnboardingInstructionPopupViewController: BottomSheetChild {
    func willDismiss() { }
}
