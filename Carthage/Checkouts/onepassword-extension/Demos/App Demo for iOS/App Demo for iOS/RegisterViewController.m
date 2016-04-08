//
//  RegisterViewController.m
//  App Demo for iOS
//
//  Created by Rad Azzouz on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "RegisterViewController.h"
#import <OnePasswordExtension/OnePasswordExtension.h>

@interface RegisterViewController ()

@property (weak, nonatomic) IBOutlet UIButton *onepasswordButton;

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];

	NSBundle *onePasswordExtensionBundle = [NSBundle bundleForClass:[OnePasswordExtension class]];
	UIImage *onePasswordButtonImage = [UIImage imageNamed:@"onepassword-button" inBundle:onePasswordExtensionBundle compatibleWithTraitCollection:self.traitCollection];
	[self.onepasswordButton setImage:onePasswordButtonImage forState:UIControlStateNormal];
	[self.onepasswordButton setHidden:![[OnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleDefault;
}

- (IBAction)saveLoginTo1Password:(id)sender {
	NSDictionary *newLoginDetails = @{
									  AppExtensionTitleKey: @"ACME",
									  AppExtensionUsernameKey: self.usernameTextField.text ? : @"",
									  AppExtensionPasswordKey: self.passwordTextField.text ? : @"",
									  AppExtensionNotesKey: @"Saved with the ACME app",
									  AppExtensionSectionTitleKey: @"ACME Browser",
									  AppExtensionFieldsKey: @{
											  @"firstname" : self.firstnameTextField.text ? : @"",
											  @"lastname" : self.lastnameTextField.text ? : @""
											  // Add as many string fields as you please.
											  }
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

	[[OnePasswordExtension sharedExtension] storeLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions forViewController:self sender:sender completion:^(NSDictionary *loginDictionary, NSError *error) {

		if (loginDictionary.count == 0) {
			if (error.code != AppExtensionErrorCodeCancelledByUser) {
				NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
			}
			return;
		}

		self.usernameTextField.text = loginDictionary[AppExtensionUsernameKey] ? : @"";
		self.passwordTextField.text = loginDictionary[AppExtensionPasswordKey] ? : @"";
		self.firstnameTextField.text = loginDictionary[AppExtensionReturnedFieldsKey][@"firstname"] ? : @"";
		self.lastnameTextField.text = loginDictionary[AppExtensionReturnedFieldsKey][@"lastname"] ? : @"";
		// retrieve any additional fields that were passed in newLoginDetails dictionary
	}];
}

@end
