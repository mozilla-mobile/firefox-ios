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

#import "Action/GREYPickerAction.h"

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/UIView+GREYAdditions.h"
#import "Common/GREYDefines.h"
#import "Common/GREYError.h"
#import "Core/GREYInteraction.h"
#import "Matcher/GREYAllOf.h"
#import "Matcher/GREYMatchers.h"
#import "Matcher/GREYNot.h"
#import "Synchronization/GREYTimedIdlingResource.h"

@implementation GREYPickerAction {
  /**
   *  The column being modified of the UIPickerView.
   */
  NSInteger _column;
  /**
   *  The value to modify the column of the UIPickerView.
   */
  NSString * _value;
}

- (instancetype)initWithColumn:(NSInteger)column value:(NSString *)value {
  NSString *name =
      [NSString stringWithFormat:@"Set picker column %ld to value '%@'", (long)column, value];
  self = [super initWithName:name constraints:grey_allOf(grey_interactable(),
                                                         grey_userInteractionEnabled(),
                                                         grey_not(grey_systemAlertViewShown()),
                                                         grey_kindOfClass([UIPickerView class]),
                                                         nil)];
  if (self) {
    _column = column;
    _value = value;
  }
  return self;
}

#pragma mark - GREYAction

- (BOOL)perform:(UIPickerView *)pickerView error:(__strong NSError **)errorOrNil {
  if (![self satisfiesConstraintsForElement:pickerView error:errorOrNil]) {
    return NO;
  }

  NSInteger componentCount = [pickerView.dataSource numberOfComponentsInPickerView:pickerView];

  if (componentCount < _column) {
    NSString *description = [NSString stringWithFormat:@"Invalid column on picker view [P] "
                                                       @"cannot find the column %lu.",
                                                       (unsigned long)_column];
    NSDictionary *glossary = @{ @"P" : [pickerView description] };
    GREYPopulateErrorNotedOrLog(errorOrNil,
                                kGREYInteractionErrorDomain,
                                kGREYInteractionActionFailedErrorCode,
                                description,
                                glossary);

    return NO;
  }

  NSInteger columnRowCount = [pickerView.dataSource pickerView:pickerView
                                       numberOfRowsInComponent:_column];

  SEL titleForRowSelector = @selector(pickerView:titleForRow:forComponent:);
  SEL viewForRowSelector = @selector(pickerView:viewForRow:forComponent:reusingView:);

  for (NSInteger rowIndex = 0; rowIndex < columnRowCount; rowIndex++) {
    NSString *rowTitle;
    if ([pickerView.delegate respondsToSelector:titleForRowSelector]) {
      rowTitle = [pickerView.delegate pickerView:pickerView
                                     titleForRow:rowIndex
                                    forComponent:_column];
    } else if ([pickerView.delegate respondsToSelector:viewForRowSelector]) {
      UIView *rowView = [pickerView.delegate pickerView:pickerView
                                             viewForRow:rowIndex
                                           forComponent:_column
                                            reusingView:nil];
      if (![rowView isKindOfClass:[UILabel class]]) {
        NSArray *labels = [rowView grey_childrenAssignableFromClass:[UILabel class]];
        UILabel *label = (labels.count > 0 ? labels[0] : nil);
        rowTitle = label.text;
      } else {
        rowTitle = [((UILabel *)rowView) text];
      }
    }
    if ([rowTitle isEqualToString:_value]) {
      [pickerView selectRow:rowIndex inComponent:_column animated:YES];
      if ([pickerView.delegate
              respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]) {
        [pickerView.delegate pickerView:pickerView didSelectRow:rowIndex inComponent:_column];
      }
      // UIPickerView does a delayed animation. We don't track delayed animations, therefore
      // we have to track it manually
      [GREYTimedIdlingResource resourceForObject:pickerView
                           thatIsBusyForDuration:0.5
                                            name:@"UIPickerView"];
      return YES;
    }
  }
  GREYPopulateErrorOrLog(errorOrNil,
                         kGREYInteractionErrorDomain,
                         kGREYInteractionActionFailedErrorCode,
                         @"UIPickerView does not contain desired value!");
  return NO;
}

@end
