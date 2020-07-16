/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import SnapKit

/* The layout for update view controller.

The whole is divided into two parts. Top container view and Bottom view.
Top container view sits above Sign Up button and its height spans all
the way from sign up button to top safe area. We then add [combined view]
that contains Image, Title and Description inside [Top container view]
to make it center in the top container view.
 
|----------------|----------[Top Container View]---------
|                |
|                |---------[Combined View]
|                |
|     Image      | [Top View]
|                |      -- Has title image view
|                |
|                | [Mid View]
|     Title      |      -- Has title
|                |      -- Description
|   Description  |
|                |---------[Combined View]
|                |
|----------------|----------[Top Container View]---------
|                |  Bottom View
|   [Sign up]    |      -- Bottom View
|                |      -- Start Browsing
| Start Browsing |
|                |
|----------------|

*/

class IntroScreenSyncViewV2: UIView, CardTheme {
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return theme == .dark ? UIColor.Firefox.DarkGrey10 : .white
    }
    private lazy var titleImageView: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "tour-sync-v2"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CardTitleFxASyncDevices
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.CardDescriptionFxASyncDevices
        label.textColor = fxTextThemeColour
        label.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    private var signUpButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.Photon.Blue50
        button.setTitle(Strings.IntroSignUpButtonTitle, for: .normal)
        return button
    }()
    private lazy var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .clear
        button.setTitleColor(UIColor.Photon.Blue50, for: .normal)
        button.setTitle(Strings.StartBrowsingButtonTitle, for: .normal)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    // Container and combined views
    private let topContainerView = UIView()
    private let combinedView = UIView()
    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()
    // Closure delegates
    var signUp: (() -> Void)?
    var startBrowsing: (() -> Void)?
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialViewSetup()
        topContainerViewSetup()
        bottomViewSetup()
    }
    
    // MARK: Initializer
    private func initialViewSetup() {
        combinedView.addSubview(titleLabel)
        combinedView.addSubview(descriptionLabel)
        combinedView.addSubview(titleImageView)
        topContainerView.addSubview(combinedView)
        addSubview(topContainerView)
        addSubview(signUpButton)
        addSubview(startBrowsingButton)
    }
    
    // MARK: View setup
    private func topContainerViewSetup() {
        // Background colour setup
        backgroundColor = fxBackgroundThemeColour
        // Height constants
        let titleLabelHeight = 100
        let descriptionLabelHeight = 100
        let titleImageHeight = screenSize.height > 600 ? 300 : 200
        // Title label constraints
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(titleImageView.snp.bottom)
            make.height.equalTo(titleLabelHeight)
        }
        // Description label constraints
        descriptionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.equalTo(descriptionLabelHeight)
        }
        // Title image view constraints
        titleImageView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(titleImageHeight)
        }
        // Top container view constraints
        topContainerView.snp.makeConstraints { make in
            make.top.equalTo(safeArea.top)
            make.bottom.equalTo(signUpButton.snp.top)
            make.left.right.equalToSuperview()
        }
        // Combined view constraints
        combinedView.snp.makeConstraints { make in
            make.height.equalTo(titleLabelHeight + descriptionLabelHeight + titleImageHeight)
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    
    private func bottomViewSetup() {
        // Sign-up button constraints
        signUpButton.snp.makeConstraints { make in
            make.bottom.equalTo(startBrowsingButton.snp.top).offset(-20)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(46)
            
        }
        // Start browsing button constraints
        startBrowsingButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeArea.bottom)
            make.left.right.equalToSuperview().inset(80)
            make.height.equalTo(46)
        }
        // Sign-up and start browsing button action
        signUpButton.addTarget(self, action: #selector(signUpAction), for: .touchUpInside)
        startBrowsingButton.addTarget(self, action: #selector(startBrowsingAction), for: .touchUpInside)
    }
    
    // MARK: Button Actions
    @objc private func signUpAction() {
        LeanPlumClient.shared.track(event: .dismissedOnboardingShowSignUp, withParameters: ["dismissedOnSlide": "1"])
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboardingSignUp, extras: ["slide-num": 1])
        print("Sign up")
        signUp?()
    }
    
    @objc private func startBrowsingAction() {
        LeanPlumClient.shared.track(event: .dismissedOnboarding, withParameters: ["dismissedOnSlide": "1"])
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedOnboarding, extras: ["slide-num": 1])
        print("Start Browsing")
        startBrowsing?()
    }
}

