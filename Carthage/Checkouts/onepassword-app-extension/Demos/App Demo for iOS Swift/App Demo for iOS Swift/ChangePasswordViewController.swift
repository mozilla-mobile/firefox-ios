//
//  ChangePasswordViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad Azzouz on 2015-05-14.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import Foundation

class ChangePasswordViewController: UIViewController {
	@IBOutlet weak var onepasswordButton: UIButton!
	@IBOutlet weak var oldPasswordTextField: UITextField!
	@IBOutlet weak var freshPasswordTextField: UITextField!
	@IBOutlet weak var confirmPasswordTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		if let patternImage = UIImage(named: "login-background.png") {
			self.view.backgroundColor = UIColor(patternImage: patternImage)
		}
		
		onepasswordButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	@IBAction func changePasswordIn1Password(_ sender:AnyObject) {
		guard let changedPassword = freshPasswordTextField.text,
			let oldPassword = oldPasswordTextField.text,
			let confirmationPassword = confirmPasswordTextField.text else {
				return
		}
		
		// Validate that the new password and the old password are not the same.
		if (oldPassword.count > 0 && oldPassword == changedPassword) {
			showChangePasswordFailedAlertWithMessage(message: "The old and the new password must not be the same")
			return
		}
		
		// Validate that the new and confirmation passwords match.
		if (changedPassword.count > 0 && changedPassword != confirmationPassword) {
			showChangePasswordFailedAlertWithMessage(message: "The new passwords and the confirmation password must match")
			return
		}
		
		let newLoginDetails:[String : Any] = [
			AppExtensionTitleKey: "ACME", // Optional, used for the third schenario only
			AppExtensionUsernameKey: "aUsername", // Optional, used for the third schenario only
			AppExtensionPasswordKey: changedPassword,
			AppExtensionOldPasswordKey: oldPassword,
			AppExtensionNotesKey: "Saved with the ACME app", // Optional, used for the third schenario only
		]
		
		// The password generation options are optional, but are very handy in case you have strict rules about password lengths, symbols and digits.
		let passwordGenerationOptions:[String : AnyObject] = [
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
		
		OnePasswordExtension.shared().changePasswordForLogin(forURLString: "https://www.acme.com", loginDetails: newLoginDetails, passwordGenerationOptions: passwordGenerationOptions, for: self, sender: sender) { (loginDictionary, error) in
			guard let loginDictionary = loginDictionary else {
				if let error = error as NSError?, error.code != AppExtensionErrorCode.cancelledByUser.rawValue {
					print("Error invoking 1Password App Extension for find login: \(String(describing: error))")
				}
				return
			}
			
			self.oldPasswordTextField.text = loginDictionary[AppExtensionOldPasswordKey] as? String
			self.freshPasswordTextField.text = loginDictionary[AppExtensionPasswordKey] as? String
			self.confirmPasswordTextField.text = loginDictionary[AppExtensionPasswordKey] as? String
		}
	}
	
	// Convenience function
	func showChangePasswordFailedAlertWithMessage(message:String) {
		let alertController = UIAlertController(title: "Change Password Error", message: message, preferredStyle: .alert)
		
		let dismissAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
			self.freshPasswordTextField.text = ""
			self.confirmPasswordTextField.text = ""
			self.freshPasswordTextField.becomeFirstResponder()
		}
		
		alertController.addAction(dismissAction)
		self.present(alertController, animated: true, completion: nil)
	}
}
