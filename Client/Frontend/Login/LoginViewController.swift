// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Snappy

class LoginViewController: UIViewController
{
    var loginButton: UIButton!
    var loginLabel: UILabel!
    var forgotPasswordButton: UIButton!
    var signupButton: UIButton!
    var userText: UITextField!
    var passText: UITextField!
    var statusLabel: UILabel!

    var accountManager: AccountManager!
    
    private final let IMAGE_PATH_LOGO = "guidelines-logo"
    private final let IMAGE_PATH_EMAIL = "email.png"
    private final let IMAGE_PATH_PASSWORD = "password.png"
    private final let IMAGE_PATH_REVEAL = "visible-text.png"
    
    // TODO: Use a strings file.
    private final let TEXT_LOGIN = "Login"
    private final let TEXT_LOGIN_LABEL = "Sign in with your Firefox account"
    private final let TEXT_LOGIN_INSTEAD = "Sign in instead"
    private final let TEXT_SIGNUP = "Sign up"
    private final let TEXT_SIGNUP_LABEL = "Create a new Firefox account"
    private final let TEXT_SIGNUP_INSTEAD = "Sign up instead"
    private final let TEXT_FORGOT_PASSWORD = "Forgot password?"
    
    // True if showing login state; false if showing sign up state.
    private var stateLogin = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.darkGrayColor()
        
        // Firefox logo
        let image = UIImage(named: IMAGE_PATH_LOGO)!
        let logo = UIImageView(image: image)
        view.addSubview(logo)
        let ratio = image.size.width / image.size.height
        logo.snp_makeConstraints { make in
            make.top.equalTo(60)
            make.centerX.equalTo(self.view)
            make.width.equalTo(75)
            make.width.equalTo(logo.snp_height).multipliedBy(ratio)
        }
        
        // 105 text
        let label105 = UILabel()
        label105.textColor = UIColor.whiteColor()
        label105.font = UIFont(name: "HelveticaNeue-UltraLight", size: 25)
        label105.text = "105"
        view.addSubview(label105)
        label105.snp_makeConstraints { make in
            make.top.equalTo(logo.snp_bottom).offset(8)
            make.centerX.equalTo(self.view)
        }
        
        // Email address
        userText = UITextField()
        userText.backgroundColor = UIColor.lightGrayColor()
        userText.font = UIFont(name: "HelveticaNeue-Thin", size: 14)
        userText.textColor = UIColor.whiteColor()
        userText.placeholder = "Email address"
        userText.layer.borderColor = UIColor.whiteColor().CGColor
        userText.layer.borderWidth = 1
        view.addSubview(userText)
        userText.snp_makeConstraints { make in
            make.top.equalTo(label105.snp_bottom).offset(40)
            make.left.equalTo(self.view.snp_left)
            make.right.equalTo(self.view.snp_right)
            make.height.equalTo(30)
        }
        
        // Password
        passText = UITextField()
        passText.backgroundColor = UIColor.lightGrayColor()
        passText.font = UIFont(name: "HelveticaNeue-Thin", size: 14)
        passText.textColor = UIColor.whiteColor()
        passText.placeholder = "Password"
        passText.layer.borderColor = UIColor.whiteColor().CGColor
        passText.layer.borderWidth = 1
        passText.secureTextEntry = true
        view.addSubview(passText)
        passText.snp_makeConstraints { make in
            make.top.equalTo(self.userText.snp_bottom).offset(-1)
            make.left.equalTo(self.view.snp_left)
            make.right.equalTo(self.view.snp_right)
            make.height.equalTo(30)
        }
        
