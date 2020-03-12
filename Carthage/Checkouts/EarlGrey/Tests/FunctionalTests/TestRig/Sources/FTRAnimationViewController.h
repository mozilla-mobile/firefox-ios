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

#import <UIKit/UIKit.h>

// Controls a view that contains a view we can animation. Clicking on the button animates the view
// and the view pauses after 2 seconds, clicking the button again resumes the animation until the
// animation finishes.
@interface FTRAnimationViewController : UIViewController

@property(weak, nonatomic) IBOutlet UIView *viewToAnimate;
@property(weak, nonatomic) IBOutlet UIButton *CAAnimationControlButton;
@property(weak, nonatomic) IBOutlet UIButton *UIViewAnimationControlButton;
@property(weak, nonatomic) IBOutlet UILabel *animationStatusLabel;
@property(weak, nonatomic) IBOutlet UILabel *delayedExecutionStatusLabel;

// Called when "Begin Ignoring Events" button is clicked. This calls through to application's
// beginIgnoringInteractionEvent and after 2 seconds calls endIgnoringInteractionEvent. EarlGrey
// should synchronize with this and return the control back to the test after
// endIgnoringInteractionEvents is called.
- (IBAction)beginIgnoringEventsClicked:(id)sender;

- (IBAction)CAAnimationControlClicked:(id)sender;

- (IBAction)UIViewAnimationControlClicked:(id)sender;

// Calls performSelector with a delay to set delayedExecutionStatusLabel's text.
- (IBAction)delayedAnimationButtonClicked:(id)sender;

@end
