// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

enum AccessoryType {
    case standard, creditCard, address, login, passwordGenerator, relayEmailMask
}

final class AccessoryViewProvider: UIView, Themeable, InjectedThemeUUIDIdentifiable, FeatureFlaggable, Notifiable {
    // MARK: - Constants
    private struct UX {
        static let accessoryViewHeight: CGFloat = 56
        static let fixedSpacerWidth: CGFloat = if #available(iOS 26.0, *) { 8 } else { 10 }
        static let fixedSpacerHeight: CGFloat = 30
        static let fixedLeadingSpacerWidth: CGFloat = 2
        static let fixedTrailingSpacerWidth: CGFloat = 3
        static let bottomOffset: CGFloat = if #available(iOS 26.0, *) { 8 } else { 0 }
        static let spacerViewHeight: CGFloat = 4
        static let cornerRadius: CGFloat = 24.0
        static let buttonsWidth: CGFloat = 40
    }

    // MARK: - Properties
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    private var autofillAccessoryView: AutofillAccessoryViewButtonItem?
    let windowUUID: WindowUUID

    // Stub closures - these closures will be given as selectors in a future task
    var previousClosure: (() -> Void)?
    var nextClosure: (() -> Void)?
    var doneClosure: (() -> Void)?
    var savedCardsClosure: (() -> Void)?
    var savedAddressesClosure: (() -> Void)?
    var savedLoginsClosure: (() -> Void)?
    var useStrongPasswordClosure: (() -> Void)?
    var useRelayMaskClosure: (() -> Void)?

    private var searchBarPosition: SearchBarPosition {
        return featureFlags.getCustomState(for: .searchBarPosition) ?? .bottom
    }

