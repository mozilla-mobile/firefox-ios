//
//  ChangePasswordViewController.m
//  App Demo for iOS
//
//  Created by Rad Azzouz on 2014-08-11.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

@interface ChangePasswordViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordButton;
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *freshPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@end

@implementation ChangePasswordViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
	NSBundle *onePasswordExtensionBundle = [NSBundle bundleForClass:[OnePasswordExtension class]];
	UIImage *onePasswordButtonImage = [UIImage imageNamed:@"onepassword-button" inBundle:onePasswordExtensionBundle compatibleWithTraitCollection:self.traitCollection];
	[self.onepasswordButton setImage:onePasswordButtonImage forState:UIControlStateNormal];
	[self.onepasswordButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

- (IBAction)changePasswordIn1Password:(id)sender {
	NSString *changedPassword = self.freshPasswordTextField.text ? : @"";
	NSString *oldPassword = self.oldPasswordTextField.text ? : @"";
	NSString *confirmationPassword = self.confirmPasswordTextField.text ? : @"";
	
	// Validate that the new password and the old password are not the same.
	if (oldPassword.length > 0 && [oldPassword isEqualToString:changedPassword]) {
		[self showChangePasswordFailedAlertWithMessage:@"The old and the new password must not be the same"];
		return;
	}
	
	// Validate that the new and confirmation passwords match.
	if (NO == [changedPassword isEqualToString:confirmationPassword]) {
		[self showChangePasswordFailedAlertWithMessage:@"The new passwords and the confirmation password must match"];
		return;
	}
	
	NSDictionary *loginDetails = @{
									  AppExtensionTitleKey: @"ACME", // Optional, used for the third schenario only
									  AppExtensionUsernameKey: @"aUsername", // Optional, used for the third schenario only
									  AppExtensionPasswordKey: changedPassword,
									  AppExtensionOldPasswordKey: oldPassword,
									  AppExtensionNotesKey: @"Saved with the ACME app", // Optional, used for the third schenario only
									  };
	
	// The password generation options are optional, but are very handy in case you have strict rules about password lengths, symbols and digits.
	NSDictionary *passwordGenerationOptions = @{
												// The minimum password length can be 4 or more.
												AppExtensionGeneratedPasswordMinLengthKey: @(8),
												
												// The maximum password length can be 50 or less.
												AppExtensionGeneratedPasswordMaxLengthKey: @(30),
												
												// If YES, the 1Password will guarantee that the generated password will contain at least one digit (number between 0 and 9). Passing NO will not exclude digits from the generated password.
												AppExtensionGeneratedPasswordRequireDigitsKey: @(YES),
												
												// If YES, the 1Password will guarantee that the generated password will contain at least one symbol (See the list bellow). Passing NO with will exclude symbols from the generated password.
												AppExtensionGeneratedPasswordRequireSymbolsKey: @(YES),
												
												// Here are all the symbols available in the the 1Password Password Generator:
												// !@#$%^&*()_-+=|[]{}'\";.,>?/~`
												// The string for AppExtensionGeneratedPasswordForbiddenCharactersKey should contain the symbols and characters that you wish 1Password to exclude from the generated password.
												AppExtensionGeneratedPasswordForbiddenCharactersKey: @"!@#$%/0lIO"
												};
	
	[[OnePasswordExtension sharedExtension] changePasswordForLoginForURLString:@"https://www.acme.com" loginDetails:loginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDictionary, NSError *error) {
		if (loginDictionary.count == 0) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
			}
			return;
		}
		
		self.oldPasswordTextField.text = loginDictionary[AppExtensionOldPasswordKey];
		self.freshPasswordTextField.text = loginDictionary[AppExtensionPasswordKey];
		self.confirmPasswordTextField.text = loginDictionary[AppExtensionPasswordKey];
	}];
}

#pragma mark - Convenience methods

- (void)showChangePasswordFailedAlertWithMessage:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password Error" message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		self.freshPasswordTextField.text = @"";
		self.confirmPasswordTextField.text = @"";
		[self.freshPasswordTextField becomeFirstResponder];
	}];
	
	[alert addAction:dismissAction];
	[self presentViewController:alert animated:YES completion:nil];
}

@end
