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

#import "FTRTypingViewController.h"

#import "FTRCustomTextView.h"

#define kFTRKeyboardTypeCount 11

@interface FTRCustomKeyboardTracker : UIButton
@end

@implementation FTRCustomKeyboardTracker {
  UIView *_fakeKeyboardTracker;
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (UIView *)inputAccessoryView {
  if (!_fakeKeyboardTracker) {
    // Create a zero size input accessory to continue receiving keyboard event.
    // This is a common practice in iOS apps to work around
    // https://openradar.appspot.com/15341512 We are simulating this usage here
    // to make sure our keyboard functions would still work with this work
    // around usage.
    _fakeKeyboardTracker = [[UILabel alloc] initWithFrame:CGRectZero];
  }
  return _fakeKeyboardTracker;
}

@end

@implementation FTRTypingViewController {
  UIKeyboardType _keyboardTypeArray[kFTRKeyboardTypeCount];
  UITextField *_accessoryTextField;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _keyboardTypeStringArray = @[@"Default",
                                 @"ASCIICapable",
                                 @"NumbersAndPunctuation",
                                 @"URL",
                                 @"NumberPad",
                                 @"PhonePad",
                                 @"NamePhonePad",
                                 @"EmailAddress",
                                 @"DecimalPad",
                                 @"Twitter",
                                 @"WebSearch"];
    NSAssert([_keyboardTypeStringArray count] == kFTRKeyboardTypeCount,
             @"count must be kFTRKeyboardTypeCount");
    _keyboardTypeArray[0] = UIKeyboardTypeDefault;
    _keyboardTypeArray[1] = UIKeyboardTypeASCIICapable;
    _keyboardTypeArray[2] = UIKeyboardTypeNumbersAndPunctuation;
    _keyboardTypeArray[3] = UIKeyboardTypeURL;
    _keyboardTypeArray[4] = UIKeyboardTypeNumberPad;
    _keyboardTypeArray[5] = UIKeyboardTypePhonePad;
    _keyboardTypeArray[6] = UIKeyboardTypeNamePhonePad;
    _keyboardTypeArray[7] = UIKeyboardTypeEmailAddress;
    _keyboardTypeArray[8] = UIKeyboardTypeDecimalPad;
    _keyboardTypeArray[9] = UIKeyboardTypeTwitter;
    _keyboardTypeArray[10] = UIKeyboardTypeWebSearch;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.dismissKeyboardButton =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                    target:self
                                                    action:@selector(dismissKeyboard)];

  self.textField.delegate = self;
  self.textField.isAccessibilityElement = YES;
  self.textField.userInteractionEnabled = YES;
  self.textField.accessibilityIdentifier = @"TypingTextField";
  self.textField.autocorrectionType = UITextAutocorrectionTypeYes;

  self.nonTypingTextField.delegate = self;
  self.nonTypingTextField.isAccessibilityElement = YES;
  self.nonTypingTextField.userInteractionEnabled = YES;
  self.nonTypingTextField.accessibilityIdentifier = @"NonTypingTextField";

  self.textView.delegate = self;
  self.textView.isAccessibilityElement = YES;
  self.textView.userInteractionEnabled = YES;
  self.textView.accessibilityIdentifier = @"TypingTextView";
  self.textView.autocorrectionType = UITextAutocorrectionTypeYes;

  self.inputAccessoryTextField.delegate = self;
  self.inputAccessoryTextField.isAccessibilityElement = YES;
  self.inputAccessoryTextField.userInteractionEnabled = YES;
  self.inputAccessoryTextField.accessibilityIdentifier = @"InputAccessoryTextField";
  self.inputAccessoryTextField.autocorrectionType = UITextAutocorrectionTypeYes;
  [self AddInputAccessoryViewtoKeyboard];

  self.inputButton.accessibilityIdentifier = @"Input Button";
  [self.inputButton addTarget:self
                       action:@selector(buttonPressedForTyping)
             forControlEvents:UIControlEventTouchUpInside];

  self.keyboardPicker.accessibilityIdentifier = @"KeyboardPicker";

  self.customTextView.isAccessibilityElement = YES;
  self.customTextView.userInteractionEnabled = YES;
  self.customTextView.accessibilityIdentifier = @"CustomTextView";

  [self.view sendSubviewToBack:_customKeyboardTracker];
  self.customKeyboardTracker.isAccessibilityElement = YES;
  self.customKeyboardTracker.accessibilityIdentifier = @"CustomKeyboardTracker";
}

