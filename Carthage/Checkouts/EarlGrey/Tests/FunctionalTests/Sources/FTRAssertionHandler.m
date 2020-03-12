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

#import "FTRAssertionHandler.h"

@implementation FTRAssertionHandler

- (void)handleFailureInMethod:(SEL)selector
                       object:(id)object
                         file:(NSString *)fileName
                   lineNumber:(NSInteger)line
                  description:(NSString *)format, ... {
  _failuresCount += 1;
  va_list args;
  va_start(args, format);
  if (!_failureDescriptions) {
    _failureDescriptions = [[NSMutableArray alloc] init];
  }
  [_failureDescriptions addObject:[[NSString alloc] initWithFormat:format arguments:args]];
  va_end(args);
}

@end
