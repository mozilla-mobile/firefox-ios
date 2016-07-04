//
//  LoginViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad Azzouz on 2015-05-14.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import Foundation

class LoginViewController: UIViewController {

	@IBOutlet weak var onepasswordButton: UIButton!
	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var oneTimePasswordTextField: UITextField!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor(patternImage: UIImage(named: "login-background.png")!)
		self.onepasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() == false {
			let alertController = UIAlertController(title: "1Password is not installed", message: "Get 1Password from the App Store", preferredStyle: UIAlertControllerStyle.Alert)

			let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
			alertController.addAction(cancelAction)

			let OKAction = UIAlertAction(title: "Get 1Password", style: .Default) { (action) in UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/app/1password-password-manager/id568903335")!)
			}

			alertController.addAction(OKAction)
			self.presentViewController(alertController, animated: true, completion: nil)
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	@IBAction func findLoginFrom1Password(sender:AnyObject) -> Void {
		OnePasswordExtension.sharedExtension().findLoginForURLString("https://www.acme.com", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
			if loginDictionary == nil {
				if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
					print("Error invoking 1Password App Extension for find login: \(error)")
				}
				return
			}
			
			self.usernameTextField.text = loginDictionary?[AppExtensionUsernameKey] as? String
			self.passwordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String

			if let generatedOneTimePassword = loginDictionary?[AppExtensionTOTPKey] as? String {
				self.oneTimePasswordTextField.hidden = false
				self.oneTimePasswordTextField.text = generatedOneTimePassword

				// Important: It is recommended that you submit the OTP/TOTP to your validation server as soon as you receive it, otherwise it may expire.
				let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
				dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
					self.performSegueWithIdentifier("showThankYouViewController", sender: self)
				})
			}

		})
	}
}
