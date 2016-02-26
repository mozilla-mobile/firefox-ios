//
//  RegisterViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad on 2015-05-14.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import Foundation

class RegisterViewController: UIViewController {
	@IBOutlet weak var onepasswordButton: UIButton!
	@IBOutlet weak var firstnameTextField: UITextField!
	@IBOutlet weak var lastnameTextField: UITextField!
	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!

	override func viewDidLoad() {
		super.viewDidLoad()
		UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:UIStatusBarAnimation.None)
		self.view.backgroundColor = UIColor(patternImage: UIImage(named: "register-background.png")!)
		self.onepasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.Default
	}

	@IBAction func saveLoginTo1Password(sender:AnyObject) -> Void {
		let newLoginDetails:[String: AnyObject] = [
			AppExtensionTitleKey: "ACME",
			AppExtensionUsernameKey: self.usernameTextField.text!,
			AppExtensionPasswordKey: self.passwordTextField.text!,
			AppExtensionNotesKey: "Saved with the ACME app",
			AppExtensionSectionTitleKey: "ACME Browser",
			AppExtensionFieldsKey: [
				"firstname" : self.firstnameTextField.text!,
				"lastname" : self.lastnameTextField.text!
				// Add as many string fields as you please.
			]
		]

		// The password generation options are optional, but are very handy in case you have strict rules about password lengths, symbols and digits.
		let passwordGenerationOptions:[String: AnyObject] = [
			// The minimum password length can be 4 or more.
			AppExtensionGeneratedPasswordMinLengthKey: (8),
			
			// The maximum password length can be 50 or less.
			AppExtensionGeneratedPasswordMaxLengthKey: (30),
			
			// If YES, the 1Password will guarantee that the generated password will contain at least one digit (number between 0 and 9). Passing NO will not exclude digits from the generated password.
			AppExtensionGeneratedPasswordRequireDigitsKey: (true),
			
			// If YES, the 1Password will guarantee that the generated password will contain at least one symbol (See the list bellow). Passing NO with will exclude symbols from the generated password.
			AppExtensionGeneratedPasswordRequireSymbolsKey: (true),
			
			// Here are all the symbols available in the the 1Password Password Generator:
			// !@#$%^&*()_-+=|[]{}'\";.,>?/~`
			// The string for AppExtensionGeneratedPasswordForbiddenCharactersKey should contain the symbols and characters that you wish 1Password to exclude from the generated password.
			
			AppExtensionGeneratedPasswordForbiddenCharactersKey: "!@#$%/0lIO"
		]
		
		OnePasswordExtension.sharedExtension().storeLoginForURLString("https://www.acme.com", loginDetails: newLoginDetails, passwordGenerationOptions: passwordGenerationOptions, forViewController: self, sender: sender) { (loginDictionary, error) -> Void in
			if loginDictionary == nil {
				if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
					print("Error invoking 1Password App Extension for find login: \(error)")
				}
				return
			}

			self.usernameTextField.text = loginDictionary?[AppExtensionUsernameKey] as? String
			self.passwordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String
			self.firstnameTextField.text = loginDictionary?[AppExtensionReturnedFieldsKey]?["firstname"] as? String
			self.lastnameTextField.text = loginDictionary?[AppExtensionReturnedFieldsKey]?["lastname"] as? String
		}
	}
}