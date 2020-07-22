/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

class IntroScreenSyncViewV1: UIView, CardTheme {
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return theme == .dark ? UIColor.Firefox.DarkGrey10 : .white
    }
    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()
    // Views
    private lazy var titleImageViewPage2: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "tour-Sync"))
        imgView.contentMode = .center
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var subTitleLabelPage2: UILabel = {
        let fontSize: CGFloat = screenSize.width <= 320 ? 16 : 20
        let label = UILabel()
        label.text = Strings.CardTextSync
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 3
        return label
    }()
    private var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "close-large"), for: .normal)
        if #available(iOS 13, *) {
            closeButton.tintColor = .secondaryLabel
        } else {
            closeButton.tintColor = .black
        }
        return closeButton
    }()
    private lazy var signUpButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "signUpOnboardingButton"
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.Photon.Blue50
        button.setTitle(Strings.IntroSignUpButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    private lazy var signInButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "signInOnboardingButton"
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray.cgColor
        button.backgroundColor = .clear
        button.setTitle(Strings.IntroSignInButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    private lazy var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.accessibilityIdentifier = "startBrowsingOnboardingButton"
        return button
    }()
    // Helper views
    let main2panel = UIStackView()
    let imageHolder = UIView()
    let bottomHolder = UIView()
    // Closure delegates
    var closeClosure: (() -> Void)?
    var nextClosure: (() -> Void)?
    var signUpClosure: (() -> Void)?
    var signInClosure: (() -> Void)?
    // Basic variables
    private var currentPage = 1
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialViewSetup()
    }
    
    // MARK: View setup
    private func initialViewSetup() {
        // Background colour setup
        backgroundColor = fxBackgroundThemeColour
        // View setup
        main2panel.axis = .vertical
        main2panel.distribution = .fillEqually
    
        addSubview(main2panel)
        main2panel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(safeArea.top)
            make.bottom.equalTo(safeArea.bottom)
        }
        
        main2panel.addArrangedSubview(imageHolder)
        imageHolder.addSubview(titleImageViewPage2)
        titleImageViewPage2.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        main2panel.addArrangedSubview(bottomHolder)
        [subTitleLabelPage2, signUpButton, signInButton, startBrowsingButton].forEach {
             bottomHolder.addSubview($0)
         }
        
        subTitleLabelPage2.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(35)
            make.top.equalToSuperview()
        }
        
        let buttonEdgeInset = 15
        let buttonHeight = 46
        let buttonSpacing = 16
        
        signUpButton.addTarget(self, action: #selector(showSignUpFlow), for: .touchUpInside)
        signUpButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(buttonEdgeInset)
            make.bottom.equalTo(signInButton.snp.top).offset(-buttonSpacing)
            make.height.equalTo(buttonHeight)
        }
        signInButton.addTarget(self, action: #selector(showEmailLoginFlow), for: .touchUpInside)
        signInButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(buttonEdgeInset)
            make.bottom.equalTo(startBrowsingButton.snp.top).offset(-buttonSpacing)
            make.height.equalTo(buttonHeight)
        }
        startBrowsingButton.addTarget(self, action: #selector(startBrowsing), for: .touchUpInside)
        startBrowsingButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(buttonEdgeInset)
            // On large iPhone screens, bump this up from the bottom
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 20 : (screenSize.height > 800 ? 60 : 20)
            make.bottom.equalToSuperview().inset(offset)
            make.height.equalTo(buttonHeight)
        }
        
        addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(startBrowsing), for: .touchUpInside)
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(buttonEdgeInset)
            make.right.equalToSuperview().inset(buttonEdgeInset)
        }
        if #available(iOS 13, *) {
            closeButton.tintColor = .secondaryLabel
        } else {
            closeButton.tintColor = .black
        }
    }
    
    // MARK: Button Actions
    @objc func startBrowsing() {
        LeanPlumClient.shared.track(event: .dismissedOnboarding, withParameters: ["dismissedOnSlide": String(currentPage)])
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboarding, extras: ["slide-num": currentPage])
        closeClosure?()
    }

    @objc func showEmailLoginFlow() {
        LeanPlumClient.shared.track(event: .dismissedOnboardingShowLogin, withParameters: ["dismissedOnSlide": String(currentPage)])
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboardingEmailLogin, extras: ["slide-num": currentPage])
        signInClosure?()
    }

    @objc func showSignUpFlow() {
        LeanPlumClient.shared.track(event: .dismissedOnboardingShowSignUp, withParameters: ["dismissedOnSlide": String(currentPage)])
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboardingSignUp, extras: ["slide-num": currentPage])
        signUpClosure?()
    }
    
    @objc private func dismissAnimated() {
        startBrowsing()
        closeClosure?()
    }
}