    private var toolbarItems: [UIBarButtonItem] {
        guard #available(iOS 26.0, *) else {
            return [
                navigationButtonsBarItem,
                .flexibleSpace(),
                autofillAccessoryView,
                .flexibleSpace(),
                .fixedSpace(UX.fixedSpacerWidth),
                doneButton
            ].compactMap { $0 }
        }

        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        if isiPad {
            return [.flexibleSpace(), autofillAccessoryView].compactMap { $0 }
        } else if let autofillAccessoryView {
            return [navigationButtonsBarItem, autofillAccessoryView, doneButton]
        } else {
            return [navigationButtonsBarItem, .flexibleSpace(), doneButton]
        }
    }

    // MARK: - UI Elements
    private let toolbar: UIToolbar = .build()
    private let toolbarTopHeightSpacer: UIView = .build()

    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.tappedPreviousButton), for: .touchUpInside)
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronUp), for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.previousButton
        button.accessibilityLabel = .KeyboardAccessory.PreviousButtonA11yLabel
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.tappedNextButton), for: .touchUpInside)
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronDown), for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.nextButton
        button.accessibilityLabel = .KeyboardAccessory.NextButtonA11yLabel
        return button
    }()

    private lazy var navigationButtonsStackView: UIStackView = .build {
        $0.spacing = UX.fixedSpacerWidth
    }

    /// On iOS 26+, `UIBarButtonItem` has a fixed default padding between elements that cannot be reduced.
    /// To work around this limitation, we wrap the next and previous buttons in a `UIStackView` where
    /// we can control the spacing between them, then add the stack view as a single `UIBarButtonItem`.
    private lazy var navigationButtonsBarItem: UIBarButtonItem = {
        let barButton = UIBarButtonItem(customView: navigationButtonsStackView)
        return barButton
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.checkmark), for: .normal)
        button.addTarget(self, action: #selector(self.tappedDoneButton), for: .touchUpInside)
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        let barButton = UIBarButtonItem(customView: button)
        barButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.doneButton
        barButton.accessibilityLabel = .CreditCard.Settings.Done
        return barButton
    }()

    private let leadingFixedSpacer: UIView = .build()
    private let trailingFixedSpacer: UIView = .build()

    private lazy var creditCardAutofillView: AutofillAccessoryViewButtonItem = {
        let accessoryView = AutofillAccessoryViewButtonItem(
            image: UIImage(named: StandardImageIdentifiers.Large.creditCard),
            labelText: .CreditCard.Settings.UseSavedCardFromKeyboard,
            tappedAction: { [weak self] in
                self?.tappedCreditCardButton()
            })
        accessoryView.accessibilityTraits = .button
        accessoryView.accessibilityLabel = .CreditCard.Settings.UseSavedCardFromKeyboard
        accessoryView.accessibilityIdentifier =
            AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton
        accessoryView.isAccessibilityElement = true
        return accessoryView
    }()

    private lazy var addressAutofillView: AutofillAccessoryViewButtonItem = {
        let accessoryView = AutofillAccessoryViewButtonItem(
            image: UIImage(named: StandardImageIdentifiers.Large.location),
            labelText: .Addresses.Settings.UseSavedAddressFromKeyboard,
            tappedAction: { [weak self] in
                self?.tappedAddressCardButton()
            })
        accessoryView.accessibilityTraits = .button
        accessoryView.accessibilityLabel = .Addresses.Settings.UseSavedAddressFromKeyboard
        accessoryView.accessibilityIdentifier =
            AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
        accessoryView.isAccessibilityElement = true
        return accessoryView
    }()

    private lazy var loginAutofillView: AutofillAccessoryViewButtonItem = {
        let accessoryView = AutofillAccessoryViewButtonItem(
            image: UIImage(named: StandardImageIdentifiers.Large.login),
            labelText: .PasswordAutofill.UseSavedPasswordFromKeyboard,
            tappedAction: { [weak self] in
                self?.tappedLoginsButton()
            })
        accessoryView.accessibilityTraits = .button
        accessoryView.accessibilityLabel = .PasswordAutofill.UseSavedPasswordFromKeyboard
        accessoryView.accessibilityIdentifier = AccessibilityIdentifiers.Autofill.footerPrimaryAction
        accessoryView.isAccessibilityElement = true
        return accessoryView
    }()

    private lazy var passwordGeneratorView: AutofillAccessoryViewButtonItem = {
        let accessoryView = AutofillAccessoryViewButtonItem(
            image: UIImage(named: StandardImageIdentifiers.Large.login),
            labelText: .PasswordGenerator.KeyboardAccessoryButtonLabel,
            tappedAction: { [weak self] in
                self?.tappedUseStrongPasswordButton()
            })
        accessoryView.accessibilityTraits = .button
        accessoryView.accessibilityLabel = .PasswordGenerator.KeyboardAccessoryButtonLabel
        accessoryView.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.keyboardButton
        accessoryView.isAccessibilityElement = true
        return accessoryView
    }()

    private lazy var relayMaskView: AutofillAccessoryViewButtonItem = {
        let accessoryView = AutofillAccessoryViewButtonItem(
            image: UIImage(named: StandardImageIdentifiers.Large.emailMask),
            labelText: .RelayMask.UseRelayEmailMaskFromKeyboard,
            tappedAction: { [weak self] in
                self?.tappedUseRelayMaskButton()
            })
        accessoryView.accessibilityTraits = .button
        accessoryView.accessibilityLabel = .RelayMask.UseRelayEmailMaskFromKeyboard
        accessoryView.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.relayMaskAutofillButton
        accessoryView.isAccessibilityElement = true
        return accessoryView
    }()

    // MARK: - Initialization
    init(themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowUUID: WindowUUID,
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter

        super.init(frame: CGRect(width: UIScreen.main.bounds.width,
                                 height: UX.accessoryViewHeight))

        setupLayout()
        configureToolbarItems()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.SearchBarPositionDidChange]
        )
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func removeFromSuperview() {
        super.removeFromSuperview()
        // Reset showing of credit card when dismissing the view
        // This is required otherwise it will always show credit card view
        // even if the input isn't of type credit card
        autofillAccessoryView = nil
        configureToolbarItems()
    }

    // MARK: - Layout
    func reloadViewFor(_ accessoryType: AccessoryType) {
        switch accessoryType {
        case .standard:
            autofillAccessoryView = nil
        case .creditCard:
            autofillAccessoryView = creditCardAutofillView
            sendCreditCardAutofillPromptShownTelemetry()
        case .address:
            autofillAccessoryView = addressAutofillView
        case .login:
            autofillAccessoryView = loginAutofillView
        case .passwordGenerator:
            autofillAccessoryView = passwordGeneratorView
        case .relayEmailMask:
            autofillAccessoryView = relayMaskView
        }
        configureToolbarItems()
        layoutIfNeeded()
    }

    private func setupSpacer(_ spacer: UIView, width: CGFloat) {
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: width),
            spacer.heightAnchor.constraint(equalToConstant: UX.fixedSpacerHeight)
        ])
        spacer.accessibilityElementsHidden = true
    }

    private func setupHeightSpacer(_ spacer: UIView, height: CGFloat) {
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            spacer.heightAnchor.constraint(equalToConstant: height)
        ])
        spacer.accessibilityElementsHidden = true
    }

    private func setupLayout() {
        [previousButton, nextButton].forEach { navigationButtonsStackView.addArrangedSubview($0) }
        setupHeightSpacer(toolbarTopHeightSpacer, height: UX.spacerViewHeight)
        setupSpacer(leadingFixedSpacer, width: UX.fixedLeadingSpacerWidth)
        setupSpacer(trailingFixedSpacer, width: UX.fixedTrailingSpacerWidth)
        if #unavailable(iOS 26.0) { layer.cornerRadius = UX.cornerRadius }

        addSubviews(toolbarTopHeightSpacer, toolbar)
        if #available(iOS 26.0, *) {
            NSLayoutConstraint.activate([
                previousButton.widthAnchor.constraint(equalToConstant: UX.buttonsWidth),
                nextButton.widthAnchor.constraint(equalToConstant: UX.buttonsWidth)
            ])
        }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            heightAnchor.constraint(equalToConstant: UX.accessoryViewHeight),

            toolbarTopHeightSpacer.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopHeightSpacer.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.topAnchor.constraint(equalTo: toolbarTopHeightSpacer.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomOffset),
        ])
    }

    // MARK: - Private Methods
    private func configureToolbarItems() {
        toolbar.setItems(toolbarItems, animated: true)
    }

    // MARK: - ThemeApplicable
    func applyTheme() {
        let colors = themeManager.getCurrentTheme(for: windowUUID).colors
        // We want to use `.label` system color to make sure it blends well with the background when using glass effects.
        let barButtonsTintColor: UIColor = if #available(iOS 26.0, *) { .label } else { colors.iconAccentBlue }
        let buttonsBackgroundColor: UIColor = if #available(iOS 26.0, *) {
            .clear
        } else {
            colors.layer5Hover
        }

        backgroundColor = .clear
        doneButton.customView?.tintColor = if #available(iOS 26.0, *) { colors.actionPrimary } else { colors.iconAccentBlue }
        previousButton.tintColor = barButtonsTintColor
        nextButton.tintColor = barButtonsTintColor

        [creditCardAutofillView, addressAutofillView, loginAutofillView, passwordGeneratorView, relayMaskView].forEach {
            $0.accessoryImageViewTintColor = if #available(iOS 26.0, *) { .label } else { colors.iconPrimary }
            $0.backgroundColor = buttonsBackgroundColor
        }
    }

    // MARK: - Actions

    @objc
    private func tappedPreviousButton() {
        previousClosure?()
    }

    @objc
    private func tappedNextButton() {
        nextClosure?()
    }

    @objc
    private func tappedDoneButton() {
        doneClosure?()
    }

    @objc
    private func tappedCreditCardButton() {
        savedCardsClosure?()
    }

    @objc
    private func tappedAddressCardButton() {
        savedAddressesClosure?()
    }

    @objc
    private func tappedLoginsButton() {
        savedLoginsClosure?()
    }

    @objc
    private func tappedUseStrongPasswordButton() {
        useStrongPasswordClosure?()
    }

    @objc
    private func tappedUseRelayMaskButton() {
        useRelayMaskClosure?()
    }

    // MARK: - Telemetry
    fileprivate func sendCreditCardAutofillPromptShownTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .creditCardAutofillPromptShown)
    }

    // MARK: - Notifiable
    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == .SearchBarPositionDidChange else { return }
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }
}
