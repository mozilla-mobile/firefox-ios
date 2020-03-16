//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FTRAlertViewController.h"

@interface FTRAlertViewController()

#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
@property(strong, nonatomic) UIAlertView *alertView;
#else
@property(strong, nonatomic) UIAlertController *alertController;
#endif
@end

@implementation FTRAlertViewController

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
  if (self.alertView) {
    [self.alertView dismissWithClickedButtonIndex:[self.alertView cancelButtonIndex] animated:NO];
  }
#else
  if (self.alertController) {
    [self.alertController dismissViewControllerAnimated:NO completion:nil];
  }
#endif
}

- (IBAction)showSimpleAlert:(id)sender {
#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Alert!"
                                              message:@"Danger Will Robinson!"
                                             delegate:nil
                                    cancelButtonTitle:@"Flee"
                                    otherButtonTitles:nil];
  [self.alertView show];
#else
  self.alertController =
      [UIAlertController alertControllerWithTitle:@"Alert!"
                                          message:@"Danger Will Robinson!"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Flee"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [self.alertController addAction:cancelAction];
  [self presentViewController:self.alertController animated:YES completion:nil];
#endif
}

- (IBAction)showMultiOptionAlert:(id)sender {
#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
  self.alertView =
      [[UIAlertView alloc] initWithTitle:@"Alert!"
                                 message:@"Danger Will Robinson!"
                                delegate:self
                       cancelButtonTitle:@"Flee"
                       otherButtonTitles:@"Use Phaser", @"Use Slingshot", nil];
  [self.alertView show];
#else
  self.alertController =
      [UIAlertController alertControllerWithTitle:@"Alert!"
                                          message:@"Danger Will Robinson!"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *usePhaserAction =
      [UIAlertAction actionWithTitle:@"Use Phaser"
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *_Nonnull action) {
                               [self presentViewController:[self chainedViewController]
                                                  animated:YES
                                                completion:nil];
                             }];
  UIAlertAction *useSlingshotAction = [UIAlertAction actionWithTitle:@"Use Slingshot"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Flee"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [self.alertController addAction:usePhaserAction];
  [self.alertController addAction:useSlingshotAction];
  [self.alertController addAction:cancelAction];

  [self presentViewController:self.alertController animated:YES completion:nil];
#endif
}

- (IBAction)showStyledAlert:(id)sender {
#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
  self.alertView = [[UIAlertView alloc] initWithTitle:@"Styled alert!"
                                              message:@"Who are you?"
                                             delegate:self
                                    cancelButtonTitle:@"Cancel"
                                    otherButtonTitles:@"Leave", nil];
  self.alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
  [self.alertView show];
#else
  self.alertController =
      [UIAlertController alertControllerWithTitle:@"Styled alert!"
                                          message:@"Who are you?"
                                   preferredStyle:UIAlertControllerStyleAlert];
  [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Login";
  }];
  [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Password";
    textField.secureTextEntry = YES;
  }];
  UIAlertAction *leaveAction =
      [UIAlertAction actionWithTitle:@"Leave"
                               style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *_Nonnull action) {
                               [self presentViewController:[self chainedViewController]
                                                  animated:YES
                                                completion:nil];
                             }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [self.alertController addAction:leaveAction];
  [self.alertController addAction:cancelAction];

  [self presentViewController:self.alertController animated:YES completion:nil];
#endif
}

#if !defined(__IPHONE_9_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Danger!"
                                                    message:@"*zap*"
                                                   delegate:nil
                                          cancelButtonTitle:@"Roger"
                                          otherButtonTitles:nil];
    [alert show];
  }
}
#else
- (UIAlertController *)chainedViewController {
  UIAlertController *styledAlertController =
      [UIAlertController alertControllerWithTitle:@"Danger!"
                                          message:@"*zap*"
                                   preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Roger"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [styledAlertController addAction:cancelAction];
  return styledAlertController;
}
#endif

@end
