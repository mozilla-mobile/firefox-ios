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
		self.view.backgroundColor = UIColor(patternImage: UIImage(named: "login-background.png")!)
		self.onepasswordButton.hidden = (false == OnePasswordExtension.sharedExtension().isAppExtensionAvailable())
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}
	
	@IBAction func changePasswordIn1Password(sender:AnyObject) -> Void {
		let changedPassword = self.freshPasswordTextField.text!
		let oldPassword = self.oldPasswordTextField.text!
		let confirmationPassword = self.confirmPasswordTextField.text!
		
		// Validate that the new password and the old password are not the same.
		if (oldPassword.characters.count > 0 && oldPassword == changedPassword) {
			self.showChangePasswordFailedAlertWithMessage("The old and the new password must not be the same")
			return
		}
		
		// Validate that the new and confirmation passwords match.
		if (changedPassword.characters.count > 0 && changedPassword != confirmationPassword) {
			self.showChangePasswordFailedAlertWithMessage("The new passwords and the confirmation password must match")
			return
		}
		
		let newLoginDetails:[String: AnyObject] = [
			AppExtensionTitleKey: "ACME", // Optional, used for the third schenario only
			AppExtensionUsernameKey: "aUsername", // Optional, used for the third schenario only
			AppExtensionPasswordKey: changedPassword,
			AppExtensionOldPasswordKey: oldPassword,
			AppExtensionNotesKey: "Saved with the ACME app", // Optional, used for the third schenario only
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
		
		OnePasswordExtension.sharedExtension().changePasswordForLoginForURLString("https://www.acme.com", loginDetails: newLoginDetails, passwordGenerationOptions: passwordGenerationOptions, forViewController: self, sender: sender) { (loginDictionary, error) -> Void in
			if loginDictionary == nil {
				if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
					print("Error invoking 1Password App Extension for find login: \(error)")
				}
				return
			}
			
			self.oldPasswordTextField.text = loginDictionary?[AppExtensionOldPasswordKey] as? String
			self.freshPasswordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String
			self.confirmPasswordTextField.text = loginDictionary?[AppExtensionPasswordKey] as? String
		}
	}
	
	// Convenience function
	func showChangePasswordFailedAlertWithMessage(message:String) -> Void {
		let alertController = UIAlertController(title: "Change Password Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
		
		let dismissAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
			self.freshPasswordTextField.text = ""
			self.confirmPasswordTextField.text = ""
			self.freshPasswordTextField.becomeFirstResponder()
		}
		
		alertController.addAction(dismissAction)
		self.presentViewController(alertController, animated: true, completion: nil)
	}
}
