// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

enum AccessoryType {
    case standard, creditCard, address, login, passwordGenerator
}

final class AccessoryViewProvider: UIView, Themeable, InjectedThemeUUIDIdentifiable, FeatureFlaggable, Notifiable {
    // MARK: - Constants
    private struct UX {
        static let accessoryViewHeight: CGFloat = 56
        static let fixedSpacerWidth: CGFloat = 10
        static let fixedSpacerHeight: CGFloat = 30
        static let fixedLeadingSpacerWidth: CGFloat = 2
        static let fixedTrailingSpacerWidth: CGFloat = 3
        static let leadingTrailingOffset: CGFloat = 12
        static let topOffset: CGFloat = 2
        static let bottomOffset: CGFloat = 8
        static let backgroundViewHeight: CGFloat = 44
        static let spacerViewHeight: CGFloat = 4
        static let cornerRadius: CGFloat = 24.0
        static let backgroundCornerRadius: CGFloat = 22
    }

    // MARK: - Properties
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    private var currentAccessoryView: AutofillAccessoryViewButtonItem?
    let windowUUID: WindowUUID

    // Stub closures - these closures will be given as selectors in a future task
    var previousClosure: (() -> Void)?
    var nextClosure: (() -> Void)?
    var doneClosure: (() -> Void)?
    var savedCardsClosure: (() -> Void)?
    var savedAddressesClosure: (() -> Void)?
    var savedLoginsClosure: (() -> Void)?
    var useStrongPasswordClosure: (() -> Void)?

    var hasAccessoryView: Bool {
        return currentAccessoryView != nil
    }
    private var searchBarPosition: SearchBarPosition {
        return featureFlags.getCustomState(for: .searchBarPosition) ?? .bottom
    }

    // MARK: - UI Elements
    private let toolbar: UIToolbar = .build()

    private let toolbarTopHeightSpacer: UIView = .build()

