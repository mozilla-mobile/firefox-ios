// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Redux

final class TermsOfUseViewController: UIViewController,
                                      Themeable,
                                      UITextViewDelegate,
                                      StoreSubscriber {
    private struct UX {
        static let cornerRadius: CGFloat = 20
        static let stackSpacing: CGFloat = 16
        static let stackSidePadding: CGFloat = 24
        static let sheetContainerSidePadding: CGFloat = 40
        static let logoSize: CGFloat = 40
        static let acceptButtonHeight: CGFloat = 44
        static let remindMeLaterButtonHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 12
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = 8
        static let iPadWidthMultiplier: CGFloat = 0.6
        static let textViewHeightMultiplier: CGFloat = 0.4
        static let panDismissDistance: CGFloat = 100
        static let panDismissVelocity: CGFloat = 800
        static let animationDuration: TimeInterval = 0.25
        static let springDamping: CGFloat = 0.8
        static let initialSpringVelocity: CGFloat = 1
        static let backgroundAlpha: CGFloat = 0.6

        static let titleFont = FXFontStyles.Bold.title3.scaledFont()
        static let descriptionFont = FXFontStyles.Regular.body.scaledFont()
        static let buttonFont = FXFontStyles.Bold.callout.scaledFont()
    }
    typealias SubscriberStateType = TermsOfUseState
    weak var coordinator: TermsOfUseCoordinatorDelegate?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    private let strings: TermsOfUseStrings
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private var activeContainerConstraints: [NSLayoutConstraint] = []
    private var textViewHeightConstraint: NSLayoutConstraint?
    private var grabberHeightConstraint: NSLayoutConstraint?
    private let isDragToDismissEnabled: Bool

    private var sheetContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var grabberView: UIView = .build { view in
        view.layer.cornerRadius = UX.grabberHeight / 2
    }

    private lazy var stackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.stackSpacing
        stack.alignment = .fill
    }

    private lazy var logoImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall)
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.logo
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = UX.titleFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.title
    }

    private lazy var descriptionTextView: UITextView = .build { [self] textView in
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.attributedText = self.makeAttributedDescription()
        textView.adjustsFontForContentSizeCategory = true
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.description
        textView.delegate = self
    }

    private lazy var acceptButton: UIButton = .build { button in
        button.setTitle(TermsOfUseStrings.acceptButtonTitle, for: .normal)
        button.titleLabel?.font = UX.buttonFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.acceptButton
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(self.acceptTapped), for: .touchUpInside)
    }

    private lazy var remindMeLaterButton: UIButton = .build { button in
        button.setTitle(TermsOfUseStrings.remindMeLaterButtonTitle, for: .normal)
        button.titleLabel?.font = UX.buttonFont
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfUse.remindMeLaterButton
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(self.remindMeLaterTapped), for: .touchUpInside)
    }

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: UUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         enableDragToDismiss: Bool = true,
         contentOption: TermsOfUseContentOption = .value0) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID
        self.isDragToDismissEnabled = enableDragToDismiss
        self.strings = TermsOfUseStrings(option: contentOption)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIAccessibility.post(notification: .announcement, argument:
                            TermsOfUseStrings.termsOfUseHasOpenedNotification)
        titleLabel.text = strings.titleText
        setupUI()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        subscribeToRedux()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: .termsShown))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .termsOfUse)
        store.dispatch(action)
        store.subscribe(self) {
            $0.select { appState in
                appState.screenState(TermsOfUseState.self, for: .termsOfUse, window: self.windowUUID)
                ?? TermsOfUseState(windowUUID: self.windowUUID)
            }
        }
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .termsOfUse)
        store.dispatch(action)
        // Note: actual `store.unsubscribe()` is not strictly needed; Redux uses weak subscribers
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupConstraints()
            view.layoutIfNeeded()
        }
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            configureTextViewScrolling()
            descriptionTextView.attributedText = makeAttributedDescription()
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    func newState(state: TermsOfUseState) {
        if state.hasAccepted || state.wasDismissed {
            coordinator?.dismissTermsFlow()
        }
    }

    private func setupUI() {
        view.addSubview(sheetContainer)
        sheetContainer.addSubview(grabberView)
        sheetContainer.addSubview(stackView)
        grabberView.isHidden = !isDragToDismissEnabled
        addStackSubviews()
        setupConstraints()
        configureTextViewScrolling()
        setupDismissGesture()
        if isDragToDismissEnabled {
            setupPanGesture()
        }
    }

    func addStackSubviews() {
        stackView.addArrangedSubview(self.logoImageView)
        stackView.addArrangedSubview(self.titleLabel)
        stackView.addArrangedSubview(self.descriptionTextView)
        stackView.addArrangedSubview(self.remindMeLaterButton)
        stackView.addArrangedSubview(self.acceptButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.deactivate(activeContainerConstraints)

        var containerConstraints = [
            sheetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        if traitCollection.horizontalSizeClass == .regular {
            containerConstraints.append(contentsOf: [
                sheetContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: UX.iPadWidthMultiplier),
                sheetContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                        constant: UX.sheetContainerSidePadding),
                sheetContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                         constant: -UX.sheetContainerSidePadding)
            ])
        } else {
            containerConstraints.append(contentsOf: [
                sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate(containerConstraints)
        activeContainerConstraints = containerConstraints

        let grabberHeight = grabberView.heightAnchor.constraint(equalToConstant:
                            isDragToDismissEnabled ? UX.grabberHeight : 0)
        grabberHeightConstraint = grabberHeight

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberHeight,

            stackView.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: UX.stackSidePadding),
            stackView.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -UX.stackSidePadding),
            stackView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: UX.stackSpacing),
            stackView.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor, constant: -UX.stackSidePadding)
        ])
    }

    private func makeAttributedDescription() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left

        let attributed = NSMutableAttributedString(
            string: strings.termsOfUseInfoText,
            attributes: [
                // UITextView.attributedText overrides adjustsFontForContentSizeCategory behavior
                // Unlike UILabel, we must explicitly set scaledFont() in the attributed string
                .font: FXFontStyles.Regular.body.scaledFont(),
                .foregroundColor: currentTheme().colors.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )

        for term in strings.linkTerms {
            if let url = strings.linkURL(for: term),
               let range = attributed.string.range(of: term) {
                let nsRange = NSRange(range, in: attributed.string)
                attributed.addAttribute(.link, value: url, range: nsRange)
            }
        }
        return attributed
    }

    private func setupDismissGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        sheetContainer.addGestureRecognizer(panGesture)
    }

    @objc private func backgroundTapped(_ sender: UITapGestureRecognizer) {
        // Only intercepts tap occurred outside the visible sheetContainer.
        // This prevents interacting with its content.
        guard !sheetContainer.frame.contains(sender.location(in: view)) else { return }
        // FXIOS-30197: Intentionally no longer dismissing when tapping the background scrim.
        // Add any other scrim interaction here
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed where translation.y > 0:
            sheetContainer.transform = CGAffineTransform(translationX: 0, y: translation.y)
        case .ended:
            if translation.y > UX.panDismissDistance || gesture.velocity(in: view).y > UX.panDismissVelocity {
                store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: .gestureDismiss))
                // In rare external-open flows the Redux subscriber can be delayed for gestures
                // due to window/state selection timing, so it should be dismissed directly
                coordinator?.dismissTermsFlow()
            } else {
                UIView.animate(withDuration: UX.animationDuration,
                               delay: 0,
                               usingSpringWithDamping: UX.springDamping,
                               initialSpringVelocity: UX.initialSpringVelocity,
                               options: .curveEaseOut) {
                    self.sheetContainer.transform = .identity
                }
            }
        default:
            break
        }
    }

    @objc private func acceptTapped() {
        store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: .termsAccepted))
        coordinator?.dismissTermsFlow()
    }

    @objc private func remindMeLaterTapped() {
        store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: .remindMeLaterTapped))
        coordinator?.dismissTermsFlow()
    }

    func applyTheme() {
        view.backgroundColor = currentTheme().colors.layerScrim.withAlphaComponent(UX.backgroundAlpha)
        sheetContainer.backgroundColor = currentTheme().colors.layer1
        grabberView.backgroundColor = currentTheme().colors.iconDisabled
        grabberView.isHidden = !isDragToDismissEnabled
        grabberView.alpha = isDragToDismissEnabled ? 1.0 : 0.0
        titleLabel.textColor = currentTheme().colors.textPrimary
        acceptButton.tintColor = currentTheme().colors.textOnDark
        acceptButton.backgroundColor = currentTheme().colors.actionPrimary
        remindMeLaterButton.backgroundColor = currentTheme().colors.actionSecondary
        remindMeLaterButton.setTitleColor(currentTheme().colors.textPrimary, for: .normal)
        descriptionTextView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        descriptionTextView.attributedText = makeAttributedDescription()
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private func configureTextViewScrolling() {
        if let existingConstraint = textViewHeightConstraint {
            existingConstraint.isActive = false
        }
        switch traitCollection.preferredContentSizeCategory {
        case .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            descriptionTextView.isScrollEnabled = true
            textViewHeightConstraint = descriptionTextView.heightAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.heightAnchor,
                multiplier: UX.textViewHeightMultiplier)
            textViewHeightConstraint?.isActive = true

        default:
            descriptionTextView.isScrollEnabled = false
        }
    }

    // MARK: TextView Delegate

    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        if let linkType = TermsOfUseLinkType.linkType(for: url) {
            store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: linkType.actionType))
        }
        coordinator?.showTermsLink(url: url)
        return false
    }
}
