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

#import "FTRActivityIndicatorViewController.h"

@implementation FTRActivityIndicatorViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.activityIndicator.hidesWhenStopped = YES;
  self.activityIndicator.hidden = NO;
  self.activityIndicator.isAccessibilityElement = YES;
  self.activityIndicator.accessibilityLabel = @"activity indicator";
}

#pragma mark - Button Handlers

- (IBAction)startAndStopActivity:(id)sender {
  [self.activityIndicator startAnimating];
  [self performSelector:@selector(stopActivity) withObject:nil afterDelay:2.0];
}

- (IBAction)startAndHideActivity:(id)sender {
  [self.activityIndicator startAnimating];
  [self performSelector:@selector(toggleActivityHiddenProperty) withObject:nil afterDelay:2.0];
}

- (IBAction)startAndRemoveFromSuperView:(id)sender {
  [self.activityIndicator startAnimating];
  [self performSelector:@selector(removeActivityFromSuperView) withObject:nil afterDelay:2.0];
}

- (IBAction)startHiddenAndThenStopActivity:(id)sender {
  self.activityIndicator.hidden = YES;
  [self.activityIndicator startAnimating];
  [self performSelector:@selector(stopActivity) withObject:nil afterDelay:2.0];
}

- (IBAction)toggleHidesWhenStopped:(UISwitch *)sender {
  self.activityIndicator.hidesWhenStopped = [sender isOn];
}

#pragma mark - Private

// Toggles the UIActivityIndicator's hidden property and updates the status lable accordingly.
- (void)toggleActivityHiddenProperty {
  self.activityIndicator.hidden = !self.activityIndicator.hidden;
  if (self.activityIndicator.hidden) {
    [self.status setText:@"Hidden"];
  } else {
    [self.status setText:@"Shown"];
  }

}

// Removes the UIActivityIndicator from its superview.
- (void)removeActivityFromSuperView {
  [self.activityIndicator removeFromSuperview];
  [self.status setText:@"Removed from superview"];
}

// Stops the UIActivityIndicator's spinning animation.
- (void)stopActivity {
  [self.activityIndicator stopAnimating];
  [self.status setText:@"Stopped"];
}

@end
