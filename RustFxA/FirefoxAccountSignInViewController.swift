//
//  FirefoxAccountSignInVC.swift
//  Client
//
//  Created by Kayla Galway on 5/19/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import SnapKit
import Shared

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
        label.text = Strings.FxASignin_QRInstructions
        return label
    }()
    
    lazy var scanButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setTitle(Strings.FxASignin_QRScanSignin, for: .normal)
        button.addTarget(self, action: #selector(scanbuttonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var emailButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0.5
        button.layer.cornerRadius = 8
        button.setTitle(Strings.FxASignin_EmailSignin, for: .normal)
        button.addTarget(self, action: #selector(emailLoginTapped), for: .touchUpInside)
        return button
    }()
        
    private let profile: Profile
    
    /// This variable is used to track parent page that launched this sign in VC.
    /// telemetryObject deduced from parentType initializer is sent with telemetry events on button click
    private let telemetryObject: UnifiedTelemetry.EventObject
    
    // MARK: Init() and viewDidLoad()
    
    /// - Parameters:
    ///   - profile: User Profile info
    ///   - parentType: FxASignInParentType is an enum parent page that presented this VC. Parameter used in telemetry button events.
    init(profile: Profile, parentType: FxASignInParentType) {
        self.profile = profile
        switch parentType {
        case .appMenu:
            self.telemetryObject = .appMenu
        case .onboarding:
            self.telemetryObject = .onboarding
        case .settings:
            self.telemetryObject = .settings
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must init FirefoxAccountSignInVC with custom initializer including Profile and ParentType parameters")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        addViewConstraints()
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
            make.top.equalTo(view.snp_topMargin).offset(100)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        pairImageView.snp.makeConstraints { make in
            make.top.equalTo(qrSignInLabel.snp_bottomMargin).offset(20)
            make.height.equalToSuperview().multipliedBy(0.3)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        instructionsLabel.snp.makeConstraints { make in
            make.top.equalTo(pairImageView.snp_bottomMargin).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        scanButton.snp.makeConstraints { make in
            make.top.equalTo(instructionsLabel.snp_bottomMargin).offset(100)
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
    
    // MARK: Button Tap Functions
    
    /// Scan QR code button tapped
    @objc func scanbuttonTapped(_ sender: UIButton) {
        let qrCodeVC = QRCodeViewController()
        qrCodeVC.qrCodeDelegate = self
        UnifiedTelemetry.recordEvent(category: .firefoxAccount, method: .tap, object: telemetryObject, extras: ["flow_type": "pairing"])
        presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: qrCodeVC, topTabsVisible: true)
    }
    
    /// Use email login button tapped
    @objc func emailLoginTapped(_ sender: UIButton) {
        let fxaWebVC = FxAWebViewController(pageType: .emailLoginFlow, profile: profile, dismissalStyle: .popToRootVC)
        UnifiedTelemetry.recordEvent(category: .firefoxAccount, method: .qrPairing, object: telemetryObject, extras: ["flow_type": "email"])
        presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: fxaWebVC, topTabsVisible: false)
    }
    
}

// MARK: QRCodeViewControllerDelegate Functions
extension FirefoxAccountSignInViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        let vc = FxAWebViewController(pageType: .qrCode(url: url.absoluteString), profile: profile, dismissalStyle: .popToRootVC)
        present(vc, animated: true, completion: nil)
    }

    func didScanQRCodeWithText(_ text: String) {
        Sentry.shared.send(message: "FirefoxAccountSignInVC Error: `didScanQRCodeWithText` should not be called")
    }
}
