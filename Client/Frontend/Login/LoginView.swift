/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

// TODO: Use a strings file.
private let TextLogin = "Login"
private let TextLoginLabel = "Sign in with your Firefox account"
private let TextLoginInstead = "Sign in instead"
private let TextSignUp = "Sign up"
private let TextSignUpLabel = "Create a new Firefox account"
private let TextSignUpInstead = "Sign up instead"
private let TextForgotPassword = "Forgot password?"

private let ImagePathLogo = "guidelines-logo"
private let ImagePathEmail = "email.png"
private let ImagePathPassword = "password.png"

class LoginView: UIView {
    var didClickLogin: (() -> ())?

    private var loginButton: UIButton!
    private var loginLabel: UILabel!
    private var forgotPasswordButton: UIButton!
    private var switchLoginOrSignUpButton: UIButton!
    private var userText: ImageTextField!
    private var passText: PasswordTextField!
    private var statusLabel: UILabel!

    // True if showing login state; false if showing sign up state.
    private var stateLogin = true

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didInitView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        didInitView()
    }

    override init() {
        // init() calls init(frame) with a 0 rect.
        super.init()
    }

    var username: String {
        get {
            return userText.text
        }

        set(username) {
            userText.text = username
        }
    }

    var password: String {
        get {
            return passText.text
        }

        set(password) {
            passText.text = password
        }
    }

    private func didInitView() {
        backgroundColor = UIColor.darkGrayColor()

        // Firefox logo
        let image = UIImage(named: ImagePathLogo)!
        let logo = UIImageView(image: image)
        addSubview(logo)
        let ratio = image.size.width / image.size.height
        logo.snp_makeConstraints { make in
            make.top.equalTo(60)
            make.centerX.equalTo(self)
            make.width.equalTo(75)
            make.width.equalTo(logo.snp_height).multipliedBy(ratio)
        }

        // 105 text
        let label105 = UILabel()
        label105.textColor = UIColor.whiteColor()
        label105.font = UIFont(name: "HelveticaNeue-UltraLight", size: 25)
        label105.text = "105"
        addSubview(label105)
        label105.snp_makeConstraints { make in
            make.top.equalTo(logo.snp_bottom).offset(8)
            make.centerX.equalTo(self)
        }

        // Email address
        userText = ImageTextField()
        userText.setLeftImage(UIImage(named: ImagePathEmail))
        userText.backgroundColor = UIColor.lightGrayColor()
        userText.font = UIFont(name: "HelveticaNeue-Thin", size: 14)
        userText.textColor = UIColor.whiteColor()
        userText.placeholder = "Email address"
        userText.layer.borderColor = UIColor.whiteColor().CGColor
        userText.layer.borderWidth = 1
        userText.keyboardType = UIKeyboardType.EmailAddress
        addSubview(userText)
        userText.snp_makeConstraints { make in
            make.top.equalTo(label105.snp_bottom).offset(40)
            make.left.equalTo(self.snp_left)
            make.right.equalTo(self.snp_right)
            make.height.equalTo(30)
        }

        // Password
        passText = PasswordTextField()
        passText.setLeftImage(UIImage(named: ImagePathPassword))
        passText.backgroundColor = UIColor.lightGrayColor()
        passText.font = UIFont(name: "HelveticaNeue-Thin", size: 14)
        passText.textColor = UIColor.whiteColor()
        passText.placeholder = "Password"
        passText.layer.borderColor = UIColor.whiteColor().CGColor
        passText.layer.borderWidth = 1
        passText.secureTextEntry = true
        addSubview(passText)
        passText.snp_makeConstraints { make in
            make.top.equalTo(self.userText.snp_bottom).offset(-1)
            make.left.equalTo(self.snp_left)
            make.right.equalTo(self.snp_right)
            make.height.equalTo(30)
        }

        // Login label
        loginLabel = UILabel()
        loginLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        loginLabel.textColor = UIColor.whiteColor()
        loginLabel.text = "Sign in with your Firefox account"
        addSubview(loginLabel)
        loginLabel.snp_makeConstraints { make in
            make.top.equalTo(self.passText.snp_bottom).offset(5)
            make.centerX.equalTo(self)
        }

        // Login button
        loginButton = UIButton()
        loginButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 15)
        loginButton.setTitle("Login", forState: UIControlState.Normal)
        loginButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        loginButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        loginButton.layer.borderColor = UIColor.whiteColor().CGColor
        loginButton.layer.borderWidth = 1
        loginButton.layer.cornerRadius = 6
        addSubview(loginButton)
        loginButton.snp_makeConstraints { make in
            make.top.equalTo(self.loginLabel.snp_bottom).offset(25)
            make.centerX.equalTo(self)
        }

        // Forgot password button
        forgotPasswordButton = UIButton()
        forgotPasswordButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        forgotPasswordButton.setTitle("Forgot password?", forState: UIControlState.Normal)
        forgotPasswordButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        addSubview(forgotPasswordButton)
        forgotPasswordButton.snp_makeConstraints { make in
            make.top.equalTo(self.loginButton.snp_bottom).offset(25)
            make.centerX.equalTo(self)
        }

        // Sign up or login instead button
        switchLoginOrSignUpButton = UIButton()
        switchLoginOrSignUpButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        switchLoginOrSignUpButton.setTitle("Sign up instead", forState: UIControlState.Normal)
        switchLoginOrSignUpButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        addSubview(switchLoginOrSignUpButton)
        switchLoginOrSignUpButton.snp_makeConstraints { make in
            make.top.equalTo(self.forgotPasswordButton.snp_bottom)
            make.centerX.equalTo(self)
        }

        // Click listeners
        switchLoginOrSignUpButton.addTarget(self, action: "SELdidClickSwitchLoginOrSignUp", forControlEvents: UIControlEvents.TouchUpInside)
        forgotPasswordButton.addTarget(self, action: "SELdidClickForgotPassword", forControlEvents: UIControlEvents.TouchUpInside)
        loginButton.addTarget(self, action: "SELdidClickLogin", forControlEvents: UIControlEvents.TouchUpInside)
    }

    func SELdidClickSwitchLoginOrSignUp() {
        stateLogin = !stateLogin

        if (stateLogin) {
            loginButton.setTitle(TextLogin, forState: UIControlState.Normal)
            loginLabel.text = TextLoginLabel
            forgotPasswordButton.hidden = false
            switchLoginOrSignUpButton.setTitle(TextSignUpInstead, forState: UIControlState.Normal)
        } else {
            loginButton.setTitle(TextSignUp, forState: UIControlState.Normal)
            loginLabel.text = TextSignUpLabel
            forgotPasswordButton.hidden = true
            switchLoginOrSignUpButton.setTitle(TextLoginInstead, forState: UIControlState.Normal)
        }
    }

    func SELdidClickForgotPassword() {
    }

    func SELdidClickLogin() {
        didClickLogin?()
    }
}
