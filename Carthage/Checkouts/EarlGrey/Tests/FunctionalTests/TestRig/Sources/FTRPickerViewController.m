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

#import "FTRPickerViewController.h"

@interface FTRPickerViewDelegate1 : NSObject<UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface FTRPickerViewDelegate2 : NSObject<UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface FTRPickerViewDelegate3 : NSObject<UIPickerViewDelegate>

@property(nonatomic, retain) NSArray *customColumn1Array;
@property(nonatomic, retain) NSArray *customColumn2Array;

@end

@interface FTRPickerViewDelegate4 : NSObject<UIPickerViewDelegate>
@end

@implementation FTRPickerViewDelegate1

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = [[NSMutableArray alloc] init];
    self.customColumn2Array = [[NSMutableArray alloc] init];
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  UILabel *columnView = [[UILabel alloc]
      initWithFrame:CGRectMake(35, 0, pickerView.frame.size.width / 2,
                               pickerView.frame.size.height)];
  columnView.text =
      [self pickerView:pickerView titleForRow:row forComponent:component];
  columnView.textAlignment = NSTextAlignmentCenter;

  return columnView;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return [self.customColumn1Array objectAtIndex:(NSUInteger)row];
      break;
    case 1:
      return [self.customColumn2Array objectAtIndex:(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation FTRPickerViewDelegate2

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = [[NSMutableArray alloc] init];
    self.customColumn2Array = [[NSMutableArray alloc] init];
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  NSString *rowTitle =
      [self pickerView:pickerView titleForRow:row forComponent:component];
  return [[NSAttributedString alloc] initWithString:rowTitle];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return [self.customColumn1Array objectAtIndex:(NSUInteger)row];
      break;
    case 1:
      return [self.customColumn2Array objectAtIndex:(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation FTRPickerViewDelegate3

- (instancetype)init {
  self = [super init];
  if (self) {
    self.customColumn1Array = [[NSMutableArray alloc] init];
    self.customColumn2Array = [[NSMutableArray alloc] init];
    self.customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    self.customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  return nil;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return [self.customColumn1Array objectAtIndex:(NSUInteger)row];
      break;
    case 1:
      return [self.customColumn2Array objectAtIndex:(NSUInteger)row];
      break;
  }
  return nil;
}

@end

@implementation FTRPickerViewDelegate4

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  return nil;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView
             attributedTitleForRow:(NSInteger)row
                      forComponent:(NSInteger)component {
  return nil;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  return nil;
}

@end

@implementation FTRPickerViewController

@synthesize customPicker;
@synthesize datePicker;
@synthesize interactionDisabledPicker;
@synthesize datePickerSegmentedControl;
@synthesize customColumn1Array;
@synthesize customColumn2Array;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    customColumn1Array = [[NSMutableArray alloc] init];
    customColumn2Array = [[NSMutableArray alloc] init];
    customColumn1Array = @[ @"Red", @"Green", @"Blue", @"Hidden" ];
    customColumn2Array = @[ @"1", @"2", @"3", @"4", @"5" ];
  }
  return self;
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.customPicker setHidden:YES];
  [self.datePicker setHidden:YES];
  [self.interactionDisabledPicker setHidden:YES];

  self.datePicker.accessibilityIdentifier = @"DatePickerId";
  self.customPicker.accessibilityIdentifier = @"CustomPickerId";
  self.interactionDisabledPicker.accessibilityIdentifier = @"InteractionDisabledPickerId";
  self.dateLabel.accessibilityIdentifier = @"DateLabelId";
  self.clearLabelButton.accessibilityIdentifier = @"ClearDateLabelButtonId";

  self.viewForRowDelegateSwitch.accessibilityIdentifier =
      @"viewForRowDelegateSwitch";
  self.attributedTitleForRowDelegateSwitch.accessibilityIdentifier =
      @"attributedTitleForRowDelegateSwitch";
  self.titleForRowDelegateSwitch.accessibilityIdentifier =
      @"titleForRowDelegateSwitch";
  self.noDelegateMethodDefinedSwitch.accessibilityIdentifier =
      @"noDelegateMethodDefinedSwitch";

  [datePicker addTarget:self
                 action:@selector(datePickerValueChanged:)
       forControlEvents:UIControlEventValueChanged];

  self.ftrPickerViewDelegate1 = [FTRPickerViewDelegate1 new];
  self.ftrPickerViewDelegate2 = [FTRPickerViewDelegate2 new];
  self.ftrPickerViewDelegate3 = [FTRPickerViewDelegate3 new];
  self.ftrPickerViewDelegate4 = [FTRPickerViewDelegate4 new];
}

- (void)datePickerValueChanged:(id)sender {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"YYYY/MM/dd";
  self.dateLabel.text = [dateFormatter stringFromDate:datePicker.date];
}

- (IBAction)clearDateLabelButtonTapped:(id)sender {
  self.dateLabel.text = @"";
}

- (IBAction)valueChanged:(id)sender {
  [datePicker setHidden:YES];
  [customPicker setHidden:YES];
  [interactionDisabledPicker setHidden:YES];
  NSInteger selectedSegment = datePickerSegmentedControl.selectedSegmentIndex;

  switch (selectedSegment) {
    case 0:
      datePicker.datePickerMode = UIDatePickerModeDate;
      [datePicker setHidden:NO];
      break;
    case 1:
      datePicker.datePickerMode = UIDatePickerModeTime;
      [datePicker setHidden:NO];
      break;
    case 2:
      datePicker.datePickerMode = UIDatePickerModeDateAndTime;
      [datePicker setHidden:NO];
      break;
    case 3:
      datePicker.datePickerMode = UIDatePickerModeCountDownTimer;
      [datePicker setHidden:NO];
      break;
    case 4:
      [customPicker setHidden:NO];
      break;
    case 5:
      [interactionDisabledPicker setHidden:NO];
  }
}

- (IBAction)viewForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.ftrPickerViewDelegate1;
  [self.customPicker reloadAllComponents];
}

- (IBAction)attributedTitleForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.ftrPickerViewDelegate2;
  [self.customPicker reloadAllComponents];
}

- (IBAction)titleForRowDelegateSwitchToggled:(id)sender {
  self.customPicker.delegate = self.ftrPickerViewDelegate3;
  [self.customPicker reloadAllComponents];
}

- (IBAction)noDelegateMethodDefinedSwitchToggled:(id)sender {
  self.customPicker.delegate = self.ftrPickerViewDelegate4;
  [self.customPicker reloadAllComponents];
}

#pragma mark - UIPickerViewDataSource Protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return (NSInteger)[customColumn1Array count];
      break;
    case 1:
      return (NSInteger)[customColumn2Array count];
      break;
    default:
      NSAssert(NO, @"shouldn't be here");
      break;
  }
  return 0;
}

#pragma mark - UIPickerViewDelegate Protocol

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  switch (component) {
    case 0:
      return [customColumn1Array objectAtIndex:(NSUInteger)row];
      break;
    case 1:
      return [customColumn2Array objectAtIndex:(NSUInteger)row];
      break;
  }
  return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return 30;
}

- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view {
  UILabel *columnView =
      [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.view.frame.size.width / 3 - 35, 30)];
  columnView.text = [self pickerView:pickerView titleForRow:row forComponent:component];
  columnView.textAlignment = NSTextAlignmentCenter;
  return columnView;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  // If Hidden is selected, hide picker.
  if (component == 0 && [customColumn1Array[(NSUInteger)row] isEqualToString:@"Hidden"]) {
    [customPicker setHidden:YES];
  }
}

@end
