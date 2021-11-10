/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Account

/// Reflects parent page that launched FirefoxAccountSignInViewController
enum FxASignInParentType {
    case settings
    case appMenu
    case onboarding
    case tabTray
}

/// ViewController handling Sign In through QR Code or Email address
class FirefoxAccountSignInViewController: UIViewController {
    
    // MARK: - Properties
    
    var shouldReload: (() -> Void)?
    
    private let profile: Profile
    private var deepLinkParams: FxALaunchParams?
    
    /// This variable is used to track parent page that launched this sign in VC.
    /// telemetryObject deduced from parentType initializer is sent with telemetry events on button click
    private let telemetryObject: TelemetryWrapper.EventObject
    
    /// Dismissal style for FxAWebViewController
    /// Changes based on whether or not this VC is launched from the app menu or settings
    private let fxaDismissStyle: DismissType
    
    // UI
    let qrSignInLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = .FxASignin_Subtitle
        label.font = DynamicFontHelper().LargeSizeHeavyFontAS
        label.textColor = .label
    }
    let pairImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: "qr-scan")
        imageView.contentMode = .scaleAspectFit
    }
    let instructionsLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = .label
        
        let placeholder = "firefox.com/pair"
        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { manager in
            manager.getPairingAuthorityURL { result in
                guard let url = try? result.get(), let host = url.host else { return }
                let shortUrl = host + url.path // "firefox.com" + "/pair"
                let msg: String = .FxASignin_QRInstructions.replaceFirstOccurrence(of: placeholder, with: shortUrl)
                label.attributedText = msg.attributedText(boldString: shortUrl, font: DynamicFontHelper().MediumSizeRegularWeightAS)
            }
        }
    }
    let scanButton: UIButton = .build { button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setImage(UIImage(named: "qr-code-icon-white")?.tinted(withColor: .white), for: .normal)
        button.setImage(UIImage(named: "qr-code-icon-white")?.tinted(withColor: .white), for: .highlighted)
        let imageWidth = button.imageView?.frame.width ?? 0.0
        button.setTitle(.FxASignin_QRScanSignin, for: .normal)
        button.accessibilityIdentifier = "QRCodeSignIn.button"
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(scanbuttonTapped), for: .touchUpInside)
    }
    let emailButton: UIButton = .build { button in
        button.backgroundColor = .white
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.layer.borderColor = UIColor.Photon.Grey30.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.setTitle(.FxASignin_EmailSignin, for: .normal)
        button.accessibilityIdentifier = "EmailSignIn.button"
        button.addTarget(self, action: #selector(emailLoginTapped), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
    }

    // MARK: - Inits
    
    /// - Parameters:
    ///   - profile: User Profile info
    ///   - parentType: FxASignInParentType is an enum parent page that presented this VC. Parameter used in telemetry button events.
    ///   - parameter: deepLinkParams: URL args passed in from deep link that propagate to FxA web view
    init(profile: Profile, parentType: FxASignInParentType, deepLinkParams: FxALaunchParams?) {
        self.deepLinkParams = deepLinkParams
        self.profile = profile
        switch parentType {
        case .appMenu:
            self.telemetryObject = .appMenu
            self.fxaDismissStyle = .dismiss
        case .onboarding:
            self.telemetryObject = .onboarding
            self.fxaDismissStyle = .dismiss
        case .settings:
            self.telemetryObject = .settings
            self.fxaDismissStyle = .popToRootVC
        case .tabTray:
            self.telemetryObject = .tabTray
            self.fxaDismissStyle = .popToTabTray

        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must init FirefoxAccountSignInVC with custom initializer including Profile and ParentType parameters")
    }
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = .FxASignin_Title
        accessibilityLabel = "FxASingin.navBar"
        
        setupLayout()
    }
    
    // MARK: - Helpers
    
    private func setupLayout() {
        view.addSubviews(qrSignInLabel, pairImageView, instructionsLabel, scanButton, emailButton)
        
        NSLayoutConstraint.activate([
            qrSignInLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            qrSignInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            pairImageView.topAnchor.constraint(equalTo: qrSignInLabel.bottomAnchor),
            pairImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pairImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            pairImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            instructionsLabel.topAnchor.constraint(equalTo: pairImageView.bottomAnchor),
            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionsLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            
            scanButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 30),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.widthAnchor.constraint(equalToConstant: 328),
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            
            emailButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 10),
            emailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailButton.widthAnchor.constraint(equalToConstant: 328),
            emailButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: Button Tap Functions
    
    /// Scan QR code button tapped
    @objc func scanbuttonTapped(_ sender: UIButton) {
        let qrCodeVC = QRCodeViewController()
        qrCodeVC.qrCodeDelegate = self
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: telemetryObject, extras: ["flow_type": "pairing"])
        presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: qrCodeVC, topTabsVisible: true)
    }
    
    /// Use email login button tapped
    @objc func emailLoginTapped(_ sender: UIButton) {
        let fxaWebVC = FxAWebViewController(pageType: .emailLoginFlow, profile: profile, dismissalStyle: fxaDismissStyle, deepLinkParams: deepLinkParams)
        fxaWebVC.shouldDismissFxASignInViewController = { [weak self] in
            self?.shouldReload?()
            self?.dismissVC()
        }
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .qrPairing, object: telemetryObject, extras: ["flow_type": "email"])
        navigationController?.pushViewController(fxaWebVC, animated: true)
    }
}

// MARK: QRCodeViewControllerDelegate Functions
extension FirefoxAccountSignInViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        let vc = FxAWebViewController(pageType: .qrCode(url: url.absoluteString), profile: profile, dismissalStyle: fxaDismissStyle, deepLinkParams: deepLinkParams)
        navigationController?.pushViewController(vc, animated: true)
    }

    func didScanQRCodeWithText(_ text: String) {
        Sentry.shared.send(message: "FirefoxAccountSignInVC Error: `didScanQRCodeWithText` should not be called")
    }
}

// MARK: - FxA SignIn Flow
extension FirefoxAccountSignInViewController {
    
    /// This function is called to determine if FxA sign in flow or settings page should be shown
    /// - Parameters:
    ///     - deepLinkParams: FxALaunchParams from deeplink query
    ///     - flowType: FxAPageType is used to determine if email login, qr code login, or user settings page should be presented
    ///     - referringPage: ReferringPage enum is used to handle telemetry events correctly for the view event and the FxA sign in tap events, need to know which route we took to get to them
    static func getSignInOrFxASettingsVC(_ deepLinkParams: FxALaunchParams? = nil, flowType: FxAPageType, referringPage: ReferringPage, profile: Profile) -> UIViewController {
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
