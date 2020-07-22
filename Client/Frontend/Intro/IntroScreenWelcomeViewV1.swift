/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

class IntroScreenWelcomeViewV1: UIView, CardTheme {
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
    private lazy var titleImageViewPage1: UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "tour-Welcome"))
        imgView.contentMode = .center
        imgView.clipsToBounds = true
        return imgView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CardTitleWelcome
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    private lazy var subTitleLabelPage1: UILabel = {
        let fontSize: CGFloat = screenSize.width <= 320 ? 16 : 20
        let label = UILabel()
        label.text = Strings.CardTextWelcome
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
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
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.IntroNextButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.accessibilityIdentifier = "nextOnboardingButton"
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
    private var currentPage = 0
    
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
        imageHolder.addSubview(titleImageViewPage1)
        titleImageViewPage1.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        main2panel.addArrangedSubview(bottomHolder)
        [titleLabel, subTitleLabelPage1, signUpButton, signInButton, nextButton].forEach {
             bottomHolder.addSubview($0)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(10)
            make.top.equalToSuperview()
        }
        
        subTitleLabelPage1.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(35)
            make.top.equalTo(titleLabel.snp.bottom)
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
            make.bottom.equalTo(nextButton.snp.top).offset(-buttonSpacing)
            make.height.equalTo(buttonHeight)
        }
        nextButton.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
        nextButton.snp.makeConstraints { make in
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
    
    @objc private func nextAction() {
        nextClosure?()
    }
    
    @objc private func dismissAnimated() {
        closeClosure?()
    }
}
