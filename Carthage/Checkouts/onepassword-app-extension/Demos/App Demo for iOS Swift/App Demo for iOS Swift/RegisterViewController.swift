//
//  RegisterViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad Azzouz on 2015-05-14.
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
		
		if let patternImage = UIImage(named: "register-background.png") {
			self.view.backgroundColor = UIColor(patternImage: patternImage)
		}
		
		onepasswordButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return UIStatusBarStyle.default
	}

	@IBAction func saveLoginTo1Password(_ sender:AnyObject) {
		let newLoginDetails:[String: Any] = [
			AppExtensionTitleKey: "ACME",
			AppExtensionUsernameKey: usernameTextField.text ?? "",
			AppExtensionPasswordKey: passwordTextField.text ?? "",
			AppExtensionNotesKey: "Saved with the ACME app",
			AppExtensionSectionTitleKey: "ACME Browser",
			AppExtensionFieldsKey: [
				"firstname" : firstnameTextField.text ?? "",
				"lastname" : lastnameTextField.text ?? ""
				// Add as many string fields as you please.
			]
		]

		// The password generation options are optional, but are very handy in case you have strict rules about password lengths, symbols and digits.
		let passwordGenerationOptions:[String: AnyObject] = [
			// The minimum password length can be 4 or more.
			AppExtensionGeneratedPasswordMinLengthKey: (8 as NSNumber),
			
			// The maximum password length can be 50 or less.
			AppExtensionGeneratedPasswordMaxLengthKey: (30 as NSNumber),
			
			// If YES, the 1Password will guarantee that the generated password will contain at least one digit (number between 0 and 9). Passing NO will not exclude digits from the generated password.
			AppExtensionGeneratedPasswordRequireDigitsKey: (true as NSNumber),
			
			// If YES, the 1Password will guarantee that the generated password will contain at least one symbol (See the list below). Passing NO will not exclude symbols from the generated password.
			AppExtensionGeneratedPasswordRequireSymbolsKey: (true as NSNumber),
			
			// Here are all the symbols available in the the 1Password Password Generator:
			// !@#$%^&*()_-+=|[]{}'\";.,>?/~`
			// The string for AppExtensionGeneratedPasswordForbiddenCharactersKey should contain the symbols and characters that you wish 1Password to exclude from the generated password.
			AppExtensionGeneratedPasswordForbiddenCharactersKey: "!@#$%/0lIO" as NSString
		]
		
		OnePasswordExtension.shared().storeLogin(forURLString: "https://www.acme.com", loginDetails: newLoginDetails, passwordGenerationOptions: passwordGenerationOptions, for: self, sender: sender) { (loginDictionary, error) in
			guard let loginDictionary = loginDictionary else {
				if let error = error as NSError?, error.code != AppExtensionErrorCode.cancelledByUser.rawValue {
					print("Error invoking 1Password App Extension for find login: \(String(describing: error))")
				}
				return
			}

			self.usernameTextField.text = loginDictionary[AppExtensionUsernameKey] as? String
			self.passwordTextField.text = loginDictionary[AppExtensionPasswordKey] as? String
			if let returnedLoginDictionary = loginDictionary[AppExtensionReturnedFieldsKey] as? [String: Any] {
				self.firstnameTextField.text = returnedLoginDictionary["firstname"] as? String
				self.lastnameTextField.text = returnedLoginDictionary["lastname"] as? String
			}
		}
	}
}
