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

@class FTRCustomTextView;

@class FTRCustomKeyboardTracker;

// View controller for the Typing section of the TestApp.
@interface FTRTypingViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>

@property(nonatomic, retain) IBOutlet UITextView *textView;
@property(nonatomic, retain) IBOutlet UITextField *inputAccessoryTextField;
@property(nonatomic, retain) IBOutlet UIButton *inputButton;
@property(nonatomic, retain) IBOutlet UITextField *textField;
@property(nonatomic, retain) IBOutlet UITextField *nonTypingTextField;
@property(nonatomic, retain) IBOutlet FTRCustomTextView *customTextView;
@property(nonatomic, retain) UIBarButtonItem *dismissKeyboardButton;
@property(nonatomic, retain) IBOutlet UIPickerView *keyboardPicker;
@property(nonatomic, retain) NSArray *keyboardTypeStringArray;
@property(nonatomic, retain) IBOutlet FTRCustomKeyboardTracker *customKeyboardTracker;

@end
