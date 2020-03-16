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

#import "Synchronization/GREYCondition.h"

#import "Common/GREYConstants.h"
#import "Common/GREYDefines.h"
#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYRunLoopSpinner.h"
#import "Synchronization/GREYUIThreadExecutor.h"

@implementation GREYCondition {
  BOOL (^_conditionBlock)(void);
  NSString *_name;
}

+ (instancetype)conditionWithName:(NSString *)name block:(BOOL(^)(void))conditionBlock {
  return [[GREYCondition alloc] initWithName:name block:conditionBlock];
}

- (instancetype)initWithName:(NSString *)name block:(BOOL(^)(void))conditionBlock {
  GREYThrowOnNilParameter(name);
  GREYThrowOnNilParameter(conditionBlock);

  self = [super init];
  if (self) {
    _name = [name copy];
    _conditionBlock = [conditionBlock copy];
  }
  return self;
}

- (BOOL)waitWithTimeout:(CFTimeInterval)seconds {
  return [self waitWithTimeout:seconds pollInterval:0];
}

- (BOOL)waitWithTimeout:(CFTimeInterval)seconds pollInterval:(CFTimeInterval)interval {
  GREYThrowOnFailedConditionWithMessage(seconds >= 0, @"timeout seconds must be >= 0.");
  GREYThrowOnFailedConditionWithMessage(interval >= 0, @"poll interval must be >= 0.");

  GREYRunLoopSpinner *runLoopSpinner = [[GREYRunLoopSpinner alloc] init];

  runLoopSpinner.timeout = seconds;
  runLoopSpinner.maxSleepInterval = interval;

  if (interval == 0) {
    return [runLoopSpinner spinWithStopConditionBlock:^BOOL {
      return _conditionBlock();
    }];
  } else {
    __block CFTimeInterval nextPollTime = CACurrentMediaTime();

    return [runLoopSpinner spinWithStopConditionBlock:^BOOL {
      CFTimeInterval now = CACurrentMediaTime();

      if (now >= nextPollTime) {
        nextPollTime = now + interval;
        return _conditionBlock();
      } else {
        return NO;
      }
    }];
  }
}

- (NSString *)name {
  return _name;
}

@end