- (void)buttonPressedForTyping {
  [self.inputAccessoryTextField becomeFirstResponder];
  [_accessoryTextField becomeFirstResponder];
}

- (void)AddInputAccessoryViewtoKeyboard {
  UIView *customView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 20, 100)];
  _accessoryTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
  _accessoryTextField.backgroundColor = [UIColor greenColor];
  [customView addSubview:_accessoryTextField];
  _accessoryTextField.accessibilityIdentifier = @"AccessoryTextField";
  _accessoryTextField.inputAccessoryView = customView;
  customView.backgroundColor = [UIColor redColor];
  self.inputAccessoryTextField.inputAccessoryView = customView;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  return textField != self.nonTypingTextField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
  self.navigationItem.rightBarButtonItem = self.dismissKeyboardButton;
}

- (void)dismissKeyboard {
  [self.textView resignFirstResponder];
  self.navigationItem.rightBarButtonItem = nil;
}

- (void)resetState {
  self.textField.text = @"";
  if ([self.textField isFirstResponder]) {
    [self.textField resignFirstResponder];
  }
  self.textView.text = @"";
  if ([self.textView isFirstResponder]) {
    [self.textView resignFirstResponder];
  }
}

- (IBAction)changeReturnKeyType:(id)sender {
  [self resetState];
  self.textField.returnKeyType = [self nextReturnKeyTypeFor:self.textField.returnKeyType];
  self.textView.returnKeyType =  [self nextReturnKeyTypeFor:self.textView.returnKeyType];
}

- (UIReturnKeyType)nextReturnKeyTypeFor:(UIReturnKeyType)type {
  switch (type) {
    case UIReturnKeyDefault:
      return UIReturnKeyGo;
    case UIReturnKeyGo:
      return UIReturnKeyGoogle;
    case UIReturnKeyGoogle:
      return UIReturnKeyJoin;
    case UIReturnKeyJoin:
      return UIReturnKeyNext;
    case UIReturnKeyNext:
      return UIReturnKeyRoute;
    case UIReturnKeyRoute:
      return UIReturnKeySearch;
    case UIReturnKeySearch:
      return UIReturnKeySend;
    case UIReturnKeySend:
      return UIReturnKeyYahoo;
    case UIReturnKeyYahoo:
      return UIReturnKeyDone;
    case UIReturnKeyDone:
      // The Emergency Call key is no longer accessible starting from iOS 9.1. Therefore, we move
      // to the Continue key that has to be present after iOS 9.0.
      if (([UIDevice currentDevice].systemVersion.floatValue > 9.0)) {
#if defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
        return UIReturnKeyContinue;
#endif
      } else {
        return UIReturnKeyEmergencyCall;
      }
    case UIReturnKeyEmergencyCall:
      return UIReturnKeyDefault;
#if defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
    case UIReturnKeyContinue:
      return UIReturnKeyContinue;
#endif
  }
}

#pragma mark - UIPickerViewDataSource Protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent :(NSInteger)component {
  if (component == 0) {
    return (NSInteger)[_keyboardTypeStringArray count];
  }
  NSAssert(NO, @"invalid component number");
  return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  if (component == 0) {
    return _keyboardTypeStringArray[(NSUInteger)row];
  }
  NSAssert(NO, @"invalid component number");
  return nil;
}

#pragma mark - UIPickerViewDelegate Protocol

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return 30;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  NSAssert(0 <= row && row < kFTRKeyboardTypeCount, @"invalid row");
  [self resetState];
  self.textField.keyboardType = _keyboardTypeArray[row];
  self.textView.keyboardType = _keyboardTypeArray[row];
}

@end
