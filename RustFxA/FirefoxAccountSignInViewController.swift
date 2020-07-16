/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared
import Account

/// Reflects parent page that launched FirefoxAccountSignInViewController
enum FxASignInParentType {
    case settings
    case appMenu
    case onboarding
}

/// ViewController handling Sign In through QR Code or Email address
class FirefoxAccountSignInViewController: UIViewController {
    
    // MARK: Class Variable Definitions
    
    lazy var qrSignInLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = Strings.FxASignin_Subtitle
        label.font = DynamicFontHelper().LargeSizeHeavyFontAS
        return label
    }()
    
    lazy var pairImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "qr-scan")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        let placeholder = "firefox.com/pair"

        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { manager in
            manager.getPairingAuthorityURL { result in
                guard let url = try? result.get(), let host = url.host else { return }
                let shortUrl = host + url.path // "firefox.com" + "/pair"
                let msg = Strings.FxASignin_QRInstructions.replaceFirstOccurrence(of: placeholder, with: shortUrl)
                label.attributedText = msg.attributedText(boldString: shortUrl, font: DynamicFontHelper().MediumSizeRegularWeightAS)
            }
        }

        return label
    }()
    
    lazy var scanButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setImage(UIImage(named: "qr-code-icon-white"), for: .normal)
        button.setImage(UIImage(named: "qr-code-icon-white"), for: .highlighted)
        let imageWidth = button.imageView?.frame.width ?? 0.0
        button.setTitle(Strings.FxASignin_QRScanSignin, for: .normal)
        button.accessibilityIdentifier = "QRCodeSignIn.button"
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(scanbuttonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var emailButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.layer.borderColor = UIColor.Photon.Grey30.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.setTitle(Strings.FxASignin_EmailSignin, for: .normal)
        button.accessibilityIdentifier = "EmailSignIn.button"
        button.addTarget(self, action: #selector(emailLoginTapped), for: .touchUpInside)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        return button
    }()
            
    private let profile: Profile
    
    /// This variable is used to track parent page that launched this sign in VC.
    /// telemetryObject deduced from parentType initializer is sent with telemetry events on button click
    private let telemetryObject: TelemetryWrapper.EventObject
    
    /// Dismissal style for FxAWebViewController
    /// Changes based on whether or not this VC is launched from the app menu or settings
    private let fxaDismissStyle: DismissType

    private var deepLinkParams: FxALaunchParams?

    // MARK: Init() and viewDidLoad()
    
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
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must init FirefoxAccountSignInVC with custom initializer including Profile and ParentType parameters")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = Strings.FxASignin_Title
        accessibilityLabel = "FxASingin.navBar"
        addSubviews()
        addViewConstraints()
        handleDarkMode()
    }
    
    // MARK: Subview Layout Functions
    
    func addSubviews() {
        view.addSubview(qrSignInLabel)
        view.addSubview(pairImageView)
        view.addSubview(instructionsLabel)
        view.addSubview(scanButton)
        view.addSubview(emailButton)
    }
    
    func addViewConstraints() {
        qrSignInLabel.snp.makeConstraints { make in
            make.top.equalTo(view.snp_topMargin).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        pairImageView.snp.makeConstraints { make in
            make.top.equalTo(qrSignInLabel.snp_bottomMargin)
            make.height.equalToSuperview().multipliedBy(0.3)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        instructionsLabel.snp.makeConstraints { make in
            make.top.equalTo(pairImageView.snp_bottomMargin)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        scanButton.snp.makeConstraints { make in
            make.top.equalTo(instructionsLabel.snp_bottomMargin).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(327)
            make.height.equalTo(44)
        }
        emailButton.snp.makeConstraints { make in
            make.top.equalTo(scanButton.snp_bottomMargin).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(327)
            make.height.equalTo(44)
        }
    }
    
    func handleDarkMode() {
        [qrSignInLabel, instructionsLabel].forEach {
            // UI is not currently themeable, enforce black
            $0.textColor = .black
        }
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
