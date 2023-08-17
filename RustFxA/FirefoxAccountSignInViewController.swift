// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Account
import Common
import ComponentLibrary

/// Reflects parent page that launched FirefoxAccountSignInViewController
enum FxASignInParentType {
    case settings
    case appMenu
    case onboarding
    case upgrade
    case tabTray
}

/// ViewController handling Sign In through QR Code or Email address
class FirefoxAccountSignInViewController: UIViewController, Themeable {
    struct UX {
        static let horizontalPadding: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 8
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonFontSize: CGFloat = 16
        static let signInLabelFontSize: CGFloat = 20
        static let descriptionFontSize: CGFloat = 17
    }

    // MARK: - Properties
    var shouldReload: (() -> Void)?

    private let profile: Profile
    private let deepLinkParams: FxALaunchParams
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    /// This variable is used to track parent page that launched this sign in VC.
    /// telemetryObject deduced from parentType initializer is sent with telemetry events on button click
    private let telemetryObject: TelemetryWrapper.EventObject

    /// Dismissal style for FxAWebViewController
    /// Changes based on whether or not this VC is launched from the app menu or settings
    private let fxaDismissStyle: DismissType
    private let logger: Logger

    // UI
    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var signinSyncQRImage = UIImage(named: ImageIdentifiers.signinSyncQRButton)

    private let qrSignInLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = .FxASignin_Subtitle
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .headline,
                                                                size: UX.signInLabelFontSize)
        label.adjustsFontForContentSizeCategory = true
    }

    private let pairImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.signinSync)
        imageView.contentMode = .scaleAspectFit
    }

    private let instructionsLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.signInLabelFontSize)
        label.adjustsFontForContentSizeCategory = true

        let placeholder = "firefox.com/pair"
        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { manager in
            manager.getPairingAuthorityURL { result in
                guard let url = try? result.get(), let host = url.host else { return }

                let font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                                  size: UX.signInLabelFontSize)
                let shortUrl = host + url.path // "firefox.com" + "/pair"
                let msg: String = .FxASignin_QRInstructions.replaceFirstOccurrence(of: placeholder, with: shortUrl)
                label.attributedText = msg.attributedText(boldString: shortUrl, font: font)
            }
        }
    }

    private lazy var scanButton: ResizableButton = .build { button in
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.setImage(self.signinSyncQRImage?.tinted(withColor: .white), for: .highlighted)
        button.setTitle(.FxASignin_QRScanSignin, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.FirefoxAccount.qrButton
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)

        let contentPadding = UIEdgeInsets(top: UX.buttonVerticalInset,
                                          left: UX.buttonHorizontalInset,
                                          bottom: UX.buttonVerticalInset,
                                          right: UX.buttonHorizontalInset)
        button.setInsets(forContentPadding: contentPadding, imageTitlePadding: UX.buttonHorizontalInset)
        button.addTarget(self, action: #selector(self.scanbuttonTapped), for: .touchUpInside)
    }

    private lazy var emailButton: ResizableButton = .build { button in
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.setTitle(.FxASignin_EmailSignin, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSignInButton
        button.addTarget(self, action: #selector(self.emailLoginTapped), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    // MARK: - Inits

    /// - Parameters:
    ///   - profile: User Profile info
    ///   - parentType: FxASignInParentType is an enum parent page that presented this VC. Parameter used in telemetry button events.
    ///   - deepLinkParams: URL args passed in from deep link that propagate to FxA web view
    init(profile: Profile,
         parentType: FxASignInParentType,
         deepLinkParams: FxALaunchParams,
         logger: Logger = DefaultLogger.shared,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.deepLinkParams = deepLinkParams
        self.profile = profile
        switch parentType {
        case .appMenu:
            self.telemetryObject = .appMenu
            self.fxaDismissStyle = .dismiss
        case .onboarding:
            self.telemetryObject = .onboarding
            self.fxaDismissStyle = .dismiss
        case .upgrade:
            self.telemetryObject = .upgradeOnboarding
            self.fxaDismissStyle = .dismiss
        case .settings:
            self.telemetryObject = .settings
            self.fxaDismissStyle = .popToRootVC
        case .tabTray:
            self.telemetryObject = .tabTray
            self.fxaDismissStyle = .popToTabTray
        }
        self.logger = logger
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Must init FirefoxAccountSignInVC with custom initializer including Profile and ParentType parameters")
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        title = .Settings.Sync.SignInView.Title
        accessibilityLabel = "FxASingin.navBar"

        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    // MARK: - Helpers

    private func setupLayout() {
        containerView.addSubviews(qrSignInLabel, pairImageView, instructionsLabel, scanButton, emailButton)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            qrSignInLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            qrSignInLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                   constant: UX.horizontalPadding),
            qrSignInLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                    constant: -UX.horizontalPadding),

            pairImageView.topAnchor.constraint(equalTo: qrSignInLabel.bottomAnchor,
                                               constant: UX.horizontalPadding),
            pairImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            instructionsLabel.topAnchor.constraint(equalTo: pairImageView.bottomAnchor,
                                                   constant: UX.horizontalPadding),
            instructionsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                       constant: UX.horizontalPadding),
            instructionsLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                        constant: -UX.horizontalPadding),

            scanButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 24),
            scanButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            scanButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),

            emailButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 8),
            emailButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                 constant: UX.horizontalPadding),
            emailButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                  constant: -UX.horizontalPadding),
            emailButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
        ])
    }

    func applyTheme() {
        let colors = themeManager.currentTheme.colors
        view.backgroundColor = colors.layer1
        qrSignInLabel.textColor = colors.textPrimary
        instructionsLabel.textColor = colors.textPrimary
        scanButton.backgroundColor = colors.actionPrimary
        scanButton.setTitleColor(colors.textInverted, for: .normal)
        scanButton.setImage(signinSyncQRImage?
            .tinted(withColor: colors.textInverted), for: .normal)
        emailButton.backgroundColor = colors.actionSecondary
        emailButton.setTitleColor(colors.textSecondaryAction, for: .normal)
    }

    // MARK: Button Tap Functions

    /// Scan QR code button tapped
    @objc
    func scanbuttonTapped(_ sender: UIButton) {
        let qrCodeVC = QRCodeViewController()
        qrCodeVC.qrCodeDelegate = self
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInScanQRCode)
        presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: qrCodeVC, topTabsVisible: true)
    }

    /// Use email login button tapped
    @objc
    func emailLoginTapped(_ sender: UIButton) {
        let askForPermission = OnboardingNotificationCardHelper().askForPermissionDuringSync(
            isOnboarding: telemetryObject == .onboarding)

        let fxaWebVC = FxAWebViewController(pageType: .emailLoginFlow,
                                            profile: profile,
                                            dismissalStyle: fxaDismissStyle,
                                            deepLinkParams: deepLinkParams,
                                            shouldAskForNotificationPermission: askForPermission)
        fxaWebVC.shouldDismissFxASignInViewController = { [weak self] in
            self?.shouldReload?()
            self?.dismissVC()
        }
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInUseEmail)
        navigationController?.pushViewController(fxaWebVC, animated: true)
    }
}

