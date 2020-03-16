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

#import "Provider/GREYDataEnumerator.h"

#import "Common/GREYDefines.h"
#import "Common/GREYThrowDefines.h"

@implementation GREYDataEnumerator {
  id(^_nextObjectBlock)(id);
  id _userInfo;
}

- (instancetype)initWithUserInfo:(id)userInfo block:(id(^)(id))nextObjectBlock {
  GREYThrowOnNilParameter(nextObjectBlock);

  self = [super init];
  if (self) {
    _nextObjectBlock = nextObjectBlock;
    _userInfo = userInfo;
  }
  return self;
}

#pragma mark - NSEnumerator

- (id)nextObject {
  return _nextObjectBlock(_userInfo);
}

- (NSArray *)allObjects {
  NSMutableArray *remainingObjects = [[NSMutableArray alloc] init];
  id object;
  while (YES) {
    @autoreleasepool {
      object = _nextObjectBlock(_userInfo);
      if (object) {
        [remainingObjects addObject:object];
      } else {
        break;
      }
    }
  }
  return [NSArray arrayWithArray:remainingObjects];
}

@end
