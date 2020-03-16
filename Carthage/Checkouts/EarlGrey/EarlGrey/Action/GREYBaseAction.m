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

#import "Action/GREYBaseAction.h"

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/NSObject+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Assertion/GREYAssertions+Internal.h"
#import "Common/GREYConfiguration.h"
#import "Common/GREYError+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYErrorConstants.h"
#import "Common/GREYObjectFormatter.h"
#import "Common/GREYThrowDefines.h"
#import "Core/GREYInteraction.h"
#import "Matcher/GREYMatcher.h"
#import "Matcher/GREYStringDescription.h"

@implementation GREYBaseAction {
  NSString *_name;
  id<GREYMatcher> _constraints;
}

- (instancetype)initWithName:(NSString *)name constraints:(id<GREYMatcher>)constraints {
  GREYThrowOnNilParameter(name);

  self = [super init];
  if (self) {
    _name = [name copy];
    _constraints = constraints;
  }
  return self;
}

- (BOOL)satisfiesConstraintsForElement:(id)element error:(__strong NSError **)errorOrNil {
  if (!_constraints || !GREY_CONFIG_BOOL(kGREYConfigKeyActionConstraintsEnabled)) {
    return YES;
  } else {
    GREYStringDescription *mismatchDetail = [[GREYStringDescription alloc] init];
    if (![_constraints matches:element describingMismatchTo:mismatchDetail]) {
      NSMutableDictionary *errorDetails = [[NSMutableDictionary alloc] init];

      errorDetails[kErrorDetailActionNameKey] = _name;
      errorDetails[kErrorDetailElementDescriptionKey] = [element grey_description];
      errorDetails[kErrorDetailConstraintRequirementKey] = mismatchDetail;
      errorDetails[kErrorDetailConstraintDetailsKey] = [_constraints description];
      errorDetails[kErrorDetailRecoverySuggestionKey] =
          @"Adjust element properties so that it matches the failed constraint(s).";

      GREYError *error = GREYErrorMake(kGREYInteractionErrorDomain,
                                       kGREYInteractionConstraintsFailedErrorCode,
                                       @"Cannot perform action due to constraint(s) failure.");
      error.errorInfo = errorDetails;

      if (errorOrNil) {
        *errorOrNil = error;
      } else {
        NSArray *keyOrder = @[ kErrorDetailActionNameKey,
                               kErrorDetailConstraintRequirementKey,
                               kErrorDetailElementDescriptionKey,
                               kErrorDetailConstraintDetailsKey,
                               kErrorDetailRecoverySuggestionKey ];

        NSString *reasonDetail = [GREYObjectFormatter formatDictionary:errorDetails
                                                                indent:2
                                                             hideEmpty:YES
                                                              keyOrder:keyOrder];

        NSString *reason = [NSString stringWithFormat:@"Cannot perform action due to "
                                                      @"constraint(s) failure.\n"
                                                      @"Exception with Action: %@\n",
                                                      reasonDetail];

        I_GREYActionFail(reason, @"");
      }
      return NO;
    }
    return YES;
  }
}

#pragma mark - GREYAction

// The perform:error: method has to be implemented by the subclass.
- (BOOL)perform:(id)element error:(__strong NSError **)errorOrNil {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (NSString *)name {
  return _name;
}

@end