// MARK: QRCodeViewControllerDelegate Functions
extension FirefoxAccountSignInViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        let askForPermission = OnboardingNotificationCardHelper().askForPermissionDuringSync(
            isOnboarding: telemetryObject == .onboarding)

        let vc = FxAWebViewController(pageType: .qrCode(url: url.absoluteString),
                                      profile: profile,
                                      dismissalStyle: fxaDismissStyle,
                                      deepLinkParams: deepLinkParams,
                                      shouldAskForNotificationPermission: askForPermission)
        navigationController?.pushViewController(vc, animated: true)
    }

    func didScanQRCodeWithText(_ text: String) {
        logger.log("FirefoxAccountSignInVC Error: `didScanQRCodeWithText` should not be called",
                   level: .info,
                   category: .sync)
    }
}

// MARK: - FxA SignIn Flow
extension FirefoxAccountSignInViewController {
    /// This function is called to determine if FxA sign in flow or settings page should be shown
    /// - Parameters:
    ///     - deepLinkParams: FxALaunchParams from deeplink query
    ///     - flowType: FxAPageType is used to determine if email login, qr code login, or user settings page should be presented
    ///     - referringPage: ReferringPage enum is used to handle telemetry events correctly for the view event and the FxA sign in tap events, need to know which route we took to get to them
    ///     - profile:
    static func getSignInOrFxASettingsVC(
        _ deepLinkParams: FxALaunchParams,
        flowType: FxAPageType,
        referringPage: ReferringPage,
        profile: Profile
    ) -> UIViewController {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let parentType: FxASignInParentType
        let object: TelemetryWrapper.EventObject
        guard profile.hasSyncableAccount() else {
            switch referringPage {
            case .appMenu, .none:
                parentType = .appMenu
                object = .appMenu
            case .onboarding:
                parentType = .onboarding
                object = .onboarding
            case .settings:
                parentType = .settings
                object = .settings
            case .tabTray:
                parentType = .tabTray
                object = .tabTray
            }

            let signInVC = FirefoxAccountSignInViewController(profile: profile, parentType: parentType, deepLinkParams: deepLinkParams)
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: object)
            return signInVC
        }

        let settingsTableViewController = SyncContentSettingsViewController()
        settingsTableViewController.profile = profile
        return settingsTableViewController
    }
}