    private lazy var previousButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.tappedPreviousButton), for: .touchUpInside)
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronUp), for: .normal)
        let barButton = UIBarButtonItem(customView: button)
        if #available(iOS 26.0, *) { barButton.hidesSharedBackground = true }
        barButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.previousButton
        barButton.accessibilityLabel = .KeyboardAccessory.PreviousButtonA11yLabel
        return barButton
    }()

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.tappedNextButton), for: .touchUpInside)
        button.setImage(UIImage(named: StandardImageIdentifiers.Large.chevronDown), for: .normal)
        let barButton = UIBarButtonItem(customView: button)
        if #available(iOS 26.0, *) { barButton.hidesSharedBackground = true }
        barButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.nextButton
        barButton.accessibilityLabel = .KeyboardAccessory.NextButtonA11yLabel
        return barButton
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: StandardImageIdentifiers.Large.checkmark), for: .normal)
        } else {
            button.setTitle(.CreditCard.Settings.Done, for: .normal)
        }
        button.addTarget(self, action: #selector(self.tappedDoneButton), for: .touchUpInside)
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        let barButton = UIBarButtonItem(customView: button)
        if #available(iOS 26.0, *) { barButton.hidesSharedBackground = true }
        barButton.accessibilityIdentifier = AccessibilityIdentifiers.Browser.KeyboardAccessory.doneButton
        return barButton
    }()

    private lazy var fixedSpacer: UIBarButtonItem = {
        let fixedSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace,
                                          target: nil,
                                          action: nil)
        fixedSpacer.width = CGFloat(UX.fixedSpacerWidth)
        return fixedSpacer
    }()

    private let flexibleSpacer = UIBarButtonItem(systemItem: .flexibleSpace)
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
        if #available(iOS 26.0, *) { accessoryView.hidesSharedBackground = true }
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
        if #available(iOS 26.0, *) { accessoryView.hidesSharedBackground = true }
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
        if #available(iOS 26.0, *) { accessoryView.hidesSharedBackground = true }
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
        if #available(iOS 26.0, *) { accessoryView.hidesSharedBackground = true }
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

    override func layoutSubviews() {
        super.layoutSubviews()
        guard #available(iOS 26.0, *) else { return }
        backgroundView.layer.shadowPath = UIBezierPath(
            roundedRect: backgroundView.bounds,
            cornerRadius: UX.backgroundCornerRadius
        ).cgPath
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        // Reset showing of credit card when dismissing the view
        // This is required otherwise it will always show credit card view
        // even if the input isn't of type credit card
        currentAccessoryView = nil
        setupLayout()
    }

    // MARK: - Theme and Layout

    func reloadViewFor(_ accessoryType: AccessoryType) {
        switch accessoryType {
        case .standard:
            currentAccessoryView = nil
        case .creditCard:
            currentAccessoryView = creditCardAutofillView
            sendCreditCardAutofillPromptShownTelemetry()
        case .address:
            currentAccessoryView = addressAutofillView
        case .login:
            currentAccessoryView = loginAutofillView
        case .passwordGenerator:
            currentAccessoryView = passwordGeneratorView
        }

        setupLayout()
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

    private lazy var backgroundView: UIView = .build {
        $0.layer.cornerRadius = UX.backgroundCornerRadius
        $0.layer.shadowRadius = 10
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowOpacity = 1
    }

    private func setupLayout() {
        setupHeightSpacer(toolbarTopHeightSpacer, height: UX.spacerViewHeight)
        setupSpacer(leadingFixedSpacer, width: UX.fixedLeadingSpacerWidth)
        setupSpacer(trailingFixedSpacer, width: UX.fixedTrailingSpacerWidth)
        if #unavailable(iOS 26.0) { layer.cornerRadius = UX.cornerRadius }

        toolbar.items = [
            currentAccessoryView,
            flexibleSpacer,
            previousButton,
            fixedSpacer,
            nextButton,
            fixedSpacer,
            doneButton
        ].compactMap { $0 }

        toolbar.accessibilityElements = [
            currentAccessoryView?.customView,
            previousButton.customView,
            nextButton.customView,
            doneButton.customView
        ].compactMap { $0 }

        addSubview(toolbarTopHeightSpacer)
        if #available(iOS 26.0, *) {
            addSubview(backgroundView)
            backgroundView.addSubview(toolbar)

            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                        constant: UX.leadingTrailingOffset),
                backgroundView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                         constant: -UX.leadingTrailingOffset),
                backgroundView.topAnchor.constraint(lessThanOrEqualTo: topAnchor, constant: UX.topOffset),
                backgroundView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -UX.bottomOffset),
                backgroundView.heightAnchor.constraint(equalToConstant: UX.backgroundViewHeight),

                toolbar.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
            ])
        } else {
            addSubview(toolbar)
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
                toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            heightAnchor.constraint(equalToConstant: UX.accessoryViewHeight),

            toolbarTopHeightSpacer.topAnchor.constraint(equalTo: topAnchor),
            toolbarTopHeightSpacer.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.topAnchor.constraint(equalTo: toolbarTopHeightSpacer.bottomAnchor),
        ])
    }

    func applyTheme() {
        let colors = themeManager.getCurrentTheme(for: windowUUID).colors
        let buttonsBackgroundColor: UIColor = if #available(iOS 26.0, *) {
            .clear
        } else {
            colors.layer5Hover
        }

        if #available(iOS 26.0, *) { backgroundView.backgroundColor = colors.layerSurfaceMedium }

        self.backgroundColor = .clear
        if #available(iOS 26.0, *) { backgroundView.layer.shadowColor = colors.shadowStrong.cgColor }
        [previousButton, nextButton, doneButton].forEach {
            $0.tintColor = if #available(iOS 26.0, *) { colors.iconPrimary } else { colors.iconAccentBlue }
            $0.customView?.tintColor = if #available(iOS 26.0, *) { colors.iconPrimary } else { colors.iconAccentBlue }
        }

        [creditCardAutofillView, addressAutofillView, loginAutofillView, passwordGeneratorView].forEach {
            $0.accessoryImageViewTintColor = colors.iconPrimary
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
