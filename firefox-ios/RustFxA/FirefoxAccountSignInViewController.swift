// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Account
import Common
import ComponentLibrary

import enum MozillaAppServices.OAuthScope

/// Reflects parent page that launched FirefoxAccountSignInViewController
enum FxASignInParentType {
    case settings
    case appMenu
    case onboarding
    case upgrade
    case tabTray
    case library
}

/// ViewController handling Sign In through QR Code or Email address
class FirefoxAccountSignInViewController: UIViewController, Themeable {
    struct UX {
        static let horizontalPadding: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 8
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
    }

    // MARK: - Properties
    var shouldReload: (() -> Void)?

    private let profile: Profile
    private let windowUUID: WindowUUID
    private let deepLinkParams: FxALaunchParams
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var qrCodeNavigationHandler: QRCodeNavigationHandler?
    var currentWindowUUID: UUID? { windowUUID }

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

    private lazy var signinSyncQRImage = UIImage(named: StandardImageIdentifiers.Large.qrCode)

    private let qrSignInLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = .FxASignin_Subtitle
        label.font = FXFontStyles.Bold.headline.scaledFont()
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
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.adjustsFontForContentSizeCategory = true

        let placeholder = "firefox.com/pair"
        if let manager = RustFirefoxAccounts.shared.accountManager {
            manager.getPairingAuthorityURL { result in
                guard let url = try? result.get(), let host = url.host else { return }

                let font = FXFontStyles.Regular.headline.scaledFont()

                let shortUrl = host + url.path // "firefox.com" + "/pair"
                let msg: String = .FxASignin_QRInstructions.replaceFirstOccurrence(of: placeholder, with: shortUrl)
                label.attributedText = msg.attributedText(boldString: shortUrl, font: font)
            }
        }
    }

    private lazy var scanButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .FxASignin_QRScanSignin,
            a11yIdentifier: AccessibilityIdentifiers.Settings.FirefoxAccount.qrButton,
            imageTitlePadding: UX.buttonHorizontalInset
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.scanbuttonTapped), for: .touchUpInside)
    }

    private lazy var emailButton: SecondaryRoundedButton = .build { button in
        let viewModel = SecondaryRoundedButtonViewModel(
            title: .FxASignin_EmailSignin,
            a11yIdentifier: AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSignInButton
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.emailLoginTapped), for: .touchUpInside)
    }

    // MARK: - Inits

    /// - Parameters:
    ///   - profile: User Profile info
    ///   - parentType: FxASignInParentType is an enum parent page that presented this VC.
    ///                 Parameter used in telemetry button events.
    ///   - deepLinkParams: URL args passed in from deep link that propagate to FxA web view
    init(profile: Profile,
         parentType: FxASignInParentType,
         deepLinkParams: FxALaunchParams,
         windowUUID: WindowUUID,
         logger: Logger = DefaultLogger.shared,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.deepLinkParams = deepLinkParams
        self.profile = profile
        self.windowUUID = windowUUID
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
        case .library:
            self.telemetryObject = .libraryPanel
            self.fxaDismissStyle = .dismiss
        }
        self.logger = logger
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // swiftlint:disable line_length
        fatalError("Must init FirefoxAccountSignInVC with custom initializer including Profile and ParentType parameters")
        // swiftlint:enable line_length
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
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let colors = theme.colors
        view.backgroundColor = colors.layer1
        qrSignInLabel.textColor = colors.textPrimary
        instructionsLabel.textColor = colors.textPrimary

        scanButton.applyTheme(theme: theme)
        emailButton.applyTheme(theme: theme)

        scanButton.configuration?.image = signinSyncQRImage?.withRenderingMode(.alwaysTemplate)
    }

    // MARK: Button Tap Functions

    /// Scan QR code button tapped
    @objc
    func scanbuttonTapped(_ sender: UIButton) {
        qrCodeNavigationHandler?.showQRCode(delegate: self, rootNavigationController: navigationController)
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInScanQRCode)
    }

    /// Use email login button tapped
    @objc
    func emailLoginTapped(_ sender: UIButton) {
        let shouldAskForPermission = OnboardingNotificationCardHelper().shouldAskForNotificationsPermission(
            telemetryObj: telemetryObject
        )
        let fxaWebVC = FxAWebViewController(pageType: .emailLoginFlow,
                                            profile: profile,
                                            dismissalStyle: fxaDismissStyle,
                                            deepLinkParams: deepLinkParams,
                                            shouldAskForNotificationPermission: shouldAskForPermission)
        fxaWebVC.shouldDismissFxASignInViewController = { [weak self] in
            self?.shouldReload?()
            self?.dismissVC()
        }
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInUseEmail)
        navigationController?.pushViewController(fxaWebVC, animated: true)
    }

    private func showFxAWebViewController(_ url: URL, completion: @escaping (URL) -> Void) {
        if let accountManager = profile.rustFxA.accountManager {
            let entrypoint = self.deepLinkParams.entrypoint.rawValue
            accountManager.getManageAccountURL(entrypoint: "ios_settings_\(entrypoint)") { [weak self] result in
                guard let self = self else { return }
                accountManager.beginPairingAuthentication(
                    pairingUrl: url.absoluteString,
                    entrypoint: "pairing_\(entrypoint)",
                    // We ask for the session scope because the web content never
                    // got the session as the user never entered their email and
                    // password
                    scopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session]
                ) { [weak self] result in
                    guard self != nil else { return }

                    if case .success(let url) = result {
                        completion(url)
                    }
                }
            }
        }
    }
}

