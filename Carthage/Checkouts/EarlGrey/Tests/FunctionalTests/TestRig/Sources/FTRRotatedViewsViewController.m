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

#import "FTRRotatedViewsViewController.h"

@implementation FTRRotatedViewsViewController

#pragma mark - Event handling

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
  if (event.subtype == UIEventSubtypeMotionShake) {
    [[self lastTappedLabel] setText:@"Device Was Shaken"];
  }
}

- (IBAction)onTopLeftTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: Top Left"];
}

- (IBAction)onTopRightTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: Top Right"];
}

- (IBAction)onBottomLeftTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: Bottom Left"];
}

- (IBAction)onBottomRightTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: Bottom Right"];
}

- (IBAction)onCenterTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: Center"];
}

- (IBAction)clearTapped:(id)sender {
  [[self lastTappedLabel] setText:@"Last tapped: None"];
}

@end
