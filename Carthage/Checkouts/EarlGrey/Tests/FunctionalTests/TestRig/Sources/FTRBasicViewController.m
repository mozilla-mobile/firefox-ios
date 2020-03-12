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

#import "FTRBasicViewController.h"

@interface FTRBasicViewController ()
@end

@implementation FTRBasicViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.sampleLabel.accessibilityIdentifier = @"sampleLabel";

  self.disabledButton.enabled = NO;

  self.textField.delegate = self;
  self.textField.accessibilityIdentifier = @"foo";

  self.stepper.minimumValue = 0;
  self.stepper.maximumValue = 100;
  self.stepper.value = 50;
  self.stepper.stepValue = 1;

  self.slider.minimumValue = 0;
  self.slider.maximumValue = 100;
  self.slider.value = 50;

  self.hiddenLabel.accessibilityLabel = @"Hidden Label";
  // Set this property explicitly to YES since hidden labels
  // have their isAccessibilityElement property set to NO.
  // This needs to be explicltly done by all users that with hidden
  // labels that are to be accessible.
  self.hiddenLabel.isAccessibilityElement = YES;

  [self.segmentedControl setSelectedSegmentIndex:0];
  [self.segmentedControl addTarget:self
                            action:@selector(tabChange:)
                  forControlEvents:UIControlEventValueChanged];

  UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                        initWithTarget:self
                                                                action:@selector(hideLongPress)];
  longPressGesture.minimumPressDuration = 1.0;
  [self.longPressLabel addGestureRecognizer:longPressGesture];

  UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]
                                            initWithTarget:self
                                                    action:@selector(moveDoubleTapOffScreen)];
  doubleTap.numberOfTapsRequired = 2;
  [self.doubleTapLabel addGestureRecognizer:doubleTap];
}

- (void)hideLongPress {
  self.longPressLabel.hidden = YES;
}

- (void)moveDoubleTapOffScreen {
  self.doubleTapLabel.hidden = YES;
}

- (void)tabChange:(id)sender {
  BOOL isTab1 = self.segmentedControl.selectedSegmentIndex == 0;
  [UIView animateWithDuration:1.0f animations:^{
      self.tab1.alpha = isTab1 ? 1 : 0;
      self.tab2.alpha = isTab1 ? 0 : 1;
  }];
}

- (IBAction)stepperDidChange:(UIStepper *)sender {
  double val = [sender value];
  self.slider.value = (float)val;
  self.valueLabel.text = [NSString stringWithFormat:@"Value: %d%%", (int)val];
}

- (IBAction)sliderDidChange:(UISlider *)sender {
  double val = [sender value];
  self.stepper.value = val;
  self.valueLabel.text = [NSString stringWithFormat:@"Value: %d%%", (int)val];
}

- (IBAction)switchDidChange:(UISwitch *)sender {
  self.sampleLabel.text = [sender isOn] ? @"ON" : @"OFF";
}

- (IBAction)onSendClick:(id)sender {
  self.sampleLabel.text = [self.textField.text copy];
  self.textView.text = @"";
  self.sendButton.selected = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

@end