// MARK: - QRCodeViewControllerDelegate Functions
extension FirefoxAccountSignInViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        let shouldAskForPermission = OnboardingNotificationCardHelper().shouldAskForNotificationsPermission(
            telemetryObj: telemetryObject
        )

        // Only show the FxAWebViewController if the correct FxA pairing QR code was captured
        showFxAWebViewController(url) { [weak self] url in
            guard let self else { return }
            let vc = FxAWebViewController(
                pageType: .qrCode(url: url),
                profile: profile,
                dismissalStyle: fxaDismissStyle,
                deepLinkParams: deepLinkParams,
                shouldAskForNotificationPermission: shouldAskForPermission)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func didScanQRCodeWithText(_ text: String) {
        logger.log("FirefoxAccountSignInVC Error: `didScanQRCodeWithText` should not be called",
                   level: .info,
                   category: .sync)
    }

    var qrCodeScanningPermissionLevel: QRCodeScanPermissions {
        return .allowURLsWithoutPrompt
    }
}

// MARK: - FxA SignIn Flow
extension FirefoxAccountSignInViewController {
    /// This function is called to determine if FxA sign in flow or settings page should be shown
    /// - Parameters:
    ///     - deepLinkParams: FxALaunchParams from deeplink query
    ///     - flowType: FxAPageType is used to determine if email login, qr code login,
    ///                 or user settings page should be presented
    ///     - referringPage: ReferringPage enum is used to handle telemetry events correctly
    ///                      for the view event and the FxA sign in tap events, need to know
    ///                      which route we took to get to them
    ///     - profile:
    static func getSignInOrFxASettingsVC(
        _ deepLinkParams: FxALaunchParams,
        flowType: FxAPageType,
        referringPage: ReferringPage,
        profile: Profile,
        windowUUID: WindowUUID
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
            case .library:
                parentType = .library
                object = .libraryPanel
            }

            let signInVC = FirefoxAccountSignInViewController(
                profile: profile,
                parentType: parentType,
                deepLinkParams: deepLinkParams,
                windowUUID: windowUUID
            )
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: object)
            return signInVC
        }

        let settingsTableViewController = SyncContentSettingsViewController(windowUUID: windowUUID)
        settingsTableViewController.profile = profile
        return settingsTableViewController
    }
}
