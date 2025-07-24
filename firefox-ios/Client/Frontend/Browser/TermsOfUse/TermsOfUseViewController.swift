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
        static let acceptButtonCornerRadius: CGFloat = 12
        static let remindMeLaterButtonHeight: CGFloat = 30
        static let grabberWidth: CGFloat = 36
        static let grabberHeight: CGFloat = 5
        static let grabberTopPadding: CGFloat = 8
        static let iPadWidthMultiplier: CGFloat = 0.6
        static let panDismissDistance: CGFloat = 100
        static let panDismissVelocity: CGFloat = 800
        static let animationDuration: TimeInterval = 0.25
        static let springDamping: CGFloat = 0.8
        static let initialSpringVelocity: CGFloat = 1
        static let backgroundAlpha: CGFloat = 0.6

        static let titleFont = FXFontStyles.Regular.headline.scaledFont()
        static let descriptionFont = FXFontStyles.Regular.body.scaledFont()
        static let acceptButtonFont = FXFontStyles.Regular.callout.scaledFont()
        static let remindMeLaterFont = FXFontStyles.Regular.body.scaledFont()
    }
    typealias SubscriberStateType = TermsOfUseState

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private let strings = TermsOfUseStrings()
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    private var activeContainerConstraints: [NSLayoutConstraint] = []

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
        imageView.widthAnchor.constraint(equalToConstant: UX.logoSize).isActive = true
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = TermsOfUseStrings.titleText
        label.font = UX.titleFont
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    private lazy var descriptionTextView: UITextView = .build { [self] textView in
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.attributedText = self.makeAttributedDescription()
        textView.linkTextAttributes = [
            .foregroundColor: currentTheme().colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.delegate = self
    }

    private lazy var acceptButton: UIButton = .build { button in
        button.setTitle(TermsOfUseStrings.acceptButtonTitle, for: .normal)
        button.titleLabel?.font = UX.acceptButtonFont
        button.layer.cornerRadius = UX.acceptButtonCornerRadius
        button.heightAnchor.constraint(equalToConstant: UX.acceptButtonHeight).isActive = true
        button.addTarget(self, action: #selector(self.acceptTapped), for: .touchUpInside)
    }

    private lazy var remindMeLaterButton: UIButton = .build { button in
        button.setTitle(TermsOfUseStrings.remindMeLaterButtonTitle, for: .normal)
        button.titleLabel?.font = UX.remindMeLaterFont
        button.heightAnchor.constraint(equalToConstant: UX.remindMeLaterButtonHeight).isActive = true
        button.addTarget(self, action: #selector(self.remindMeLaterTapped), for: .touchUpInside)
    }

    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: UUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIAccessibility.post(notification: .announcement, argument: "Terms of Use sheet opened")
        setupUI()
        listenForThemeChange(view)
        applyTheme()
        subscribeToRedux()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(TermsOfUseAction(windowUUID: windowUUID, actionType: .markShownThisLaunch))
    }

    deinit {
        unsubscribeFromRedux()
    }

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .termsOfUse)
        store.dispatchLegacy(action)
        store.subscribe(self) {
            $0.select { appState in
                appState.screenState(TermsOfUseState.self, for: .termsOfUse, window: self.windowUUID)
                ?? TermsOfUseState(windowUUID: self.windowUUID)
            }
        }
    }

    func unsubscribeFromRedux() {
            let action = ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.closeScreen,
                screen: .termsOfUse
            )
            store.dispatch(action)
            store.unsubscribe(self)
        }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupConstraints()
            view.layoutIfNeeded()
        }
    }

    func newState(state: TermsOfUseState) {
        if state.hasAccepted {
            dismiss(animated: true)
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(UX.backgroundAlpha)
        view.addSubview(sheetContainer)
        sheetContainer.addSubview(grabberView)
        sheetContainer.addSubview(stackView)
        addStackSubviews()
        setupConstraints()
        setupDismissGesture()
        setupPanGesture()
    }

    func addStackSubviews() {
        stackView.addArrangedSubview(self.logoImageView)
        stackView.addArrangedSubview(self.titleLabel)
        stackView.addArrangedSubview(self.descriptionTextView)
        stackView.addArrangedSubview(self.acceptButton)
        stackView.addArrangedSubview(self.remindMeLaterButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.deactivate(activeContainerConstraints)

        var containerConstraints = [
            sheetContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sheetContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        if traitCollection.horizontalSizeClass == .regular {
            containerConstraints.append(contentsOf: [
                sheetContainer.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * UX.iPadWidthMultiplier),
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

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: UX.grabberTopPadding),
            grabberView.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: UX.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: UX.grabberHeight),

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
            string: TermsOfUseStrings.termsOfUseInfoText,
            attributes: [
                .font: UX.descriptionFont,
                .foregroundColor: currentTheme().colors.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )

        for term in TermsOfUseStrings.linkTerms {
            if let url = TermsOfUseStrings.linkURL(for: term),
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
        if !sheetContainer.frame.contains(sender.location(in: view)) {
            dismiss(animated: true)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed where translation.y > 0:
            sheetContainer.transform = CGAffineTransform(translationX: 0, y: translation.y)
        case .ended:
            if translation.y > UX.panDismissDistance || gesture.velocity(in: view).y > UX.panDismissVelocity {
                dismiss(animated: true)
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
        store.dispatchLegacy(TermsOfUseAction(windowUUID: windowUUID, actionType: .markAccepted))
        dismiss(animated: true)
    }

    @objc private func remindMeLaterTapped() {
        store.dispatchLegacy(TermsOfUseAction(windowUUID: windowUUID, actionType: .markDismissed))
        dismiss(animated: true)
    }

    func applyTheme() {
        sheetContainer.backgroundColor = currentTheme().colors.layer1
        grabberView.backgroundColor = currentTheme().colors.iconDisabled
        titleLabel.textColor = currentTheme().colors.textPrimary
        acceptButton.tintColor = currentTheme().colors.textOnDark
        acceptButton.backgroundColor = currentTheme().colors.actionPrimary
        remindMeLaterButton.setTitleColor(currentTheme().colors.actionPrimary, for: .normal)
    }

    private func currentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    // MARK: TextView Delegate

    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        let linkVC = TermsOfUseLinkViewController(url: url, windowUUID: windowUUID)
        present(linkVC, animated: true)
        return false
    }
}
