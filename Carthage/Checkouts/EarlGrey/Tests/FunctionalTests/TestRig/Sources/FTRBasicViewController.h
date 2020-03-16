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

@interface FTRBasicViewController : UIViewController <UITextFieldDelegate>

@property(retain, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property(retain, nonatomic) IBOutlet UILabel *hiddenLabel;

@property(retain, nonatomic) IBOutlet UIView *tab1;
@property(retain, nonatomic) IBOutlet UISlider *slider;
@property(retain, nonatomic) IBOutlet UIStepper *stepper;
@property(retain, nonatomic) IBOutlet UILabel *valueLabel;

@property(retain, nonatomic) IBOutlet UIView *tab2;
@property(retain, nonatomic) IBOutlet UILabel *sampleLabel;
@property(retain, nonatomic) IBOutlet UISwitch *switchView;
@property(retain, nonatomic) IBOutlet UITextField *textField;
@property(retain, nonatomic) IBOutlet UIButton *sendButton;
@property(retain, nonatomic) IBOutlet UITextView *textView;

@property(retain, nonatomic) IBOutlet UIButton *disabledButton;

@property(retain, nonatomic) IBOutlet UILabel *longPressLabel;
@property(retain, nonatomic) IBOutlet UILabel *doubleTapLabel;

- (instancetype)init NS_UNAVAILABLE;

@end