        // Login label
        loginLabel = UILabel()
        loginLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        loginLabel.textColor = UIColor.whiteColor()
        loginLabel.text = "Sign in with your Firefox account"
        view.addSubview(loginLabel)
        loginLabel.snp_makeConstraints { make in
            make.top.equalTo(self.passText.snp_bottom).offset(5)
            make.centerX.equalTo(self.view)
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
        addPaddedLeftView(userText, image: UIImage(named: IMAGE_PATH_EMAIL)!)
        view.addSubview(loginButton)
        loginButton.snp_makeConstraints { make in
            make.top.equalTo(self.loginLabel.snp_bottom).offset(25)
            make.centerX.equalTo(self.view)
        }
        
        // Forgot password button
        forgotPasswordButton = UIButton()
        forgotPasswordButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        forgotPasswordButton.setTitle("Forgot password?", forState: UIControlState.Normal)
        forgotPasswordButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        addPaddedLeftView(passText, image: UIImage(named: IMAGE_PATH_PASSWORD)!)
        let revealButton = addSecureTextSwitcher(passText)
        view.addSubview(forgotPasswordButton)
        forgotPasswordButton.snp_makeConstraints { make in
            make.top.equalTo(self.loginButton.snp_bottom).offset(25)
            make.centerX.equalTo(self.view)
        }
        
        // Sign up instead button
        signupButton = UIButton()
        signupButton.titleLabel!.font = UIFont(name: "HelveticaNeue-Thin", size: 12)
        signupButton.setTitle("Sign up instead", forState: UIControlState.Normal)
        signupButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        view.addSubview(signupButton)
        signupButton.snp_makeConstraints { make in
            make.top.equalTo(self.forgotPasswordButton.snp_bottom)
            make.centerX.equalTo(self.view)
        }
        
        // TODO: Is there a nicer way to refer to methods other than as a string...?
        revealButton.addTarget(self, action: "didClickPasswordReveal", forControlEvents: UIControlEvents.TouchUpInside)
        signupButton.addTarget(self, action: "didClickSignup", forControlEvents: UIControlEvents.TouchUpInside)
        forgotPasswordButton.addTarget(self, action: "didClickForgotPassword", forControlEvents: UIControlEvents.TouchUpInside)
        loginButton.addTarget(self, action: "didClickLogin", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    // Referenced as button selector.
    func didClickPasswordReveal() {
        passText.secureTextEntry = !passText.secureTextEntry
    }
    
    // Referenced as button selector.
    func didClickSignup() {
        stateLogin = !stateLogin
        
        if (stateLogin) {
            loginButton.setTitle(TEXT_LOGIN, forState: UIControlState.Normal)
            loginLabel.text = TEXT_LOGIN_LABEL
            forgotPasswordButton.hidden = false
            signupButton.setTitle(TEXT_SIGNUP_INSTEAD, forState: UIControlState.Normal)
        } else {
            loginButton.setTitle(TEXT_SIGNUP, forState: UIControlState.Normal)
            loginLabel.text = TEXT_SIGNUP_LABEL
            forgotPasswordButton.hidden = true
            signupButton.setTitle(TEXT_LOGIN_INSTEAD, forState: UIControlState.Normal)
        }
    }
    
    // Referenced as button selector.
    func didClickForgotPassword() {
    }

    // Referenced as button selector.
    func didClickLogin() {
        accountManager.login(userText.text, password: passText.text, { err in
            switch err {
                case .BadAuth:
                    println("Invalid username and/or password")
                default:
                    println("Connection error")
            }
        })
    }
    
    private func addPaddedLeftView(textField: UITextField, image: UIImage) {
        let imageView = UIImageView(image: image)
        // TODO: We should resize the raw image instead of programmatically scaling it.
        let scale: CGFloat = 0.6
        imageView.frame = CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)
        let padding: CGFloat = 10
        let paddingView = UIView(frame: CGRectMake(0, 0, imageView.bounds.width + padding, imageView.bounds.height))
        imageView.center = paddingView.center
        paddingView.addSubview(imageView)
        textField.leftView = paddingView
        textField.leftViewMode = UITextFieldViewMode.Always
    }
    
    private func addSecureTextSwitcher(textField: UITextField) -> UIButton {
        let image = UIImage(named: IMAGE_PATH_REVEAL)!
        // TODO: We should resize the raw image instead of programmatically scaling it.
        let scale: CGFloat = 0.7
        let button = UIButton(frame: CGRectMake(0, 0, image.size.width * scale, image.size.height * scale))
        button.setImage(image, forState: UIControlState.Normal)
        let padding: CGFloat = 10
        let paddingView = UIView(frame: CGRectMake(0, 0, button.bounds.width + padding, button.bounds.height))
        button.center = paddingView.center
        paddingView.addSubview(button)
        textField.rightView = paddingView
        textField.rightViewMode = UITextFieldViewMode.Always
        return button
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
